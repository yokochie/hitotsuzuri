import XCTest
import SwiftUI
@testable import HitotsuzuriCore

final class U3IntegrationTests:XCTestCase {
    @MainActor func testActualUIChangesMarkerAndFrameEvidenceCanQualifyThirtyOperations() async {
        let w=workflow(),m=NativeMeasurement(enabled:true); await w.start()
        let view=PickerContent(workflow:w,measurement:m); var frames=FrameMeasurement()
        for sequence in 1...30 {
            view.toggleFromUI("1",eventSeconds:ProcessInfo.processInfo.systemUptime)
            guard let stamp=m.stamp,let decoded=MeasurementStamp.parse(stamp.marker) else {XCTFail(); return}
            XCTAssertEqual(decoded.sequence,UInt64(sequence))
            let visible=w.selection.orderedIDs.compactMap {id in w.assets.firstIndex(where:{$0.id==id}).map {$0+1}}
            frames.input(sequence:decoded.sequence,ticks:decoded.inputTicks,beforePositions:decoded.beforePositions,positions:decoded.positions)
            frames.frame(sequence:decoded.sequence,ticks:decoded.inputTicks+1,interval:1,selectionMatches:decoded.positions==visible && visible.count==w.selection.orderedIDs.count,calibrated:true)
        }
        XCTAssertEqual(frames.upperMilliseconds.count,30); XCTAssertTrue(frames.passed)
    }
    @MainActor func testFirstDeselectionAndReturnToOriginalSelectionBothCount() async {
        let w=workflow(),m=NativeMeasurement(enabled:true); await w.start(); let original=w.selection.orderedIDs
        let view=PickerContent(workflow:w,measurement:m)
        view.toggleFromUI("1",eventSeconds:ProcessInfo.processInfo.systemUptime)
        XCTAssertEqual(m.stamp?.sequence,1); XCTAssertEqual(m.stamp?.beforePositions,[4,2,3,1])
        view.toggleFromUI("1",eventSeconds:ProcessInfo.processInfo.systemUptime)
        XCTAssertEqual(m.stamp?.sequence,2); XCTAssertEqual(w.selection.orderedIDs,original)
    }
    @MainActor func testMeasurementFailureDoesNotBecomeSelectionFailure() async {
        let w=workflow(),m=NativeMeasurement(enabled:true); await w.start(); let view=PickerContent(workflow:w,measurement:m)
        view.toggleFromUI("1",eventSeconds:1)
        XCTAssertTrue(m.unavailable); XCTAssertEqual(w.selection.orderedIDs,["4","2","3"]); XCTAssertNil(w.error)
    }
    @MainActor func testMeasurementUIRejectsFifthUnavailableAndInvalidIDWithoutSequenceHoles() async {
        let w=workflow(),m=NativeMeasurement(enabled:true); await w.start()
        let view=PickerContent(workflow:w,measurement:m)
        view.toggleFromUI("5",eventSeconds:ProcessInfo.processInfo.systemUptime) // 4枚で拒否
        XCTAssertNil(m.stamp)
        view.toggleFromUI("missing",eventSeconds:ProcessInfo.processInfo.systemUptime)
        XCTAssertNil(m.stamp)
        view.toggleFromUI("4",eventSeconds:ProcessInfo.processInfo.systemUptime) // 初回が解除
        XCTAssertEqual(m.stamp?.sequence,1)
        view.toggleFromUI("5",eventSeconds:ProcessInfo.processInfo.systemUptime) // 未取得
        XCTAssertEqual(m.stamp?.sequence,1)
        view.toggleFromUI("4",eventSeconds:ProcessInfo.processInfo.systemUptime) // 元の状態へ戻る
        XCTAssertEqual(m.stamp?.sequence,2); XCTAssertEqual(w.selection.orderedIDs,["2","3","1","4"])
    }
    @MainActor func testMeasurementUIRejectsFrozenOperation() async {
        let s=U3Store(),latch=U3Latch(),w=workflow(U3Library(),U3Images(),s); await w.start()
        await s.setPause {await latch.wait()}; let task=Task {await w.confirm()}
        for _ in 0..<1000 {if latch.waiting {break}; await Task.yield()}
        let m=NativeMeasurement(enabled:true),view=PickerContent(workflow:w,measurement:m),before=w.selection.orderedIDs
        view.toggleFromUI("4",eventSeconds:ProcessInfo.processInfo.systemUptime)
        XCTAssertNil(m.stamp); XCTAssertEqual(w.selection.orderedIDs,before)
        latch.open(); await task.value
    }
    @MainActor func render(_ w:SelectionWorkflow,_ p:PickerPresentationState,_ width:Double,_ height:Double,measure:Bool=false) {
        let v=NSHostingView(rootView:PickerContent(workflow:w,presentation:p,measurement:NativeMeasurement(enabled:measure)))
        v.frame=NSRect(x:0,y:0,width:width,height:height); v.layoutSubtreeIfNeeded()
        XCTAssertLessThanOrEqual(v.fittingSize.width,width); XCTAssertLessThanOrEqual(v.fittingSize.height,height)
    }
    @MainActor func testCompactRegionReturnAndSelectionSaveAreCoherent() async {
        let w=workflow(),p=PickerPresentationState(); await w.start(); p.remember("2",in:.photos); p.region = .folders; render(w,p,640,560)
        p.region = .photos; XCTAssertEqual(p.restore(in:.photos,available:w.assets.map(\.id)),"2")
        w.toggle("4"); await w.loadImage("5"); w.toggle("5"); await w.confirm()
        XCTAssertEqual(w.lastCommitted?.orderedAssetIDs,["2","3","1","5"]); render(w,p,640,560)
    }
    @MainActor func testAllWidthsRenderSameOrderedPreview() async {
        let w=workflow(); await w.start()
        for width in [640.0,820,821,1280] {render(w,PickerPresentationState(),width,width==1280 ? 800 : 560); XCTAssertEqual(PresentationSnapshot(w).slotIDs,["4","2","3","1"])}
    }
    @MainActor func testFailureRetryRendersInCompactMode() async {
        let s=U3Store(),w=workflow(U3Library(),U3Images(),s); await w.start(); await s.configure(saveFailure:.ioFailure); await w.confirm()
        XCTAssertEqual(PresentationSnapshot(w).confirmTitle,"保存を再試行"); render(w,PickerPresentationState(),640,560)
        await s.configure(); await w.confirm(); XCTAssertEqual(w.selectionSaveState,.saved); render(w,PickerPresentationState(),1280,800)
    }
    @MainActor func testLongHierarchyAndAllRegionsRender() async {
        let l=U3Library(); l.value = .init(folders:[.init(id:"f",title:String(repeating:"長い名称",count:40),children:["c"],albums:["a"]),.init(id:"c",title:"同名")],albums:[.init(id:"a",title:String(repeating:"同名",count:50))])
        let w=workflow(l),p=PickerPresentationState(); await w.start(); p.expanded=["f"]
        for region in PickerRegion.allCases {p.region=region; render(w,p,640,560)}
        XCTAssertEqual(w.selection.orderedIDs.count,4)
    }
    @MainActor func testUnavailablePhotoAndEmptySlotRender() async {
        let s=U3Store(),i=U3Images(); await s.configure(selection:.missing); let w=workflow(U3Library(),i,s); await draft(w); w.toggle("1"); w.updateVisibleImages([])
        i.failure = .unavailable; await w.loadImage("5"); render(w,PickerPresentationState(),640,560)
        XCTAssertEqual(w.imageFailures["5"],.unavailable)
    }
    @MainActor func testOptionalMarkerRendersWithoutCapturingFrames() async {
        let w=workflow(); await w.start(); render(w,PickerPresentationState(),640,560,measure:true)
        XCTAssertFalse(w.isDirty)
    }
}
