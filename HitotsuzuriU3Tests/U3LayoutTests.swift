import XCTest
import SwiftUI
@testable import HitotsuzuriCore
final class U3LayoutTests:XCTestCase {
    @MainActor func testBoundaryIsInclusive() {XCTAssertTrue(PickerPresentationState.isCompact(820)); XCTAssertFalse(PickerPresentationState.isCompact(821))}
    @MainActor func testCollapsedHierarchyHidesChildren() {let p=PickerPresentationState(); XCTAssertEqual(p.rows(folders).map(\.id),["p"])}
    @MainActor func testExpandedHierarchyHasDepth() {let p=PickerPresentationState(); p.toggleExpanded("p"); XCTAssertEqual(p.rows(folders).map(\.depth),[0,1])}
    @MainActor func testCyclesTerminate() {let p=PickerPresentationState(); p.expanded=["a","b"]; XCTAssertEqual(p.rows([.init(id:"a",title:"",children:["b"]),.init(id:"b",title:"",children:["a"])]).count,2)}
    @MainActor func testLongTitleIsNotChangedByLayout() {let p=PickerPresentationState(); let name=String(repeating:"長い名称",count:60); XCTAssertEqual(p.rows([.init(id:"x",title:name)]).first?.folder.title,name)}
    var folders:[LibraryFolder] {[.init(id:"p",title:"親",children:["c"]),.init(id:"c",title:"子")]}
    @MainActor func testMinimumWidthDoesNotOverflow() {
        let v=NSHostingView(rootView:PickerContent(workflow:workflow())); v.frame=NSRect(x:0,y:0,width:640,height:560); v.layoutSubtreeIfNeeded()
        XCTAssertLessThanOrEqual(v.fittingSize.width,640)
    }
}
