import XCTest
@testable import HitotsuzuriCore

@MainActor final class ArticleExportDeliveryTests: XCTestCase {
    func testFourImagesAreRequestedInOrder() async throws {
        let root = try ExportFixture.root(); defer { try? FileManager.default.removeItem(at: root) }
        let images = ExportTestImages(), journal = ArticleExportJournal(directory: root.appendingPathComponent("jobs"))
        let delivery = ArticleExportDelivery(images: images, journal: journal), prepared = try ExportFixture.prepared()
        let result = try? await delivery.run(jobID: UUID(), prepared: prepared, destination: root)
        XCTAssertNotNil(result); XCTAssertEqual(images.calls, ["a", "b", "c", "d"])
    }
    func testSecondImageFailureStopsAndPreservesText() async throws {
        let root = try ExportFixture.root(); defer { try? FileManager.default.removeItem(at: root) }
        let images = ExportTestImages(); images.failureAt = 2
        let delivery = ArticleExportDelivery(images: images, journal: ArticleExportJournal(directory: root.appendingPathComponent("jobs")))
        do { _ = try await delivery.run(jobID: UUID(), prepared: ExportFixture.prepared(), destination: root); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .assetUnavailable) }
        let detail = await delivery.failureDetail
        XCTAssertEqual(images.calls, ["a", "b"]); XCTAssertEqual(detail?.photoIndex, 2)
    }
    func testStageDeadlineDiscardsLateImage() async throws {
        let root = try ExportFixture.root(); defer { try? FileManager.default.removeItem(at: root) }
        let clock = ExportTestClock(), images = ExportTestImages()
        images.onRequest = { _ in clock.advance(.seconds(41)) }
        let delivery = ArticleExportDelivery(images: images, journal: ArticleExportJournal(directory: root.appendingPathComponent("jobs")), now: { clock.now() })
        do { _ = try await delivery.run(jobID: UUID(), prepared: ExportFixture.prepared(), destination: root); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .timedOut) }
        XCTAssertEqual(images.calls.count, 1)
    }
    func testOverallDeadlineStopsNewCommit() async throws {
        let root = try ExportFixture.root(); defer { try? FileManager.default.removeItem(at: root) }
        let clock = ExportTestClock(), images = ExportTestImages()
        images.onRequest = { index in if index == 4 { clock.advance(.seconds(181)) } }
        let delivery = ArticleExportDelivery(images: images, journal: ArticleExportJournal(directory: root.appendingPathComponent("jobs")), now: { clock.now() })
        do { _ = try await delivery.run(jobID: UUID(), prepared: ExportFixture.prepared(), destination: root); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .timedOut) }
    }
    func testCancellationWaitsForImageAndCleanup() async throws {
        let root = try ExportFixture.root(); defer { try? FileManager.default.removeItem(at: root) }
        let images = ExportTestImages(), latch = U3Latch(); images.pause = latch
        let delivery = ArticleExportDelivery(images: images, journal: ArticleExportJournal(directory: root.appendingPathComponent("jobs"))), id = UUID()
        let task = Task { try? await delivery.run(jobID: id, prepared: ExportFixture.prepared(), destination: root) }
        try await ExportFixture.waitUntil { latch.waiting }
        await delivery.cancel(id); let result = await task.value
        XCTAssertNil(result); XCTAssertEqual(images.cancelled.count, 1)
        let pending = try await delivery.pending(); XCTAssertNil(pending)
        XCTAssertFalse(try FileManager.default.contentsOfDirectory(atPath: root.path).contains { $0.hasPrefix(".article-export-") })
    }
    func testDuplicateActiveJobDoesNotAcquireAnotherImage() async throws {
        let root = try ExportFixture.root(); defer { try? FileManager.default.removeItem(at: root) }
        let images = ExportTestImages(), latch = U3Latch(); images.pause = latch
        let delivery = ArticleExportDelivery(images: images, journal: ArticleExportJournal(directory: root.appendingPathComponent("jobs"))), id = UUID(), prepared = try ExportFixture.prepared()
        let task = Task { try? await delivery.run(jobID: id, prepared: prepared, destination: root) }
        try await ExportFixture.waitUntil { latch.waiting }
        do { _ = try await delivery.run(jobID: id, prepared: prepared, destination: root); XCTFail() } catch { XCTAssertEqual(error as? ArticleFailure, .busy) }
        await delivery.cancel(id); _ = await task.value
        XCTAssertEqual(images.calls.count, 1)
    }
    func testCompletedIDIsReconciledWithoutRegeneration() async throws {
        let root = try ExportFixture.root(); defer { try? FileManager.default.removeItem(at: root) }
        let images = ExportTestImages(), delivery = ArticleExportDelivery(images: images, journal: ArticleExportJournal(directory: root.appendingPathComponent("jobs")))
        let id = UUID(), prepared = try ExportFixture.prepared()
        let first = try? await delivery.run(jobID: id, prepared: prepared, destination: root)
        let second = try? await delivery.run(jobID: id, prepared: prepared, destination: root)
        XCTAssertNotNil(first); XCTAssertEqual(first, second); XCTAssertEqual(images.calls.count, 4)
    }
    func testImageBudgetExcessIsRejected() async throws {
        let root = try ExportFixture.root(); defer { try? FileManager.default.removeItem(at: root) }
        let images = ExportTestImages(); images.reservedImageBytes = 257 * 1024 * 1024
        let delivery = ArticleExportDelivery(images: images, journal: ArticleExportJournal(directory: root.appendingPathComponent("jobs")))
        do { _ = try await delivery.run(jobID: UUID(), prepared: ExportFixture.prepared(), destination: root); XCTFail() } catch { XCTAssertEqual(error as? ArticleFailure, .capacity) }
    }
}
