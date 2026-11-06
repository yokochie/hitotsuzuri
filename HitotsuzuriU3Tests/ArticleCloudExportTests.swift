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
        let delivery = ArticleExportDelivery(images: images, journal: ArticleExportJournal(directory: root.appendingPathComponent("jobs")), now: { clock.now() })
        do {
            let result = try await delivery.run(jobID: UUID(), prepared: ExportFixture.prepared(), destination: root)
            XCTAssertTrue(FileManager.default.fileExists(atPath: result.directory.appendingPathComponent("images/04.jpg").path))
        } catch { XCTFail("各画像301秒の待機だけで出力を打ち切った: \(error)") }
    }
}

@MainActor private final class CloudExportImages: ArticleExportImageProviding {
    var isBusy = false
    var reservedImageBytes = 0
    var peakReservedImageBytes = 0
    var flags: [Bool] = [], assets: [String] = []
    var onAcquire: (() -> Void)?
    func image(_ assetID: String, requestID: UUID) async throws -> ArticleJPEG {
        try await image(assetID, requestID: requestID, networkAllowed: false, progress: { _ in })
    }
    func image(_ assetID: String, requestID: UUID, networkAllowed: Bool, progress: @escaping @MainActor (Double) -> Void) async throws -> ArticleJPEG {
        flags.append(networkAllowed); assets.append(assetID); onAcquire?()
        progress(0); progress(0.5); progress(1)
        return try ExportFixture.jpeg()
    }
    func cancel(_ requestID: UUID) { }
}
