import XCTest
@testable import HitotsuzuriCore

@MainActor final class ArticleNavigationTests: XCTestCase {
    func testCanonicallyEquivalentByteChangeDuringReadCancelsReplacement() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession(), source=try DraftFixtures.source()
        let target=try await h.store.create(projectID:UUID(),operationID:UUID(),source:source,content:ArticleContent(source:source))
        session.content.title="e\u{301}"; _=await h.presentation.requestNavigation(.article(target.id))
        await h.store.configure(pauseOpen:true)
        let task=Task {await h.presentation.resolveNavigation(.discard)}
        guard await draftWaitUntil({await h.store.waiting}) else {_=await task.value; return XCTFail("読込を開始")}
        session.content.title="\u{e9}"; await h.store.release()
        let result=await task.value; XCTAssertFalse(result); XCTAssertTrue(h.presentation.session === session)
        XCTAssertEqual(Array(session.content.title.utf8),[0xc3,0xa9])
    }
    func testNewInputDuringDiscardTargetReadIsNotLost() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession()
        let source=try DraftFixtures.source(), target=try await h.store.create(projectID:UUID(),operationID:UUID(),source:source,content:ArticleContent(source:source))
        session.content.title="離脱前"; _=await h.presentation.requestNavigation(.article(target.id))
        await h.store.configure(pauseOpen:true)
        let task=Task {await h.presentation.resolveNavigation(.discard)}
        guard await draftWaitUntil({await h.store.waiting}) else {_=await task.value; return XCTFail("読込を開始")}
        session.content.title="読込中の新入力"; await h.store.release()
        let result=await task.value; XCTAssertFalse(result)
        XCTAssertTrue(h.presentation.session === session); XCTAssertEqual(session.content.title,"読込中の新入力")
    }
    func testNewInputDuringNewTargetSaveIsNotLost() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession()
        session.content.title="離脱前"
        await h.selections.set(CommittedSelection(albumID:"別",albumTitle:"別記事",orderedAssetIDs:["w","x","y","z"]))
        _=await h.presentation.requestNavigation(.currentSelection); await h.store.configure(pause:true)
        let task=Task {await h.presentation.resolveNavigation(.discard)}
        guard await draftWaitUntil({await h.store.waiting}) else {_=await task.value; return XCTFail("保存を開始")}
        session.content.title="保存中の新入力"; await h.store.release()
        let result=await task.value; XCTAssertFalse(result)
        XCTAssertTrue(h.presentation.session === session); XCTAssertEqual(session.content.title,"保存中の新入力")
    }
    func testEveryDepartureRequiresSingleDirtyConfirmation() async throws {
        for target in [ArticleNavigationDestination.back,.closeWindow,.terminate,.article(UUID()),.currentSelection,.reload] {
            let h=DraftHarness.make(), session=try await h.savedSession(); session.content.title="未保存"
            let left=await h.presentation.requestNavigation(target)
            XCTAssertFalse(left); XCTAssertEqual(h.presentation.pendingNavigation,target); XCTAssertTrue(h.presentation.session === session)
        }
    }
    func testSecondDestinationCannotReplacePendingOne() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession(); session.content.title="未保存"
        _=await h.presentation.requestNavigation(.back); _=await h.presentation.requestNavigation(.terminate)
        XCTAssertEqual(h.presentation.pendingNavigation,.back)
    }
    func testContinueKeepsInputAndClearsPending() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession(); session.content.title="未保存"
        _=await h.presentation.requestNavigation(.back)
        let result=await h.presentation.resolveNavigation(.keepEditing); XCTAssertFalse(result)
        XCTAssertNil(h.presentation.pendingNavigation); XCTAssertEqual(session.content.title,"未保存")
    }
    func testExplicitDiscardPreservesStoredArticle() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession(), saved=try XCTUnwrap(session.saved)
        session.content.title="未保存"; _=await h.presentation.requestNavigation(.back)
        let result=await h.presentation.resolveNavigation(.discard); XCTAssertTrue(result); XCTAssertNil(h.presentation.session)
        let reopened=try await h.store.open(saved.id); XCTAssertEqual(reopened,saved)
    }
    func testSaveFailureKeepsOldSessionAndPendingTarget() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession(); session.content.title="未保存"
        await h.store.configure(save:[.permissionDenied]); _=await h.presentation.requestNavigation(.terminate)
        let result=await h.presentation.resolveNavigation(.save); XCTAssertFalse(result); XCTAssertTrue(h.presentation.session === session)
        XCTAssertEqual(session.content.title,"未保存")
    }
    func testInvalidRawDateBlocksSaveAndLeave() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession()
        session.metadataInput.change(year:"2026",month:"2",day:"31")
        _=await h.presentation.requestNavigation(.closeWindow)
        let result=await h.presentation.resolveNavigation(.save); XCTAssertFalse(result); XCTAssertTrue(h.presentation.session === session)
    }
    func testFailedTargetPreparationRetainsDiscardedWorkingValues() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession(); session.content.introduction="残す"
        _=await h.presentation.requestNavigation(.article(UUID()))
        await h.store.configure(open:.ioFailure)
        let result=await h.presentation.resolveNavigation(.discard); XCTAssertFalse(result)
        XCTAssertTrue(h.presentation.session === session); XCTAssertEqual(session.content.introduction,"残す")
    }
    func testCleanLeaveNeedsNoConfirmation() async throws {
        let h=DraftHarness.make(); _=try await h.savedSession()
        let result=await h.presentation.requestNavigation(.back); XCTAssertTrue(result)
        XCTAssertNil(h.presentation.pendingNavigation); XCTAssertNil(h.presentation.session)
    }
}
