import XCTest
@testable import HitotsuzuriCore

@MainActor final class ResourceDriver:ImageDriving {
    var callbacks=[Int:@MainActor (ImageOutcome)->Void](),cancelled=[Int]()
    var count=0
    let buffer=ImageBuffer(pixels:Data(repeating:1,count:16),width:2,height:2,bytesPerRow:8)
    func request(_ id:String,completion:@escaping @MainActor (ImageOutcome)->Void)->Int {count += 1; callbacks[count]=completion; return count}
    func cancel(_ id:Int) {cancelled.append(id)}
}
final class U3ResourceTests:XCTestCase {
    @MainActor func testValidationRequestsKeepFourSlotsAndBudget() async {
        let d=ResourceDriver(),a=LocalImageAccess(driver:d)
        let tasks=(0..<9).map {i in Task {try? await a.image(String(i),validation:true)}}
        for _ in 0..<1000 {if d.count==4 {break}; await Task.yield()}
        XCTAssertEqual(a.activeCount,4); XCTAssertLessThanOrEqual(a.retainedBytes+a.reservedBytes,256*1024*1024)
        for task in tasks {task.cancel()}; for task in tasks {_=await task.value}
        XCTAssertEqual(a.activeCount,0)
    }
    @MainActor func testAggregateResourceSnapshotContainsOnlyCounts() {
        let a=LocalImageAccess(driver:ResourceDriver()); XCTAssertEqual(a.resourceSnapshot.active,0); XCTAssertEqual(a.resourceSnapshot.queued,0); XCTAssertEqual(a.resourceSnapshot.retainedBytes,0); XCTAssertEqual(a.resources?.reservedBytes,0)
    }
    @MainActor func testReleaseCancelsQueuedAndActiveUnusedDisplay() async {
        let d=ResourceDriver(),a=LocalImageAccess(driver:d)
        let tasks=(0..<10).map {i in Task {try? await a.image(String(i),validation:false)}}
        for _ in 0..<1000 {if d.count==4 {break}; await Task.yield()}
        a.release(except:[]); XCTAssertEqual(a.activeCount,0); XCTAssertGreaterThanOrEqual(d.cancelled.count,4)
        a.cancelDisplayRequests(); for task in tasks {_=await task.value}
    }
    @MainActor func testReleaseKeepsNeededActiveRequestOnly() async {
        let d=ResourceDriver(),a=LocalImageAccess(driver:d)
        let t1=Task {try? await a.image("keep",validation:false)},t2=Task {try? await a.image("drop",validation:false)}
        for _ in 0..<1000 {if d.count==2 {break}; await Task.yield()}
        a.release(except:["keep"]); XCTAssertEqual(a.activeCount,1)
        a.cancelDisplayRequests(); _=await t1.value; _=await t2.value
    }
    @MainActor func testLateWorkflowImageAfterExitNotAdopted() async {
        let i=U3Images(),latch=U3Latch(),w=workflow(U3Library(),i); await w.start()
        i.pause={await latch.wait()}; let task=Task {await w.loadImage("5")}
        for _ in 0..<1000 {if latch.waiting {break}; await Task.yield()}
        w.updateVisibleImages([]); latch.open(); await task.value
        XCTAssertNil(w.images["5"]); XCTAssertEqual(w.images.count,4)
    }
    @MainActor func testTenRoundTripsKeepOnlyNecessaryImages() async {
        let w=workflow(); await w.start()
        for _ in 0..<10 {await w.loadImage("5"); w.updateVisibleImages(["5"]); w.updateVisibleImages([]); XCTAssertEqual(Set(w.images.keys),Set(w.selection.orderedIDs))}
    }
    @MainActor func testReturnedBufferSurvivesCacheReleaseAndIsAccounted() async throws {
        let d=ResourceDriver(),a=LocalImageAccess(driver:d),task=Task {try await a.image("x",validation:false)}
        for _ in 0..<1000 {if d.count==1 {break}; await Task.yield()}; d.callbacks[1]?(.image(d.buffer,final:true))
        let image=try await task.value; a.release(except:[]); XCTAssertEqual(a.retainedBytes,image.byteCount)
    }
    @MainActor func testReleasingDisplayDoesNotCancelValidation() async {
        let d=ResourceDriver(),a=LocalImageAccess(driver:d),task=Task {try? await a.image("x",validation:true)}
        for _ in 0..<1000 {if d.count==1 {break}; await Task.yield()}
        a.release(except:[]); XCTAssertEqual(a.activeCount,1); d.callbacks[1]?(.image(d.buffer,final:true)); _=await task.value
    }
}
