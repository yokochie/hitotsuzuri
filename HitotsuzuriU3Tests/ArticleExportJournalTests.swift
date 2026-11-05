import XCTest
@testable import HitotsuzuriCore

@MainActor final class ArticleExportJournalTests: XCTestCase {
    private var root: URL!
    override func setUpWithError() throws {
        root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".build/export-journal-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: root) }
    private func record() throws -> ArticleExportRecoveryRecord { try ArticleExportRecoveryRecord(jobID: UUID(), prepared: ExportFixture.prepared(), parentIdentity: ExportFixture.identity) }
    func testBeginsAndReopensTheSameRecord() async throws {
        let value = try record(); let journal = ArticleExportJournal(directory: root)
        try await journal.begin(value)
        let result = try await ArticleExportJournal(directory: root).pending()
        XCTAssertEqual(result, value)
    }
    func testSameJobSameInputIsIdempotent() async throws {
        let value = try record(); let journal = ArticleExportJournal(directory: root)
        try await journal.begin(value); try await journal.begin(value)
        let result = try await journal.lookup(value.jobID)
        XCTAssertEqual(result, value)
    }
    func testAnotherActiveJobIsRejected() async throws {
        let journal = ArticleExportJournal(directory: root)
        try await journal.begin(record())
        do { try await journal.begin(record()); XCTFail("別ジョブを開始した") } catch { XCTAssertEqual(error as? ArticleFailure, .busy) }
    }
    func testReusedIDWithDifferentInputIsRejected() async throws {
        let value = try record(); let journal = ArticleExportJournal(directory: root)
        try await journal.begin(value)
        let changed = try ArticleExportRecoveryRecord(jobID: value.jobID, prepared: ExportFixture.prepared(title: "異入力"), parentIdentity: ExportFixture.identity)
        do { try await journal.begin(changed); XCTFail("異入力を受け付けた") } catch { XCTAssertEqual(error as? ArticleFailure, .conflict) }
    }
    func testExpectedOldRecordProtectsExternalChange() async throws {
        let value = try record(); let journal = ArticleExportJournal(directory: root)
        try await journal.begin(value)
        let bytes = Data("external".utf8); try bytes.write(to: root.appendingPathComponent("active"))
        var next = value; next.phase = .generating
        do { try await journal.update(next, expected: value); XCTFail("外部変更を上書きした") } catch { }
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent("active")), bytes)
    }
    func testUnknownVersionIsProtected() async throws {
        var value = try record(); value.schemaVersion = 2
        try JSONEncoder().encode(value).write(to: root.appendingPathComponent("active"))
        do { _ = try await ArticleExportJournal(directory: root).pending(); XCTFail("未知版を読んだ") } catch { XCTAssertEqual(error as? ArticleFailure, .unsupportedVersion) }
    }
    func testCorruptRecordIsNotAnEmptyJournal() async throws {
        try Data("not json".utf8).write(to: root.appendingPathComponent("active"))
        do { _ = try await ArticleExportJournal(directory: root).pending(); XCTFail("破損を空と扱った") } catch { XCTAssertEqual(error as? ArticleFailure, .corruptData) }
    }
    func testFinishingArchivesBeforeClearingActive() async throws {
        let value = try record(); let journal = ArticleExportJournal(directory: root)
        try await journal.begin(value)
        var done = value; done.phase = .cancelled
        try await journal.finish(done, expected: value)
        let pending = try await journal.pending(), archived = try await journal.lookup(value.jobID)
        XCTAssertNil(pending); XCTAssertEqual(archived, done)
    }
}
