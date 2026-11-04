import XCTest
@testable import HitotsuzuriCore

final class U1PresentationTests: XCTestCase {
    @MainActor func testInitialAuthorizationText() { let s=FakeLibrarySource(); s.access = .notDetermined; let w=SelectionWorkflow(library:PhotoLibraryAccess(source:s),images:LocalImageAccess(driver:FakeImageDriver()),store:FakeStore()); XCTAssertTrue(PresentationSnapshot(w).statusText.contains("許可")) }
    @MainActor func testEmptyFourSlots() async { let w=await readyWorkflow(); XCTAssertEqual(PresentationSnapshot(w).slotIDs.count,4); XCTAssertEqual(PresentationSnapshot(w).countText,"0 / 4枚") }
    @MainActor func testOrderedSlots() async { let w=await readyWorkflow(); w.toggle("3"); w.toggle("1"); XCTAssertEqual(PresentationSnapshot(w).slotIDs,["3","1",nil,nil]) }
    @MainActor func testConfirmProjection() async { let w=await readyWorkflow(); for id in ["1","2","3","4"] { w.toggle(id) }; XCTAssertTrue(PresentationSnapshot(w).canConfirm) }
    @MainActor func testSavedNotice() async { let w=await readyWorkflow(); for id in ["1","2","3","4"] { w.toggle(id) }; await w.confirm(); XCTAssertTrue(PresentationSnapshot(w).statusText.contains("保存")) }
    @MainActor func testFailureNotice() async { let store=FakeStore(); let w=await readyWorkflow(store:store); for id in ["1","2","3","4"] { w.toggle(id) }; await store.setFailure(); await w.confirm(); XCTAssertTrue(PresentationSnapshot(w).statusText.contains("保存できません")) }
}

