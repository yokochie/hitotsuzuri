import XCTest
@testable import HitotsuzuriCore

@MainActor final class ArticleOutputPreparationTests: XCTestCase {
    func testCopyDoesNotStartParallelProjectionWhilePreviewIsActive() async throws {
        let output=DraftOutput(), gate=DraftProjectionGate()
        let h=DraftHarness.make(output:output,projector:{context,source,content in try await gate.project(context,source:source,content:content)})
        _=try await h.savedSession(); let preview=Task {await h.presentation.showPreview()}
        guard await draftWaitUntil({gate.waiting}) else {await preview.value; return XCTFail("投影を開始")}
        let copied=await h.presentation.copyCurrent()
        XCTAssertFalse(copied); XCTAssertEqual(gate.invocations,1); XCTAssertTrue(output.copied.isEmpty)
        gate.release(); await preview.value
    }
    func testCopyRejectsProjectionWithDifferentProjectIdentity() async throws {
        let output=DraftOutput(), h=DraftHarness.make(output:output,projector:{_,source,content in
            try ArticleProjectionContext(projectID:UUID()).renderArticle(source:source,content:content)
        })
        _=try await h.savedSession()
        let result=await h.presentation.copyCurrent()
        XCTAssertFalse(result); XCTAssertTrue(output.copied.isEmpty)
    }
    func testDisconnectedActionsStayUnavailable() async throws {
        let h=DraftHarness.make(); _=try await h.savedSession()
        XCTAssertFalse(h.presentation.capabilities.copy); XCTAssertFalse(h.presentation.capabilities.export)
        let result=await h.presentation.copyCurrent(); XCTAssertFalse(result)
    }
    func testCopyUsesCurrentUnsavedInputAndDoesNotSave() async throws {
        let output=DraftOutput(), h=DraftHarness.make(output:output), session=try await h.savedSession(), saved=session.saved
        session.content.introduction="未保存コピー"
        let result=await h.presentation.copyCurrent(); XCTAssertTrue(result)
        XCTAssertTrue(output.copied.first?.0.contains("未保存コピー") == true)
        XCTAssertEqual(session.saved,saved); XCTAssertTrue(session.isDirty)
    }
    func testInvalidRawStopsCopyAndExportPreparation() async throws {
        let output=DraftOutput(), h=DraftHarness.make(output:output), session=try await h.savedSession()
        session.metadataInput.change(year:"2026",month:"",day:"1")
        let result=await h.presentation.copyCurrent(); XCTAssertFalse(result); XCTAssertTrue(output.copied.isEmpty)
        do { _=try await h.presentation.prepareSavedExport(.save); XCTFail("日付不正") } catch { XCTAssertEqual(error as? ArticleFailure,.invalidInput) }
    }
    func testCopyFailureNeverAnnouncesSuccess() async throws {
        let output=DraftOutput(), h=DraftHarness.make(output:output); _=try await h.savedSession(); output.failure = .ioFailure
        let result=await h.presentation.copyCurrent(); XCTAssertFalse(result); XCTAssertEqual(h.presentation.failure,.ioFailure)
    }
    func testLateCopyDoesNotMoveSuccessToAnotherProject() async throws {
        let output=DraftOutput(), h=DraftHarness.make(output:output), first=try await h.savedSession()
        first.content.title="固定コピー"; output.pause=true
        let task=Task { await h.presentation.copyCurrent() }
        guard await draftWaitUntil({ output.continuation != nil }) else { _=await task.value; return XCTFail("コピー境界を呼ぶ") }
        let other=ArticleEditSession(source:try DraftFixtures.source(),store:h.store)
        h.presentation.adopt(other); output.release(); _=await task.value
        XCTAssertNil(h.presentation.message); XCTAssertTrue(h.presentation.session === other)
        XCTAssertTrue(output.copied.first?.0.contains("固定コピー") == true)
    }
    func testSaveCancelDoesNotPrepareExport() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession(); session.content.title="未保存"
        let value=try await h.presentation.prepareSavedExport(.keepEditing)
        XCTAssertNil(value); XCTAssertTrue(session.isDirty)
    }
    func testSaveFailureDoesNotPrepareExport() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession(); session.content.title="未保存"
        await h.store.configure(save:[.capacity])
        do { _=try await h.presentation.prepareSavedExport(.save); XCTFail("保存失敗") } catch { XCTAssertEqual(error as? ArticleFailure,.capacity) }
        XCTAssertTrue(session.isDirty)
    }
    func testPreparationFreezesSavedInputWhileLaterEditsRemainDirty() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession(); session.content.title="出力固定"
        await h.store.configure(pause:true)
        let task=Task { try await h.presentation.prepareSavedExport(.save) }
        guard await draftWaitUntil({ await h.store.waiting }) else { _=try await task.value; return XCTFail("保存境界を呼ぶ") }
        session.content.title="後続"; await h.store.release()
        let result=try await task.value
        XCTAssertEqual(result?.article.content.title,"出力固定"); XCTAssertTrue(session.isDirty)
        XCTAssertEqual(result?.article.projectID,session.projectID)
    }
}
