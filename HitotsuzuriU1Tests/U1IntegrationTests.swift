import XCTest
import SwiftUI
@testable import HitotsuzuriCore

final class U1IntegrationTests: XCTestCase {
    @MainActor func testFlowWritesActualFile() async throws {
        let dir=URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("HitotsuzuriTests-"+UUID().uuidString)
        let store=SelectionPersistence(directory:dir)
        let w=SelectionWorkflow(library:PhotoLibraryAccess(source:FakeLibrarySource()),images:LocalImageAccess(driver:FakeImageDriver()),store:store)
        await w.start(); await w.setTargetFolders(["parent"]); await w.selectAlbum(.init(id:"a",title:"アルバム"))
        for id in ["4","2","1","3"] { await w.loadImage(id); w.toggle(id) }
        await w.confirm()
        if case .valid(let value)=await store.loadSelection() { XCTAssertEqual(value.orderedAssetIDs,["4","2","1","3"]) } else { XCTFail() }
    }
    @MainActor func testFailureKeepsPreviousCommit() async {
        let store=FakeStore(); let w=await readyWorkflow(store:store)
        for id in ["1","2","3","4"] { w.toggle(id) }; await w.confirm(); let old=w.lastCommitted
        w.toggle("1"); w.toggle("5"); await store.setFailure(); await w.confirm()
        XCTAssertEqual(w.lastCommitted,old); XCTAssertEqual(w.selection.orderedIDs,["2","3","4","5"])
    }
    func testSemanticallyCorruptOriginalIsPreserved() async throws {
        let dir=URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("HitotsuzuriTests-"+UUID().uuidString)
        try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        let encoder=JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let corrupt=CommittedSelection(albumID:"a",albumTitle:"",orderedAssetIDs:["1","1","2","3"])
        let data=try encoder.encode(corrupt); let url=dir.appendingPathComponent("selection.json"); try data.write(to:url)
        do { try await SelectionPersistence(directory:dir).saveSelection(testSelection()); XCTFail("破損原本を上書きした") } catch { XCTAssertEqual(error as? PickerFailure,.corruptData) }
        XCTAssertEqual(try Data(contentsOf:url),data)
    }
    @MainActor func testNativeViewCanRenderFakeLibraryWithoutPermission() async {
        let w=await readyWorkflow()
        let view=NSHostingView(rootView:PickerContent(workflow:w))
        view.frame=NSRect(x:0,y:0,width:1100,height:700)
        view.layoutSubtreeIfNeeded()
        XCTAssertGreaterThan(view.fittingSize.width,0)
    }
    @MainActor func testPermissionExplanationRendersWithoutSystemRequest() {
        let source=FakeLibrarySource(); source.access = .notDetermined
        let w=SelectionWorkflow(library:PhotoLibraryAccess(source:source),images:LocalImageAccess(driver:FakeImageDriver()),store:FakeStore())
        let view=NSHostingView(rootView:PickerContent(workflow:w)); view.frame=NSRect(x:0,y:0,width:1100,height:700); view.layoutSubtreeIfNeeded()
        XCTAssertGreaterThan(view.fittingSize.height,0); XCTAssertEqual(source.fetchCount,0)
    }
    @MainActor func testSelectedImagesAndSavedStatusRender() async {
        let w=await readyWorkflow(); for id in ["1","2","3","4"] { w.toggle(id) }; await w.confirm()
        let view=NSHostingView(rootView:PickerContent(workflow:w)); view.frame=NSRect(x:0,y:0,width:1100,height:700); view.layoutSubtreeIfNeeded()
        XCTAssertEqual(PresentationSnapshot(w).slotIDs.compactMap {$0}.count,4)
    }
}

