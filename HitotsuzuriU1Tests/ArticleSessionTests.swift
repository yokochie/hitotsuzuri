import XCTest
@testable import HitotsuzuriCore

@MainActor final class ArticleSessionTests: XCTestCase {
    func testEditingIsNotAutomaticSave() async throws {
        let store = ArticlePersistence(directory: ArticleFixtures.root()), a = try await ArticleFixtures.create(store)
        let session = ArticleEditSession(article: a, store: store)
        session.content.title = "編集中"
        XCTAssertTrue(session.isDirty)
        let disk = try await store.open(a.projectID); XCTAssertEqual(disk.content.title, a.content.title)
    }
    func testSaveSuccessMarksOnlySavedInputClean() async throws {
        let store = ArticlePersistence(directory: ArticleFixtures.root()), a = try await ArticleFixtures.create(store)
        let session = ArticleEditSession(article: a, store: store)
        session.content.title = "保存"
        let success = await session.save(); XCTAssertTrue(success)
        XCTAssertFalse(session.isDirty); XCTAssertEqual(session.state, .clean)
    }
    func testSaveFailureKeepsInputAndOldData() async throws {
        let root = ArticleFixtures.root(), store = ArticlePersistence(directory: root), a = try await ArticleFixtures.create(store)
        let failing = ArticlePersistence(directory: root, checkpoint: { if $0 == .beforeCurrent { throw ArticleFailure.capacity } })
        let session = ArticleEditSession(article: a, store: failing); session.content.title = "保持"
        let success = await session.save(); XCTAssertFalse(success); XCTAssertEqual(session.content.title, "保持")
        XCTAssertTrue(session.isDirty)
    }
    func testExplicitDiscardLeavesOldSavedArticle() async throws {
        let store = ArticlePersistence(directory: ArticleFixtures.root()), a = try await ArticleFixtures.create(store)
        let session = ArticleEditSession(article: a, store: store); session.content.title = "discard"
        let leave = await session.canLeave(.discard); XCTAssertTrue(leave)
        let disk = try await store.open(a.projectID); XCTAssertEqual(disk, a)
    }
    func testKeepEditingDoesNotLeave() async throws {
        let store = ArticlePersistence(directory: ArticleFixtures.root()), a = try await ArticleFixtures.create(store)
        let session = ArticleEditSession(article: a, store: store); session.content.title = "keep"
        let leave = await session.canLeave(.keepEditing); XCTAssertFalse(leave); XCTAssertEqual(session.content.title, "keep")
    }
    func testSaveAndLeaveRequiresSuccess() async throws {
        let store = ArticlePersistence(directory: ArticleFixtures.root()), a = try await ArticleFixtures.create(store)
        let session = ArticleEditSession(article: a, store: store); session.content.title = "saved"
        let leave = await session.canLeave(.save); XCTAssertTrue(leave); XCTAssertFalse(session.isDirty)
    }
}
