import XCTest
@testable import HitotsuzuriCore

actor FakeStore: SelectionStoring {
    var selection: CommittedSelection?
    var settings: TargetFolderSettings?
    var fail=false
    func setFailure() { fail=true }
    func loadSettings() -> StoredValue<TargetFolderSettings> { settings.map { .valid($0) } ?? .missing }
    func loadSelection() -> StoredValue<CommittedSelection> { selection.map { .valid($0) } ?? .missing }
    func saveSettings(_ settings: TargetFolderSettings) throws { if fail { throw PickerFailure.ioFailure }; self.settings=settings }
    func saveSelection(_ selection: CommittedSelection) throws { if fail { throw PickerFailure.ioFailure }; self.selection=selection }
}
@MainActor func readyWorkflow(source: FakeLibrarySource = FakeLibrarySource(), store: FakeStore = FakeStore()) async -> SelectionWorkflow {
    let workflow=SelectionWorkflow(library:PhotoLibraryAccess(source:source),images:LocalImageAccess(driver:FakeImageDriver()),store:store)
    await workflow.start(); await workflow.setTargetFolders(["parent"])
    await workflow.selectAlbum(.init(id:"a",title:"同名"))
    for id in ["1","2","3","4","5"] { await workflow.loadImage(id) }
    return workflow
}
final class U1WorkflowTests: XCTestCase {
    @MainActor func testFourImageValidationUsesOneEarlierAbsoluteDeadline() async {
        let source=FakeLibrarySource(), driver=FakeImageDriver(), clock=ManualImageClock()
        let access=LocalImageAccess(driver:driver,clock:clock), store=FakeStore()
        let w=SelectionWorkflow(library:PhotoLibraryAccess(source:source),images:access,store:store,clock:clock,validationTimeout:.seconds(1))
        await w.start(); await w.setTargetFolders(["parent"]); await w.selectAlbum(.init(id:"a",title:"アルバム"))
        for id in ["1","2","3","4"] { await w.loadImage(id); w.toggle(id) }
        driver.onRequest={ count in if count==8 { clock.offset = .seconds(1) } }
        await w.confirm()
        XCTAssertEqual(w.error,.timedOut); XCTAssertNil(w.lastCommitted); XCTAssertFalse(w.isSaving)
        XCTAssertEqual(access.activeCount,0)
    }
    @MainActor func testRemovingAlbumClearsStaleSavedNotice() async {
        let w=await readyWorkflow(); for id in ["1","2","3","4"] { w.toggle(id) }; await w.confirm()
        let committed=w.lastCommitted; await w.setTargetFolders([])
        XCTAssertEqual(w.lastCommitted,committed); XCTAssertTrue(w.selection.orderedIDs.isEmpty)
        XCTAssertFalse(PresentationSnapshot(w).statusText.contains("4枚を保存しました"))
        XCTAssertTrue(PresentationSnapshot(w).statusText.contains("フォルダ"))
    }
    @MainActor func testStartsAuthorized() async { let w=await readyWorkflow(); XCTAssertEqual(w.authorization,.authorized); XCTAssertEqual(w.albums.count,3) }
    @MainActor func testFourSelectionAndFifthRefused() async { let w=await readyWorkflow(); for id in ["1","2","3","4","5"] { w.toggle(id) }; XCTAssertEqual(w.selection.orderedIDs,["1","2","3","4"]); XCTAssertTrue(w.canConfirm) }
    @MainActor func testDifferentAlbumClears() async { let w=await readyWorkflow(); w.toggle("1"); await w.selectAlbum(.init(id:"b",title:"同名")); XCTAssertTrue(w.selection.orderedIDs.isEmpty) }
    @MainActor func testSameAlbumPreserves() async { let w=await readyWorkflow(); w.toggle("1"); await w.selectAlbum(.init(id:"a",title:"同名")); XCTAssertEqual(w.selection.orderedIDs,["1"]) }
    @MainActor func testFolderExclusionClears() async { let w=await readyWorkflow(); w.toggle("1"); await w.setTargetFolders([]); XCTAssertNil(w.activeAlbum); XCTAssertTrue(w.selection.orderedIDs.isEmpty) }
    @MainActor func testConfirmPersists() async { let store=FakeStore(); let w=await readyWorkflow(store:store); for id in ["1","2","3","4"] { w.toggle(id) }; await w.confirm(); XCTAssertEqual(w.lastCommitted?.orderedAssetIDs,["1","2","3","4"]); XCTAssertFalse(w.isDirty) }
    @MainActor func testDeletedReferenceCannotSave() async { let source=FakeLibrarySource(); let w=await readyWorkflow(source:source); for id in ["1","2","3","4"] { w.toggle(id) }; source.photos["a"]=["1"]; await w.confirm(); XCTAssertNil(w.lastCommitted); XCTAssertEqual(w.error,.invalidReference) }
    @MainActor func testSaveFailurePreservesDraft() async { let store=FakeStore(); let w=await readyWorkflow(store:store); for id in ["1","2","3","4"] { w.toggle(id) }; await store.setFailure(); await w.confirm(); XCTAssertEqual(w.selection.orderedIDs,["1","2","3","4"]); XCTAssertEqual(w.error,.ioFailure) }
    @MainActor func testPermissionRequiresUserIntentBeforeFetch() async {
        let source=FakeLibrarySource(); source.access = .notDetermined
        let w=SelectionWorkflow(library:PhotoLibraryAccess(source:source),images:LocalImageAccess(driver:FakeImageDriver()),store:FakeStore())
        await w.start(); XCTAssertEqual(source.fetchCount,0)
        await w.requestAuthorization(); XCTAssertEqual(w.authorization,.authorized); XCTAssertEqual(source.fetchCount,1)
    }
}

