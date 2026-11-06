import XCTest
import Darwin
import ImageIO
import UniformTypeIdentifiers
@testable import HitotsuzuriCore

@MainActor final class ArticleExportIntegrationTests: XCTestCase {
    private func fixture(_ body: (URL, ExportTestImages, ArticleExportJournal, ArticleExportDelivery, PreparedArticleExport) async throws -> Void) async throws {
        let root = try ExportFixture.root("integration"); defer { try? FileManager.default.removeItem(at: root) }
        let images = ExportTestImages(), journal = ArticleExportJournal(directory: root.appendingPathComponent("jobs"))
        try await body(root, images, journal, ArticleExportDelivery(images: images, journal: journal), ExportFixture.prepared())
    }
    private func resolveWithoutSuccess(_ delivery: ArticleExportDelivery, root: URL) async -> ExportResult? {
        do { return try await delivery.recover(destination: root, cleanupConfirmed: true) }
        catch { XCTFail("同じ親の安全な不在/生成済み部分物を解決できない: \(error)"); return nil }
    }
    func testRealBundleManifestMatchesFourImagesAndArticle() async throws {
        try await fixture { root, _, _, delivery, prepared in
            let result = try? await delivery.run(jobID: UUID(), prepared: prepared, destination: root)
            XCTAssertNotNil(result)
            if let result {
                let manifest = try ArticleExportManifest.decode(Data(contentsOf: result.directory.appendingPathComponent("manifest.json")))
                try manifest.validate(prepared: prepared)
                XCTAssertEqual(try String(contentsOf: result.directory.appendingPathComponent("article.md"), encoding: .utf8), prepared.rendered.markdown)
            }
        }
    }
    func testImageFailureLeavesNoSuccessfulFolder() async throws {
        try await fixture { root, images, _, delivery, prepared in
            images.failureAt = 3
            _ = try? await delivery.run(jobID: UUID(), prepared: prepared, destination: root)
            XCTAssertEqual(images.calls.count, 3)
            XCTAssertFalse(try FileManager.default.contentsOfDirectory(atPath: root.path).contains { $0.hasPrefix("記事-") || $0.hasPrefix(".article-export-") })
        }
    }
    func testNewJobProducesAnotherFolderWithoutChangingPreviousBytes() async throws {
        try await fixture { root, _, _, delivery, prepared in
            let a = try? await delivery.run(jobID: UUID(), prepared: prepared, destination: root)
            let b = try? await delivery.run(jobID: UUID(), prepared: prepared, destination: root)
            XCTAssertNotNil(a); XCTAssertNotNil(b); XCTAssertNotEqual(a?.directory, b?.directory)
            if let a, let b { XCTAssertEqual(try Data(contentsOf: a.directory.appendingPathComponent("article.md")), try Data(contentsOf: b.directory.appendingPathComponent("article.md"))) }
        }
    }
    func testArchivedJobSurvivesControllerRestart() async throws {
        try await fixture { root, images, journal, delivery, prepared in
            let id = UUID(), first = try? await delivery.run(jobID: UUID(), prepared: prepared, destination: root)
            XCTAssertNotNil(first)
            let a = try? await delivery.run(jobID: id, prepared: prepared, destination: root)
            let restarted = ArticleExportDelivery(images: images, journal: journal)
            let b = try? await restarted.run(jobID: id, prepared: prepared, destination: root)
            XCTAssertNotNil(a); XCTAssertEqual(a, b); XCTAssertEqual(images.calls.count, 8)
        }
    }
    func testCorruptJournalStopsBeforeAnyImageRequest() async throws {
        try await fixture { root, images, journal, delivery, prepared in
            let jobs = root.appendingPathComponent("jobs"); try FileManager.default.createDirectory(at: jobs, withIntermediateDirectories: false)
            try Data("bad".utf8).write(to: jobs.appendingPathComponent("active"))
            do { _ = try await delivery.run(jobID: UUID(), prepared: prepared, destination: root); XCTFail() } catch { XCTAssertEqual(error as? ArticleFailure, .corruptData) }
            XCTAssertTrue(images.calls.isEmpty)
            do { _ = try await journal.pending(); XCTFail() } catch { }
        }
    }
    func testReusedIDWithChangedArticleIsRejected() async throws {
        try await fixture { root, images, _, delivery, prepared in
            let id = UUID(); _ = try? await delivery.run(jobID: id, prepared: prepared, destination: root)
            do { _ = try await delivery.run(jobID: id, prepared: ExportFixture.prepared(title: "別の記事"), destination: root); XCTFail() } catch { XCTAssertEqual(error as? ArticleFailure, .conflict) }
            XCTAssertEqual(images.calls.count, 4)
        }
    }
    func testLateCancelDoesNotUndoCommittedSuccess() async throws {
        try await fixture { root, _, journal, delivery, prepared in
            let id = UUID(), result = try? await delivery.run(jobID: id, prepared: prepared, destination: root)
            await delivery.cancel(id)
            let stored = try await journal.lookup(id)
            XCTAssertNotNil(result); XCTAssertEqual(stored?.phase, .succeeded)
        }
    }
    func testPublicFailureAfterRenameIsReconciledAfterRestart() async throws {
        try await fixture { root, images, journal, _, prepared in
            let delivery = ArticleExportDelivery(images: images, journal: journal, writerFactory: { url, record in
                ArticleExportWriter(destination: url, record: record, checkpoint: { point in if point == .afterRename { throw ArticleFailure.ioFailure } })
            })
            _ = try? await delivery.run(jobID: UUID(), prepared: prepared, destination: root)
            let pending = try await journal.pending()
            XCTAssertNotNil(pending)
            let recovered = try await ArticleExportDelivery(images: images, journal: journal).recover(destination: root, cleanupConfirmed: false)
            XCTAssertNotNil(recovered); XCTAssertEqual(images.calls.count, 4)
        }
    }
    func testCleanupFailureKeepsRecoveryAndOriginalCause() async throws {
        try await fixture { root, images, journal, _, prepared in
            images.failureAt = 2
            let delivery = ArticleExportDelivery(images: images, journal: journal, writerFactory: { url, record in
                ArticleExportWriter(destination: url, record: record, checkpoint: { point in if point == .beforeCleanup { throw ArticleFailure.cleanupFailure } })
            })
            do { _ = try await delivery.run(jobID: UUID(), prepared: prepared, destination: root); XCTFail() } catch { XCTAssertEqual(error as? ArticleFailure, .cleanupFailure) }
            let pending = try await journal.pending(), detail = await delivery.failureDetail
            XCTAssertEqual(pending?.phase, .cleanupFailed); XCTAssertEqual(pending?.originalFailure, .assetUnavailable)
            XCTAssertNotNil(detail?.residualDirectory)
        }
    }
    func testRecoveryRequiresSameParentAndPreservesForeignFiles() async throws {
        try await fixture { root, images, journal, _, prepared in
            images.failureAt = 1
            let delivery = ArticleExportDelivery(images: images, journal: journal, writerFactory: { url, record in
                ArticleExportWriter(destination: url, record: record, checkpoint: { point in if point == .beforeCleanup { throw ArticleFailure.cleanupFailure } })
            })
            _ = try? await delivery.run(jobID: UUID(), prepared: prepared, destination: root)
            let other = root.appendingPathComponent("other"); try FileManager.default.createDirectory(at: other, withIntermediateDirectories: false)
            do { _ = try await delivery.recover(destination: other, cleanupConfirmed: true); XCTFail() } catch { XCTAssertEqual(error as? ArticleFailure, .invalidReference) }
            let pending = try await journal.pending(); XCTAssertNotNil(pending)
        }
    }
    func testUnconfirmedRecoveryNeverDeletesPartialOutput() async throws {
        try await fixture { root, _, journal, delivery, prepared in
            let record = try ArticleExportRecoveryRecord(jobID: UUID(), prepared: prepared, parentIdentity: ArticleExportFileSystem.identity(of: root))
            try await journal.begin(record)
            let writer = ArticleExportWriter(destination: root, record: record), started = try await writer.prepare()
            try await journal.update(started, expected: record)
            _ = try await delivery.recover(destination: root, cleanupConfirmed: false)
            XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(record.stagingName).path))
            let pending = try await journal.pending(); XCTAssertNotNil(pending)
        }
    }
    func testReadOnlyArticleInputIsNeverModifiedByDelivery() async throws {
        try await fixture { root, _, _, delivery, prepared in
            let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
            let bytes = try encoder.encode(prepared.savedInput.article)
            _ = try? await delivery.run(jobID: UUID(), prepared: prepared, destination: root)
            XCTAssertEqual(try encoder.encode(prepared.savedInput.article), bytes)
            XCTAssertEqual(prepared.savedInput.article.fingerprint, prepared.rendered.sourceFingerprint)
        }
    }
    func testRestartBeforePrepareResolvesAbsentJobAndAllowsNewExport() async throws {
        try await fixture { root, images, journal, _, prepared in
            let record = try ArticleExportRecoveryRecord(jobID: UUID(), prepared: prepared, parentIdentity: ArticleExportFileSystem.identity(of: root))
            try await journal.begin(record)
            let restarted = ArticleExportDelivery(images: images, journal: journal)
            let beforeConfirmation = try await restarted.recover(destination: root, cleanupConfirmed: false)
            XCTAssertNil(beforeConfirmation); let stillPending = try await journal.pending(); XCTAssertNotNil(stillPending)
            let result = await self.resolveWithoutSuccess(restarted, root: root)
            XCTAssertNil(result); let pending = try await journal.pending(); XCTAssertNil(pending)
            XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(record.finalName).path))
            let next = try await restarted.run(jobID: UUID(), prepared: prepared, destination: root)
            XCTAssertNotEqual(next.jobID, record.jobID)
        }
    }
    func testRestartAfterCleanupBeforeJournalFinishAllowsNewExport() async throws {
        try await fixture { root, images, journal, _, prepared in
            let record = try ArticleExportRecoveryRecord(jobID: UUID(), prepared: prepared, parentIdentity: ArticleExportFileSystem.identity(of: root))
            try await journal.begin(record)
            let writer = ArticleExportWriter(destination: root, record: record), started = try await writer.prepare()
            try await journal.update(started, expected: record); try await writer.cleanup()
            let restarted = ArticleExportDelivery(images: images, journal: journal)
            let result = await self.resolveWithoutSuccess(restarted, root: root)
            XCTAssertNil(result); let pending = try await journal.pending(); XCTAssertNil(pending)
            _ = try await restarted.run(jobID: UUID(), prepared: prepared, destination: root)
        }
    }
    func testRestartDuringCleanupWithImagesDirectoryAlreadyRemoved() async throws {
        try await fixture { root, images, journal, _, prepared in
            let record = try ArticleExportRecoveryRecord(jobID: UUID(), prepared: prepared, parentIdentity: ArticleExportFileSystem.identity(of: root))
            try await journal.begin(record)
            let writer = ArticleExportWriter(destination: root, record: record), started = try await writer.prepare()
            let written = try await writer.writeImage(ExportFixture.jpeg(), index: 1)
            try await journal.update(written, expected: record)
            let stage = root.appendingPathComponent(record.stagingName)
            try FileManager.default.removeItem(at: stage.appendingPathComponent("images/01.jpg"))
            try FileManager.default.removeItem(at: stage.appendingPathComponent("images"))
            XCTAssertNotNil(started.imagesIdentity)
            let result = await self.resolveWithoutSuccess(ArticleExportDelivery(images: images, journal: journal), root: root)
            XCTAssertNil(result); let pending = try await journal.pending(); XCTAssertNil(pending)
            XCTAssertFalse(FileManager.default.fileExists(atPath: stage.path))
        }
    }
    func testRestartDuringCleanupWithReceiptAndArticleAlreadyRemoved() async throws {
        try await fixture { root, images, journal, _, prepared in
            let record = try ArticleExportRecoveryRecord(jobID: UUID(), prepared: prepared, parentIdentity: ArticleExportFileSystem.identity(of: root))
            try await journal.begin(record)
            let writer = ArticleExportWriter(destination: root, record: record)
            _ = try await writer.prepare()
            for index in 1...4 { _ = try await writer.writeImage(ExportFixture.jpeg(), index: index) }
            let sealed = try await writer.seal(); try await journal.update(sealed, expected: record)
            let stage = root.appendingPathComponent(record.stagingName)
            try FileManager.default.removeItem(at: stage.appendingPathComponent("owner.json"))
            try FileManager.default.removeItem(at: stage.appendingPathComponent("article.md"))
            let result = await self.resolveWithoutSuccess(ArticleExportDelivery(images: images, journal: journal), root: root)
            XCTAssertNil(result); let pending = try await journal.pending(); XCTAssertNil(pending)
            XCTAssertFalse(FileManager.default.fileExists(atPath: stage.path))
        }
    }
    func testUnpreparedRecoveryPreservesForeignStageAndFinalObjects() async throws {
        for final in [false, true] {
            try await fixture { root, images, journal, _, prepared in
                let record = try ArticleExportRecoveryRecord(jobID: UUID(), prepared: prepared, parentIdentity: ArticleExportFileSystem.identity(of: root))
                try await journal.begin(record)
                let foreign = root.appendingPathComponent(final ? record.finalName : record.stagingName), bytes = Data("foreign".utf8)
                try bytes.write(to: foreign)
                do { _ = try await ArticleExportDelivery(images: images, journal: journal).recover(destination: root, cleanupConfirmed: true); XCTFail("外部物を不在と扱った") } catch { }
                XCTAssertEqual(try Data(contentsOf: foreign), bytes)
                let pending = try await journal.pending(); XCTAssertNotNil(pending)
            }
        }
    }
    func testDeliverySealConflictPreservesExternalBytesAndOriginalCause() async throws {
        try await fixture { root, images, journal, _, prepared in
            let id = UUID()
            let delivery = ArticleExportDelivery(images: images, journal: journal, writerFactory: { url, record in
                ArticleExportWriter(destination: url, record: record, checkpoint: { point in
                    if point == .beforeSeal { try Data("external".utf8).write(to: url.appendingPathComponent(record.stagingName).appendingPathComponent("article.md")) }
                })
            })
            do { _ = try await delivery.run(jobID: id, prepared: prepared, destination: root); XCTFail() } catch { XCTAssertEqual(error as? ArticleFailure, .cleanupFailure) }
            let pending = try await journal.pending(); XCTAssertEqual(pending?.originalFailure, .conflict)
            let stage = try XCTUnwrap(pending?.stagingName)
            XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(stage).appendingPathComponent("article.md")), Data("external".utf8))
        }
    }
    func testManifestDateAndImageSettingsHaveExplicitPortableRepresentation() async throws {
        try await fixture { root, _, _, delivery, prepared in
            let result = try await delivery.run(jobID: UUID(), prepared: prepared, destination: root)
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: result.directory.appendingPathComponent("manifest.json"))) as? [String: Any])
            let date = try XCTUnwrap(object["createdAt"] as? String)
            XCTAssertNotNil(ISO8601DateFormatter().date(from: date))
            XCTAssertEqual(object["colorSpace"] as? String, "sRGB")
            XCTAssertEqual(object["encoding"] as? String, "JPEG")
            XCTAssertEqual(object["allowUpscale"] as? Bool, false)
        }
    }
    func testFourImageExportThirtyTrialsPerformance() async throws {
        XCTAssertNotEqual(ProcessInfo.processInfo.environment["GITHUB_ACTIONS"], "true", "実時間の合否は本人Macだけで判定")
        let fixture = try performanceFixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let images = ArticleImageAccess(reader: fixture.reader)
        let delivery = ArticleExportDelivery(images: images, journal: ArticleExportJournal(directory: fixture.root.appendingPathComponent("jobs")))
        var seconds: [Double] = []
        for _ in 0..<30 {
            let started = ContinuousClock().now
            let result = try await delivery.run(jobID: UUID(), prepared: fixture.prepared, destination: fixture.root)
            seconds.append(exportSeconds(started.duration(to: ContinuousClock().now)))
            XCTAssertTrue(FileManager.default.fileExists(atPath: result.directory.appendingPathComponent("images/04.jpg").path))
        }
        XCTAssertEqual(seconds.count, 30); XCTAssertEqual(fixture.reader.requests, 120)
        let p95 = seconds.sorted()[28]
        XCTAssertLessThanOrEqual(p95, 10)
        XCTAssertEqual(fixture.reader.networkRequests, 120, "出力はPhotoKit取得を許可する。合成入力なので実通信はしない")
        print("U3 normal export trials=30 images=4 input=4096x3072 bodyEach=10000 p95Seconds=\(p95) maxSeconds=\(seconds.max()!) samples=\(seconds)")
    }
    func testExportMemoryAndCancellationThirtyTrials() async throws {
        XCTAssertNotEqual(ProcessInfo.processInfo.environment["GITHUB_ACTIONS"], "true", "実メモリの合否は本人Macだけで判定")
        let fixture = try performanceFixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let images = ArticleImageAccess(reader: fixture.reader)
        let delivery = ArticleExportDelivery(images: images, journal: ArticleExportJournal(directory: fixture.root.appendingPathComponent("jobs")))
        let monitor = ExportMemoryMonitor(), sampling = monitor.start()
        defer { sampling.cancel() }
        try await Task.sleep(for: .milliseconds(5250))
        let baseline = monitor.observations
        XCTAssertGreaterThanOrEqual(baseline.count, 100)
        XCTAssertGreaterThanOrEqual(exportSeconds(baseline.first!.instant.duration(to: baseline.last!.instant)), 5)
        let median = baseline.map(\.bytes).sorted()[baseline.count / 2]
        for _ in 0..<30 { _ = try await delivery.run(jobID: UUID(), prepared: fixture.prepared, destination: fixture.root) }
        var acceptance: [Double] = [], logical: [Double] = [], cleanup: [Double] = []
        for _ in 0..<30 {
            let before = fixture.reader.requests, jobID = UUID()
            let task = Task { () -> Result<ExportResult, ArticleFailure> in
                do { return .success(try await delivery.run(jobID: jobID, prepared: fixture.prepared, destination: fixture.root)) }
                catch { return .failure(error as? ArticleFailure ?? .ioFailure) }
            }
            try await ExportFixture.waitUntil { fixture.reader.requests > before && images.isBusy }
            let token = fixture.reader.requests, requested = ContinuousClock().now
            await delivery.cancel(jobID)
            acceptance.append(exportSeconds(requested.duration(to: ContinuousClock().now)))
            let outcome = await task.value, ended = ContinuousClock().now
            guard case .failure(.cancelled) = outcome else { XCTFail("取消試行はcancelledへ収束する必要があります"); throw ArticleFailure.invalidInput }
            let terminal = try XCTUnwrap(fixture.reader.cancelTimes[token])
            logical.append(max(0, exportSeconds(requested.duration(to: terminal))))
            cleanup.append(exportSeconds(requested.duration(to: ended)))
            let pending = try await delivery.pending(); XCTAssertNil(pending)
            XCTAssertFalse(images.isBusy)
        }
        sampling.cancel(); try await sampling.value
        let samples = monitor.observations
        let maximumGap = zip(samples, samples.dropFirst()).map { exportSeconds($0.instant.duration(to: $1.instant)) }.max() ?? .infinity
        let peak = samples.map(\.bytes).max()!, delta = peak > median ? peak - median : 0
        XCTAssertLessThanOrEqual(maximumGap, 0.05, "実観測間隔の最大値")
        XCTAssertLessThanOrEqual(delta, 512 * 1024 * 1024)
        XCTAssertLessThanOrEqual(images.peakReservedImageBytes, 256 * 1024 * 1024)
        XCTAssertEqual(images.reservedImageBytes, 0)
        XCTAssertEqual(acceptance.count, 30); XCTAssertEqual(logical.count, 30); XCTAssertEqual(cleanup.count, 30)
        XCTAssertLessThanOrEqual(acceptance.max()!, 0.5)
        XCTAssertLessThanOrEqual(logical.max()!, 2)
        XCTAssertLessThanOrEqual(cleanup.sorted()[28], 5)
        print("U3 memory baselineSamples=\(baseline.count) sampleCount=\(samples.count) maxObservedGapSeconds=\(maximumGap) baselineMedianBytes=\(median) peakBytes=\(peak) incrementBytes=\(delta) directPeakBytes=\(images.peakReservedImageBytes)")
        print("U3 cancellation trials=30 acceptanceSeconds=\(acceptance) logicalSeconds=\(logical) cleanupSeconds=\(cleanup) cleanupP95Seconds=\(cleanup.sorted()[28])")
    }
    private func performanceFixture() throws -> (root: URL, prepared: PreparedArticleExport, reader: ExportPerformanceReader) {
        let root = try ExportFixture.root("performance")
        let source = try ArticleSource(selection: CommittedSelection(albumID: "performance", albumTitle: String(repeating: "題", count: 200), orderedAssetIDs: ["a", "b", "c", "d"]))
        var content = ArticleContent(source: source)
        content.introduction = String(repeating: "導", count: 10000); content.closing = String(repeating: "結", count: 10000)
        for index in 0..<4 { content.photoTexts[index].text = String(repeating: "写", count: 10000) }
        let article = try SavedArticle(projectID: UUID(), source: source, content: content)
        let prepared = try PreparedArticleExport(savedInput: SavedExportInput(article: article), rendered: ArticleProjectionContext(projectID: article.projectID).renderArticle(source: source, content: content))
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = try XCTUnwrap(CGContext(data: nil, width: 4096, height: 3072, bitsPerComponent: 8, bytesPerRow: 4096 * 4, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: 4096, height: 3072))
        let image = try XCTUnwrap(context.makeImage())
        var inputs: [String: ArticleImageInput] = [:]
        for assetID in source.orderedAssetIDs {
            let url = root.appendingPathComponent("synthetic-" + assetID + ".jpg")
            let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil))
            CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
            guard CGImageDestinationFinalize(destination) else { throw ArticleFailure.ioFailure }
            inputs[assetID] = ArticleImageInput(url: url, orientation: 1)
        }
        return (root, prepared, ExportPerformanceReader(inputs: inputs))
    }
}

private func exportSeconds(_ duration: Duration) -> Double {
    let parts = duration.components
    return Double(parts.seconds) + Double(parts.attoseconds) / 1e18
}

@MainActor private final class ExportPerformanceReader: ArticleImageReading {
    let inputs: [String: ArticleImageInput]
    private(set) var requests = 0
    private(set) var networkRequests = 0
    private(set) var cancelTimes: [Int: ContinuousClock.Instant] = [:]
    init(inputs: [String: ArticleImageInput]) { self.inputs = inputs }
    func request(_ id: String, networkAllowed: Bool, completion: @escaping @MainActor (Result<ArticleImageInput, ArticleFailure>) -> Void) -> Int {
        requests += 1
        if networkAllowed { networkRequests += 1 }
        if let input = inputs[id] { completion(.success(input)) }
        else { completion(.failure(.assetUnavailable)) }
        return requests
    }
    func cancel(_ request: Int) { cancelTimes[request] = ContinuousClock().now }
}

private struct ExportMemoryObservation: Sendable {
    let instant: ContinuousClock.Instant
    let bytes: UInt64
}
private final class ExportMemoryMonitor: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [ExportMemoryObservation] = []
    var observations: [ExportMemoryObservation] { lock.lock(); defer { lock.unlock() }; return values }
    private func append(_ value: ExportMemoryObservation) { lock.lock(); values.append(value); lock.unlock() }
    func start() -> Task<Void, Error> {
        Task.detached {
            while !Task.isCancelled {
                var info = task_vm_info_data_t(), count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
                let result = withUnsafeMutablePointer(to: &info) { pointer in
                    pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count) }
                }
                guard result == KERN_SUCCESS else { throw ArticleFailure.ioFailure }
                self.append(ExportMemoryObservation(instant: ContinuousClock().now, bytes: info.phys_footprint))
                do { try await Task.sleep(for: .milliseconds(10)) } catch { break }
            }
        }
    }
}
