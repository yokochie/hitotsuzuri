import XCTest
@testable import HitotsuzuriCore

@MainActor final class ArticleSessionTests: XCTestCase {
    func testEditsDuringUncertainReconciliationRemainDirty() async throws {
        let disk=ArticlePersistence(directory:ArticleFixtures.root()), original=try await ArticleFixtures.create(disk)
        let store=ArticleResponseLossStore(disk:disk,loseCreate:false), session=ArticleEditSession(article:original,store:store)
        session.content.title="A"; _ = await session.save()
        session.content.title="B"; await store.pauseNextRequest()
        let retry=Task {await session.save()}
        while !(await store.waiting) {await Task.yield()}
        session.content.title="照合中の入力C"
        await store.resume(); let success=await retry.value
        XCTAssertTrue(success); XCTAssertEqual(session.saved?.content.title,"B")
        XCTAssertEqual(session.content.title,"照合中の入力C"); XCTAssertTrue(session.isDirty)
        let final=await session.save(); XCTAssertTrue(final); XCTAssertFalse(session.isDirty)
    }
    func testCapacityFailureKeepsInputAndAllowsReducedPayload() async throws {
        let disk=ArticlePersistence(directory:ArticleFixtures.root()), original=try await ArticleFixtures.create(disk)
        let session=ArticleEditSession(article:original,store:disk)
        session.content.introduction=String(repeating:"x",count:64*1024*1024)
        let failed=await session.save(); XCTAssertFalse(failed); XCTAssertEqual(session.failure,.capacity)
        XCTAssertEqual(session.content.introduction.utf8.count,64*1024*1024); XCTAssertEqual(session.saved,original)
        session.content.introduction="入力を縮めて再保存"
        let saved=await session.save(); XCTAssertTrue(saved); XCTAssertFalse(session.isDirty)
        let reopened=try await disk.open(session.projectID); XCTAssertEqual(reopened.content.introduction,"入力を縮めて再保存")
    }
    func testUncertainSaveReconcilesFrozenInputBeforeSavingFurtherEdits() async throws {
        let disk=ArticlePersistence(directory:ArticleFixtures.root()), original=try await ArticleFixtures.create(disk)
        let store=ArticleResponseLossStore(disk:disk,loseCreate:false), session=ArticleEditSession(article:original,store:store)
        session.content.title="保存A"
        let first=await session.save(); XCTAssertFalse(first); XCTAssertEqual(session.failure,.uncertainResult)
        session.content.title="追加入力B"
        let retry=await session.save(); XCTAssertTrue(retry)
        XCTAssertEqual(session.content.title,"追加入力B"); XCTAssertEqual(session.saved?.content.title,"追加入力B")
        XCTAssertEqual(session.saved?.savedRevision,3); XCTAssertFalse(session.isDirty)
        let ids=await store.operationIDs; XCTAssertEqual(ids.count,3)
        if ids.count == 3 {XCTAssertEqual(ids[0],ids[1]); XCTAssertNotEqual(ids[1],ids[2])}
    }
    func testUncertainCreationReconcilesBeforeSavingFurtherEdits() async throws {
        let disk=ArticlePersistence(directory:ArticleFixtures.root()), store=ArticleResponseLossStore(disk:disk,loseCreate:true)
        let session=ArticleEditSession(source:try ArticleFixtures.source(),store:store)
        session.content.title="初期A"
        let first=await session.save(); XCTAssertFalse(first)
        session.content.title="追加入力B"
        let retry=await session.save(); XCTAssertTrue(retry)
        XCTAssertEqual(session.content.title,"追加入力B"); XCTAssertEqual(session.saved?.savedRevision,2)
        let restored=try await disk.open(session.projectID); XCTAssertEqual(restored.content.title,"追加入力B")
    }
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
private actor ArticleResponseLossStore:ArticleStoring {
    let disk:ArticlePersistence, loseCreate:Bool
    var lost=false, operationIDs:[UUID]=[]
    private var shouldPause=false
    private var continuation:CheckedContinuation<Void,Never>?
    var waiting=false
    func pauseNextRequest() {shouldPause=true}
    func resume() {continuation?.resume(); continuation=nil}
    private func waitIfNeeded() async {
        guard shouldPause else {return}; shouldPause=false; waiting=true
        await withCheckedContinuation {continuation=$0}; waiting=false
    }
    init(disk:ArticlePersistence,loseCreate:Bool) {self.disk=disk; self.loseCreate=loseCreate}
    func create(projectID:UUID,operationID:UUID,source:ArticleSource,content:ArticleContent) async throws ->SavedArticle {
        operationIDs.append(operationID)
        await waitIfNeeded()
        let result=try await disk.create(projectID:projectID,operationID:operationID,source:source,content:content)
        if loseCreate && !lost {lost=true; throw ArticleFailure.uncertainResult}; return result
    }
    func save(projectID:UUID,operationID:UUID,expected:SavedArticle,content:ArticleContent) async throws ->SavedArticle {
        operationIDs.append(operationID)
        await waitIfNeeded()
        let result=try await disk.save(projectID:projectID,operationID:operationID,expected:expected,content:content)
        if !loseCreate && !lost {lost=true; throw ArticleFailure.uncertainResult}; return result
    }
    func open(_ projectID:UUID) async throws ->SavedArticle {try await disk.open(projectID)}
    func list() async throws ->ArticleDraftList {try await disk.list()}
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
