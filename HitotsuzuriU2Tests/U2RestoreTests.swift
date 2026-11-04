import XCTest
@testable import HitotsuzuriCore

final class U2RestoreTests:XCTestCase {
    @MainActor func testDuplicateStartupSharesOneOperation() async {
        let latch=U2Latch(),l=U2Library(); l.pause={await latch.wait()}; let w=workflow(l)
        let first=Task {await w.start()}
        for _ in 0..<1000 {if latch.waiting {break}; await Task.yield()}
        let second=Task {await w.start()}; await Task.yield()
        XCTAssertEqual(l.hierarchyCount,1); latch.open(); await first.value; await second.value
        XCTAssertEqual(w.selection.orderedIDs.count,4); XCTAssertEqual(l.hierarchyCount,2) // 起動探索1回と現在参照の再検証1回
    }
    @MainActor func testPermissionLostDuringRestoreRejectsLateSuccess() async {
        let i=U2Images(),l=U2Library(),latch=U2Latch(); var paused=false
        i.pause={if !paused {paused=true; await latch.wait()}}
        let w=workflow(l,i),task=Task {await w.start()}
        for _ in 0..<1000 {if latch.waiting {break}; await Task.yield()}
        l.access = .denied; latch.open(); await task.value
        XCTAssertEqual(w.restoreState,.blocked); XCTAssertNil(w.lastCommitted); XCTAssertTrue(w.images.isEmpty); XCTAssertEqual(w.authorization,.denied)
    }
    @MainActor func testSharedRestoreDeadlineExactBoundaryRejectsAll() async {
        let c=U2Clock(),i=U2Images(); i.onImage={if i.calls.count==4 {c.offset = .seconds(15)}}
        let w=SelectionWorkflow(library:PhotoLibraryAccess(source:U2Library()),images:i,store:U2Store(),clock:c)
        await w.start(); XCTAssertEqual(w.error,.timedOut); XCTAssertNil(w.lastCommitted); XCTAssertTrue(w.images.isEmpty)
        XCTAssertEqual(Set(i.deadlines.compactMap{$0}).count,1); XCTAssertEqual(i.deadlines.first!,c.base.advanced(by:.seconds(15)))
    }
    @MainActor func testAllFourRestoreAtomicallyInSavedOrderAndDate() async {
        let w=workflow(); await w.start()
        XCTAssertEqual(w.selection.orderedIDs,["4","2","3","1"]); XCTAssertEqual(w.images.count,4)
        XCTAssertEqual(w.activeAlbum?.id,"a"); XCTAssertEqual(w.lastCommitted?.confirmedAt,Date(timeIntervalSince1970:123)); XCTAssertFalse(w.isDirty)
    }
    @MainActor func testNoAuthorizationNoReadsOrReferenceAccess() async {
        let l=U2Library(),s=U2Store(); l.access = .denied; let w=workflow(l,U2Images(),s); await w.start()
        let reads=await s.reads; XCTAssertEqual(reads,0); XCTAssertEqual(l.hierarchyCount,0); XCTAssertNil(w.lastCommitted)
    }
    @MainActor func testMissingOneClearsAllButKeepsValidFolders() async {
        let l=U2Library(); l.photos=["1","2","3"]; let w=workflow(l); await w.start()
        XCTAssertEqual(w.error,.invalidReference); XCTAssertNil(w.activeAlbum); XCTAssertNil(w.lastCommitted); XCTAssertTrue(w.selection.orderedIDs.isEmpty); XCTAssertEqual(w.targetFolders,["f"])
    }
    @MainActor func testOutsideAlbumClearsAll() async {
        let s=U2Store(); await s.configure(settings:.valid(.init(folderIDs:["other"])))
        let w=workflow(U2Library(),U2Images(),s); await w.start(); XCTAssertNil(w.lastCommitted); XCTAssertEqual(w.error,.invalidReference); XCTAssertEqual(w.targetFolders,["other"])
    }
    @MainActor func testImageFailureClearsAllCandidates() async {
        let i=U2Images(); i.failure = .unavailable; let w=workflow(U2Library(),i); await w.start()
        XCTAssertNil(w.activeAlbum); XCTAssertNil(w.lastCommitted); XCTAssertEqual(w.images.count,0); XCTAssertEqual(w.error,.unavailable)
    }
    @MainActor func testSettingsFailureDoesNotSkipSelectionReadOrRestoreUnknownScope() async {
        let s=U2Store(); await s.configure(settings:.failure(.ioFailure)); let w=workflow(U2Library(),U2Images(),s); await w.start()
        let reads=await s.reads; XCTAssertEqual(reads,2); XCTAssertTrue(w.targetFolders.isEmpty); XCTAssertNil(w.lastCommitted); XCTAssertNil(w.activeAlbum)
    }
    @MainActor func testSelectionFailureKeepsNormalSettings() async {
        let s=U2Store(); await s.configure(selection:.failure(.unsupportedVersion)); let w=workflow(U2Library(),U2Images(),s); await w.start()
        XCTAssertEqual(w.targetFolders,["f"]); XCTAssertEqual(w.error,.unsupportedVersion); XCTAssertNil(w.lastCommitted)
    }
    @MainActor func testRestoreFreezesAndDoesNotPublishPartialImages() async {
        let latch=U2Latch(),i=U2Images(); i.pause={await latch.wait()}; let w=workflow(U2Library(),i)
        // 同時4要求を1つの待機へ重ねない。
        var paused=false; i.pause={if !paused {paused=true; await latch.wait()}}
        let task=Task {await w.start()}; for _ in 0..<1000 {if latch.waiting {break}; await Task.yield()}
        await w.setTargetFolders([]); w.toggle("1")
        XCTAssertEqual(w.targetFolders,["f"]); XCTAssertNil(w.activeAlbum); XCTAssertTrue(w.images.isEmpty); XCTAssertTrue(w.selection.orderedIDs.isEmpty)
        latch.open(); await task.value; XCTAssertEqual(w.selection.orderedIDs.count,4)
    }
}
