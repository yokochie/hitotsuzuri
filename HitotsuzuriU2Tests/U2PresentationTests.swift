import XCTest
import SwiftUI
@testable import HitotsuzuriCore

final class U2PresentationTests:XCTestCase {
    @MainActor func render(_ w:SelectionWorkflow) {
        let view=NSHostingView(rootView:PickerContent(workflow:w)); view.frame=NSRect(x:0,y:0,width:1000,height:760); view.layoutSubtreeIfNeeded(); XCTAssertNotNil(view.bitmapImageRepForCachingDisplay(in:view.bounds))
    }
    @MainActor func testRestoringStatusAndEditingFreeze() async {
        let latch=U2Latch(),l=U2Library(); l.pause={await latch.wait()}; let w=workflow(l),task=Task {await w.start()}
        for _ in 0..<1000 {if latch.waiting {break}; await Task.yield()}
        XCTAssertTrue(PresentationSnapshot(w).statusText.contains("復元")); XCTAssertFalse(w.canConfirm); render(w)
        latch.open(); await task.value
    }
    @MainActor func testSavedThenUnsavedDraftProjection() async {
        let w=workflow(); await w.start(); XCTAssertTrue(PresentationSnapshot(w).statusText.contains("復元")); render(w)
        w.toggle("4"); XCTAssertTrue(PresentationSnapshot(w).statusText.contains("未保存")); XCTAssertEqual(PresentationSnapshot(w).countText,"3 / 4枚"); render(w)
    }
    @MainActor func testCorruptRecordExplainsExplicitNewConfirm() async {
        let s=U2Store(); await s.configure(selection:.failure(.corruptData)); let w=workflow(U2Library(),U2Images(),s); await w.start()
        XCTAssertTrue(PresentationSnapshot(w).statusText.contains("改めて4枚")); render(w)
    }
    @MainActor func testUnknownVersionExplainsSupportedApp() async {
        let s=U2Store(); await s.configure(selection:.failure(.unsupportedVersion)); let w=workflow(U2Library(),U2Images(),s); await w.start()
        XCTAssertTrue(PresentationSnapshot(w).statusText.contains("対応")); render(w)
    }
    @MainActor func testSettingsFailurePersistsSeparatelyAfterSelectionSave() async {
        let s=U2Store(),w=workflow(U2Library(),U2Images(),s); await w.start(); await s.configure(settingsFailure:.ioFailure); await w.setTargetFolders(["f"]); await w.confirm()
        XCTAssertTrue(PresentationSnapshot(w).statusText.contains("設定")); XCTAssertTrue(PresentationSnapshot(w).statusText.contains("4枚を保存")); render(w)
    }
    @MainActor func testSelectionSaveFailureOffersRetryAndKeepsFour() async {
        let s=U2Store(),w=workflow(U2Library(),U2Images(),s); await w.start(); await s.configure(saveFailure:.ioFailure); await w.confirm()
        XCTAssertTrue(PresentationSnapshot(w).statusText.contains("再試行")); XCTAssertTrue(w.canConfirm); render(w)
    }
    @MainActor func testAuthorizationTakesPriority() async {
        let l=U2Library(); l.access = .notDetermined; let w=workflow(l); await w.start()
        XCTAssertTrue(PresentationSnapshot(w).statusText.contains("許可してください")); render(w)
    }
}
