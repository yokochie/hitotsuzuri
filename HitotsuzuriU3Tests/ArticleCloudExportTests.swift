import XCTest
@testable import HitotsuzuriCore

@MainActor final class ArticleCloudExportTests: XCTestCase {
    // T1/T2: 実Deliveryからproviderへ出力時の通信方針が到達する。
    func testFourPhotoDeliveryPermitsCloudAcquisition() async throws {
        let root = try ExportFixture.root("cloud-policy")
        defer { try? FileManager.default.removeItem(at: root) }
        let images = CloudExportImages(), prepared = try ExportFixture.prepared()
        let delivery = ArticleExportDelivery(images: images, journal: ArticleExportJournal(directory: root.appendingPathComponent("jobs")))
        let result = try await delivery.run(jobID: UUID(), prepared: prepared, destination: root)
        XCTAssertEqual(images.flags, [true, true, true, true])
        XCTAssertEqual(images.assets, prepared.savedInput.article.source.orderedAssetIDs)
        XCTAssertEqual(try String(contentsOf: result.directory.appendingPathComponent("article.md"), encoding: .utf8), prepared.rendered.markdown)
    }

    // T5: 待機をDeliveryの40秒/全体180秒に算入しない。
    func testLongAcquisitionDoesNotSpendWritingOrWholeExportDeadline() async throws {
        let root = try ExportFixture.root("cloud-wait")
        defer { try? FileManager.default.removeItem(at: root) }
        let clock = ExportTestClock(), images = CloudExportImages()
        images.onAcquire = { clock.advance(.seconds(301)) }
        images.lastAcquisitionDuration = .seconds(301)
        let delivery = ArticleExportDelivery(images: images, journal: ArticleExportJournal(directory: root.appendingPathComponent("jobs")), now: { clock.now() })
        do {
            let result = try await delivery.run(jobID: UUID(), prepared: ExportFixture.prepared(), destination: root)
            XCTAssertTrue(FileManager.default.fileExists(atPath: result.directory.appendingPathComponent("images/04.jpg").path))
        } catch { XCTFail("各画像301秒の待機だけで出力を打ち切った: \(error)") }
    }

    // T3/T4: 実Deliveryの要求所有とfraction単調性を観測する。
    func testProgressOnlyBelongsToCurrentPhotoAndActiveRequest() async throws {
        let root = try ExportFixture.root("cloud-progress")
        defer { try? FileManager.default.removeItem(at: root) }
        let images = CloudExportImages(), latch = U3Latch(), log = CloudExportProgressLog()
        images.pause = latch
        let delivery = ArticleExportDelivery(images: images, journal: ArticleExportJournal(directory: root.appendingPathComponent("jobs")))
        let id = UUID()
        let task = Task { try await delivery.run(jobID: id, prepared: ExportFixture.prepared(), destination: root, progress: { await log.append($0) }) }
        try await ExportFixture.waitUntil { latch.waiting }
        images.emit(0.5)
        let accepted = await wait { await log.values.contains { $0.fraction == 0.5 } }; XCTAssertTrue(accepted)
        images.emit(0.25); images.emit(.nan); images.emit(2)
        let oldProgress = images.progress
        latch.open(); _ = try await task.value
        oldProgress?(0.9)
        for _ in 0..<20 { await Task.yield() }
        let fractions = await log.values.compactMap(\.fraction)
        XCTAssertTrue(fractions.contains(0.5))
        XCTAssertFalse(fractions.contains(0.25)); XCTAssertFalse(fractions.contains(0.9))
        XCTAssertTrue(fractions.allSatisfy { $0.isFinite && (0...1).contains($0) })
        let values = await log.values
        XCTAssertEqual(values.last?.stage, "committing")
    }

    // T9/T10: 写真番号付き失敗・所有cleanup・新jobでの再出力。
    func testFailureAtSecondCloudPhotoCanBeRetriedWithoutReplacingPreviousOutput() async throws {
        let root = try ExportFixture.root("cloud-retry")
        defer { try? FileManager.default.removeItem(at: root) }
        let images = CloudExportImages(), prepared = try ExportFixture.prepared()
        let delivery = ArticleExportDelivery(images: images, journal: ArticleExportJournal(directory: root.appendingPathComponent("jobs")))
        let first = try await delivery.run(jobID: UUID(), prepared: prepared, destination: root)
        let bytes = try Data(contentsOf: first.directory.appendingPathComponent("article.md"))
        images.failureAt = images.assets.count + 2
        do { _ = try await delivery.run(jobID: UUID(), prepared: prepared, destination: root); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .networkUnavailable) }
        let detail = await delivery.failureDetail
        XCTAssertEqual(detail?.photoIndex, 2)
        let pending = try await delivery.pending(); XCTAssertNil(pending)
        XCTAssertFalse(try FileManager.default.contentsOfDirectory(atPath: root.path).contains { $0.hasPrefix(".article-export-") })
        images.failureAt = nil
        let next = try await delivery.run(jobID: UUID(), prepared: prepared, destination: root)
        XCTAssertNotEqual(first.directory, next.directory)
        XCTAssertEqual(try Data(contentsOf: first.directory.appendingPathComponent("article.md")), bytes)
    }

    // T6: 長い取得を控除しても、書込の40秒上限は残す。
    func testLongDownloadDoesNotDisableWritingDeadline() async throws {
        let root = try ExportFixture.root("cloud-write-deadline")
        defer { try? FileManager.default.removeItem(at: root) }
        let clock = ExportTestClock(), images = CloudExportImages()
        images.onAcquire = { clock.advance(.seconds(301)) }; images.lastAcquisitionDuration = .seconds(301)
        let delivery = ArticleExportDelivery(images: images, journal: ArticleExportJournal(directory: root.appendingPathComponent("jobs")), now: { clock.now() }, writerFactory: { url, record in
            ArticleExportWriter(destination: url, record: record, checkpoint: { point in
                if case .beforeImage = point { clock.advance(.seconds(41)) }
            })
        })
        do { _ = try await delivery.run(jobID: UUID(), prepared: ExportFixture.prepared(), destination: root); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .timedOut) }
    }

    private func wait(_ condition: @MainActor () async -> Bool) async -> Bool {
        let end = ContinuousClock().now + .seconds(2)
        while !(await condition()) {
            if ContinuousClock().now >= end { return false }
            await Task.yield()
        }
        return true
    }
}

@MainActor private final class CloudExportImages: ArticleExportImageProviding {
    var isBusy = false
    var reservedImageBytes = 0
    var peakReservedImageBytes = 0
    var lastAcquisitionDuration: Duration = .zero
    var flags: [Bool] = [], assets: [String] = []
    var onAcquire: (() -> Void)?
    var pause: U3Latch?
    var failureAt: Int?
    var progress: (@MainActor (Double) -> Void)?
    func image(_ assetID: String, requestID: UUID) async throws -> ArticleJPEG {
        try await image(assetID, requestID: requestID, networkAllowed: false, progress: { _ in })
    }
    func image(_ assetID: String, requestID: UUID, networkAllowed: Bool, progress: @escaping @MainActor (Double) -> Void) async throws -> ArticleJPEG {
        flags.append(networkAllowed); assets.append(assetID); onAcquire?()
        self.progress = progress
        progress(0)
        await pause?.wait()
        if failureAt == assets.count { throw ArticleFailure.networkUnavailable }
        progress(1)
        return try ExportFixture.jpeg()
    }
    func emit(_ value: Double) { progress?(value) }
    func cancel(_ requestID: UUID) { }
}

private actor CloudExportProgressLog {
    var values: [ExportProgress] = []
    func append(_ value: ExportProgress) { values.append(value) }
}
