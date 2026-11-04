import XCTest
@testable import HitotsuzuriCore
final class U3AccessibilityTests:XCTestCase {
    func testUnavailableReasonIsAccessible() {let s=PhotoSemantics(position:2,selectedIndex:nil,available:false,failure:.unavailable); XCTAssertTrue(s.hint.contains("写真アプリ"))}
    func testSelectedOrderIsAccessible() {XCTAssertEqual(PhotoSemantics(position:4,selectedIndex:1,available:true,failure:nil).value,"選択済み、選択順 2")}
    func testLoadingReasonIsAccessible() {XCTAssertTrue(PhotoSemantics(position:2,selectedIndex:nil,available:false,failure:nil).hint.contains("読み込み"))}
    func testSlotLabelsIdentifyOrderAndPhoto() {XCTAssertEqual(PhotoSemantics.slotLabel(slot:1,position:3),"選択枠 2、写真 3"); XCTAssertEqual(PhotoSemantics.slotLabel(slot:0,position:nil),"選択枠 1、未選択")}
    func testArrowNavigationUsesIDAndColumnCount() {XCTAssertEqual(GridNavigation.destination(.down,current:"b",ids:["a","b","c","d"],columns:2),.photo("d")); XCTAssertEqual(GridNavigation.destination(.left,current:"b",ids:["a","b"],columns:2),.photo("a"))}
    func testTabExitsGridInBothDirections() {XCTAssertEqual(GridNavigation.destination(.tab,current:"a",ids:["a"],columns:1),.confirmation); XCTAssertEqual(GridNavigation.destination(.backtab,current:"a",ids:["a"],columns:1),.previousRegion)}
    @MainActor func testFifthPhotoKeepsOrderAndExplainsLimit() async {
        let w=workflow(); await w.start(); await w.loadImage("5"); let before=w.selection.orderedIDs; w.toggle("5")
        XCTAssertEqual(w.selection.orderedIDs,before); XCTAssertTrue(w.notice.contains("4枚まで"))
    }
}
