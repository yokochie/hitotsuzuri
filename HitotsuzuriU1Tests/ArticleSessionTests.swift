import XCTest
@testable import HitotsuzuriCore

@MainActor final class ArticleSessionTests: XCTestCase {
    func testEditingDuringSaveStaysDirtyAndResponseCannotReplaceInput() async throws {
        let original=try await ArticleFixtures.create(ArticlePersistence(directory:ArticleFixtures.root())), gate=ArticleSaveGate()
        let session=ArticleEditSession(article:original,store:gate); session.content.title="保存対象"
        let task=Task {await session.save()}
        while !(await gate.started) {await Task.yield()}
        session.content.title="保存中の新入力"
        await gate.complete()
        let success=await task.value
        XCTAssertTrue(success); XCTAssertTrue(session.isDirty)
        XCTAssertEqual(session.saved?.content.title,"保存対象"); XCTAssertEqual(session.content.title,"保存中の新入力")
    }
    func testDoubleSaveAndDiscardAreRejectedWhileSaving() async throws {
        let original=try await ArticleFixtures.create(ArticlePersistence(directory:ArticleFixtures.root())), gate=ArticleSaveGate()
        let session=ArticleEditSession(article:original,store:gate)
        let task=Task {await session.save()}
        while !(await gate.started) {await Task.yield()}
        let second=await session.save(), leave=await session.canLeave(.discard)
        XCTAssertFalse(second); XCTAssertFalse(leave)
        await gate.complete(); _ = await task.value
    }
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
private actor ArticleSaveGate: ArticleStoring {
    var started=false
    var continuation:CheckedContinuation<Void,Never>?
    func complete() {continuation?.resume(); continuation=nil}
    func create(projectID:UUID,operationID:UUID,source:ArticleSource,content:ArticleContent) throws -> SavedArticle {try SavedArticle(projectID:projectID,source:source,content:content)}
    func open(_ projectID:UUID) throws ->SavedArticle {throw ArticleFailure.missing}
    func list()->ArticleDraftList {ArticleDraftList()}
    func save(projectID:UUID,operationID:UUID,expected:SavedArticle,content:ArticleContent) async throws ->SavedArticle {
        started=true
        await withCheckedContinuation {continuation=$0}
        var result=expected; result.content=content; result.savedRevision += 1; result.fingerprint=ArticleFingerprint.content(source:expected.source,content:content)
        return result
    }
}
