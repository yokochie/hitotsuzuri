import XCTest
@testable import HitotsuzuriCore

@MainActor final class ArticleDraftSessionTests: XCTestCase {
    func testAllFieldsSaveAndRestoreExactly() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession()
        session.content.title="題e\u{301}👩‍👧"; session.content.introduction="導入\n引用\""; session.content.closing="結び"
        for i in 0..<4 { session.content.photoTexts[i].text="本文\(i)\n" }
        session.content.location=" 場所 "; session.content.equipment="機材"; session.content.film="フィルム"; session.content.people="人物"
        session.metadataInput.change(year:"1",month:"12",day:"31"); try session.metadataInput.confirm()
        let result=await session.save(); XCTAssertTrue(result)
        let reopened=try await h.store.open(session.projectID)
        XCTAssertEqual(reopened.content,try session.validatedContent())
        XCTAssertEqual(reopened.content.shootingDate?.year,1); XCTAssertEqual(reopened.content.dateCandidateState,.confirmed)
    }
    func testInvalidRawIsDirtyAndDoesNotSaveOldValidDate() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession(), old=try XCTUnwrap(session.saved)
        session.metadataInput.change(year:"2026",month:"2",day:"31")
        XCTAssertTrue(session.isDirty); XCTAssertThrowsError(try session.validatedContent())
        let result=await session.save(); XCTAssertFalse(result)
        XCTAssertEqual(session.metadataInput.day,"31")
        let reopened=try await h.store.open(old.id); XCTAssertEqual(reopened,old)
    }
    func testRawRestorationClearsDirtyAndRemovalPersists() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession(), baseline=session.metadataInput
        session.metadataInput.change(year:"xx",month:"9",day:"13"); XCTAssertTrue(session.isDirty)
        session.metadataInput=baseline; XCTAssertFalse(session.isDirty)
        session.metadataInput.remove(); XCTAssertTrue(session.isDirty)
        let result=await session.save(); XCTAssertTrue(result)
        XCTAssertNil(session.saved?.content.shootingDate)
    }
    func testEditWhileSavingKeepsLaterInputDirty() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession()
        session.content.title="固定"; await h.store.configure(pause:true)
        let task=Task { await session.save() }
        guard await draftWaitUntil({ await h.store.waiting }) else { _=await task.value; return XCTFail("保存境界を呼ぶ") }
        session.content.title="後続"; session.metadataInput.change(year:"2024",month:"2",day:"29")
        await h.store.release(); let result=await task.value
        XCTAssertTrue(result); XCTAssertEqual(session.saved?.content.title,"固定"); XCTAssertTrue(session.isDirty)
        XCTAssertEqual(session.content.title,"後続"); XCTAssertEqual(session.metadataInput.year,"2024")
    }
    func testUncertaintySurvivesRepeatedIOAndLatestFailureClassification() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession()
        session.content.title="元操作"; await h.store.configure(lose:true)
        let first=await session.save(); XCTAssertFalse(first); XCTAssertTrue(session.hasUncertainSave)
        await h.store.configure(save:[.ioFailure,.ioFailure]); session.content.title="追加"
        for _ in 0..<2 { let result=await session.save(); XCTAssertFalse(result); XCTAssertTrue(session.hasUncertainSave); XCTAssertEqual(session.failure,.ioFailure) }
        let success=await session.save(); XCTAssertTrue(success); XCTAssertFalse(session.hasUncertainSave)
        XCTAssertEqual(session.saved?.content.title,"追加"); XCTAssertFalse(session.isDirty)
        let ids=await h.store.operationIDs; XCTAssertEqual(ids[1],ids[2]); XCTAssertEqual(ids[2],ids[3])
    }
    func testDefiniteCapacityFailureCanShrinkAndSave() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession()
        await h.store.configure(save:[.capacity]); session.content.title="大きい"
        let first=await session.save(); XCTAssertFalse(first); XCTAssertFalse(session.hasUncertainSave)
        session.content.title="小さい"; let second=await session.save(); XCTAssertTrue(second)
        XCTAssertEqual(session.saved?.content.title,"小さい")
    }
    func testConflictKeepsDraftAndOldBaseline() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession(), old=session.saved
        await h.store.configure(save:[.conflict]); session.content.people="未保存の人物"
        let result=await session.save(); XCTAssertFalse(result)
        XCTAssertEqual(session.saved,old); XCTAssertEqual(session.content.people,"未保存の人物")
    }
    func testNewFactoryInjectionDoesNotReinitializeSavedEmptyTitle() async throws {
        let h=DraftHarness.make(), source=try await h.workspace.readCommittedSelection()
        let session=ArticleEditSession(source:source,store:h.store,initialContent:ArticleInitialContent(source:source).content)
        XCTAssertEqual(session.content.title,"散歩")
        session.content.title=""; let result=await session.save(); XCTAssertTrue(result)
        let reopened=ArticleEditSession(article:try XCTUnwrap(session.saved),store:h.store)
        XCTAssertEqual(reopened.content.title,""); XCTAssertEqual(reopened.metadataInput.candidateState,.candidate)
    }
}
