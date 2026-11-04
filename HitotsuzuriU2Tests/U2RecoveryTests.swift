import XCTest
@testable import HitotsuzuriCore

final class U2RecoveryTests:XCTestCase {
    @MainActor func testLateAlbumResponseCannotRepopulateExcludedAlbum() async {
        let s=U2Store(),l=U2Library(),latch=U2Latch(); await s.configure(selection:.missing)
        let w=workflow(l,U2Images(),s); await w.start(); l.pauseAssets={_ in await latch.wait()}
        let task=Task {await w.selectAlbum(.init(id:"a",title:"現在"))}
        for _ in 0..<1000 {if latch.waiting {break}; await Task.yield()}
        await w.setTargetFolders([]); latch.open(); await task.value
        XCTAssertNil(w.activeAlbum); XCTAssertTrue(w.assets.isEmpty); XCTAssertTrue(w.selection.orderedIDs.isEmpty)
    }
    @MainActor func testRetryRevalidatesImages() async {
        let s=U2Store(),i=U2Images(),w=workflow(U2Library(),i,s); await w.start(); let old=w.lastCommitted
        await s.configure(saveFailure:.ioFailure); await w.confirm(); await s.configure(); i.failure = .unavailable; await w.confirm()
        XCTAssertEqual(w.lastCommitted,old); XCTAssertEqual(w.error,.unavailable); let writes=await s.writes; XCTAssertEqual(writes,1)
    }
    @MainActor func testRetryRevalidatesAuthorizationAndKeepsOldCommit() async {
        let l=U2Library(),s=U2Store(),w=workflow(l,U2Images(),s); await w.start(); let old=w.lastCommitted
        w.toggle("4"); await w.loadImage("5"); w.toggle("5"); l.access = .denied; await w.confirm()
        XCTAssertEqual(w.error,.authorization); XCTAssertEqual(w.lastCommitted,old); XCTAssertEqual(w.selection.orderedIDs,["2","3","1","5"])
    }
    @MainActor func testFailedSaveThenExplicitRetry() async {
        let s=U2Store(),i=U2Images(),w=workflow(U2Library(),i,s); await w.start(); let old=w.lastCommitted
        await s.configure(saveFailure:.ioFailure); await w.confirm(); XCTAssertEqual(w.lastCommitted,old); XCTAssertEqual(w.error,.ioFailure)
        let count=i.calls.count; await s.configure(); await w.confirm(); XCTAssertEqual(i.calls.count,count+4); XCTAssertNil(w.error); XCTAssertFalse(w.isDirty)
    }
    @MainActor func testRetryRevalidatesMembership() async {
        let l=U2Library(),s=U2Store(),w=workflow(l,U2Images(),s); await w.start()
        await s.configure(saveFailure:.ioFailure); await w.confirm(); l.photos=["1","2","3"]; await s.configure(); await w.confirm()
        XCTAssertEqual(w.error,.invalidReference); let writes=await s.writes; XCTAssertEqual(writes,1)
    }
    @MainActor func testSettingsFailureIndependentOfSuccessfulConfirm() async {
        let s=U2Store(),w=workflow(U2Library(),U2Images(),s); await w.start(); await s.configure(settingsFailure:.ioFailure)
        await w.setTargetFolders(["f"]); await w.confirm(); XCTAssertFalse(w.isDirty)
    }
    @MainActor func testUncommittedEditNeverWritten() async {
        let s=U2Store(),w=workflow(U2Library(),U2Images(),s); await w.start(); w.toggle("4")
        let writes=await s.writes; XCTAssertEqual(writes,0); XCTAssertEqual(w.lastCommitted?.orderedAssetIDs,["4","2","3","1"])
    }
    @MainActor func testDuplicateConfirmAndEditingDuringWriteAreRejected() async {
        let latch=U2Latch(),s=U2Store(),w=workflow(U2Library(),U2Images(),s); await w.start()
        await s.setPause {await latch.wait()}; let task=Task {await w.confirm()}
        for _ in 0..<1000 {if latch.waiting {break}; await Task.yield()}
        await w.confirm(); w.toggle("1"); await w.setTargetFolders([])
        XCTAssertEqual(w.selection.orderedIDs,["4","2","3","1"]); XCTAssertEqual(w.targetFolders,["f"])
        latch.open(); await task.value; let writes=await s.writes; XCTAssertEqual(writes,1)
    }
}
