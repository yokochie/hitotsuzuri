import XCTest
import SwiftUI
import AppKit
@testable import HitotsuzuriCore
final class U3FocusTests:XCTestCase {
    @MainActor private func nativeFolder(_ folders:[LibraryFolder],selection:Set<String>=[],frozen:Bool=false,onSelection:@escaping(Set<String>)->Void)throws->(NSWindow,NSOutlineView) {
        _=NSApplication.shared
        let browser=NativeFolderBrowser(folders:folders,selection:selection,expanded:.constant([]),frozen:frozen,focusRequest:0,focusID:nil,onSelection:onSelection,onFocus:{_ in})
        let host=NSHostingView(rootView:browser)
        let window=NSWindow(contentRect:NSRect(x:0,y:0,width:400,height:300),styleMask:[.titled],backing:.buffered,defer:false)
        window.isReleasedWhenClosed=false; window.contentView=host; host.layoutSubtreeIfNeeded()
        func find(_ view:NSView)->NSOutlineView? {
            if let outline=view as? NSOutlineView {return outline}
            return view.subviews.lazy.compactMap {find($0)}.first
        }
        return (window,try XCTUnwrap(find(host)))
    }
    @MainActor private func tab(_ window:NSWindow)throws->NSEvent {
        try XCTUnwrap(NSEvent.keyEvent(with:.keyDown,location:.zero,modifierFlags:[],timestamp:ProcessInfo.processInfo.systemUptime,windowNumber:window.windowNumber,context:nil,characters:"\t",charactersIgnoringModifiers:"\t",isARepeat:false,keyCode:48))
    }
    @MainActor func testNativeTabDoesNothingInEmptyOrFrozenFolderList()throws {
        for frozen in [false,true] {
            var events=[Set<String>]()
            let folders:[LibraryFolder]=frozen ? [.init(id:"a",title:"A")] : []
            let (window,outline)=try nativeFolder(folders,frozen:frozen,onSelection:{events.append($0)})
            outline.keyDown(with:try tab(window))
            XCTAssertTrue(events.isEmpty); XCTAssertTrue(outline.selectedRowIndexes.isEmpty)
            window.close()
        }
    }
    @MainActor func testNativeInitialAndMouseFocusDoNotSelectBeforeTab()throws {
        var events=[Set<String>]()
        let (window,outline)=try nativeFolder([.init(id:"a",title:"A")],onSelection:{events.append($0)})
        XCTAssertTrue(events.isEmpty); _=window.makeFirstResponder(outline)
        XCTAssertTrue(events.isEmpty)
        outline.keyDown(with:try tab(window))
        XCTAssertEqual(events,[Set(["a"])]); XCTAssertEqual(outline.selectedRow,0)
        window.close()
    }
    @MainActor func testNativeTabPreservesExistingMultipleSelection()throws {
        var events=[Set<String>]()
        let (window,outline)=try nativeFolder([.init(id:"a",title:"A"),.init(id:"b",title:"B")],selection:["a","b"],onSelection:{events.append($0)})
        outline.keyDown(with:try tab(window))
        XCTAssertTrue(events.isEmpty); XCTAssertEqual(outline.selectedRowIndexes,IndexSet([0,1]))
        window.close()
    }
    @MainActor func testRegionRestoresSameID() {let p=PickerPresentationState(); p.remember("b",in:.albums); XCTAssertEqual(p.restore(in:.albums,available:["a","b"]),"b")}
    @MainActor func testDisappearedFocusFallsBack() {let p=PickerPresentationState(); p.remember("gone",in:.albums); XCTAssertEqual(p.restore(in:.albums,available:["a"]),"a")}
    @MainActor func testEmptyRegionUsesHeading() {XCTAssertNil(PickerPresentationState().restore(in:.photos,available:[]))}
    @MainActor func testRegionFocusIndependent() {let p=PickerPresentationState(); p.remember("x",in:.folders); p.remember("y",in:.photos); XCTAssertEqual(p.restore(in:.folders,available:["z","x"]),"x")}
    @MainActor func testAsynchronousDataDoesNotStealFocus() {let p=PickerPresentationState(); p.remember("b",in:.photos); _=p.rows([.init(id:"f",title:"x")]); XCTAssertEqual(p.focus[.photos],"b")}
    @MainActor func testExpansionDoesNotAlterFocusOrRegion() {let p=PickerPresentationState(); p.remember("x",in:.folders); p.toggleExpanded("x"); XCTAssertEqual(p.focus[.folders],"x"); XCTAssertEqual(p.region,.photos)}
}
