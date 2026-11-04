import XCTest
import AppKit
@testable import HitotsuzuriCore

final class U1ImageTests: XCTestCase {
    @MainActor func testCGImageKeepsManagedBufferAccountedAfterCacheAndValueRelease() async throws {
        let driver=FakeImageDriver(); let access=LocalImageAccess(driver:driver,budget:4*1024*1024)
        driver.outcome = .image(.init(pixels:Data(repeating:1,count:1024*1024),width:512,height:512,bytesPerRow:2048),final:true)
        var buffer: ImageBuffer?=try await access.image("rendered")
        let cg=try XCTUnwrap(buffer?.displayImage?.cgImage(forProposedRect:nil,context:nil,hints:nil))
        buffer=nil; driver.outcome = .unavailable; access.release(except:[])
        withExtendedLifetime(cg) { XCTAssertEqual(access.retainedBytes,1024*1024) }
    }
    @MainActor func testSmallBudgetCannotBeBypassedByHoldingEvictedReturnedImages() async throws {
        let driver=FakeImageDriver(); let access=LocalImageAccess(driver:driver,timeout:.milliseconds(5),budget:4*1024*1024)
        var held=[ImageBuffer]()
        for index in 0..<6 {
            driver.outcome = .image(.init(pixels:Data(repeating:UInt8(index),count:1024*1024),width:512,height:512,bytesPerRow:2048),final:true)
            do { held.append(try await access.image("\(index)")) }
            catch { XCTAssertEqual(error as? PickerFailure,.timedOut); break }
        }
        access.release(except:[])
        withExtendedLifetime(held) {
            XCTAssertEqual(access.retainedBytes,held.reduce(0) {$0+$1.byteCount})
            XCTAssertLessThanOrEqual(access.retainedBytes+access.reservedBytes,4*1024*1024)
            XCTAssertEqual(held.count,3)
        }
    }
    @MainActor func testExactlyAtInjectedDeadlineRejectsAndCancelsDriver() async {
        let driver=FakeImageDriver(); driver.automatic=false; let clock=ManualImageClock()
        let access=LocalImageAccess(driver:driver,clock:clock)
        let operation=Task { try await access.image("exact") }; await Task.yield(); await Task.yield()
        clock.offset = .seconds(15); driver.callbacks[1]?(driver.outcome)
        do { _=try await operation.value; XCTFail() } catch { XCTAssertEqual(error as? PickerFailure,.timedOut) }
        XCTAssertEqual(driver.cancelled,[1])
    }
    @MainActor func testBeforeInjectedDeadlineSucceedsDespiteUnfiredTimer() async throws {
        let driver=FakeImageDriver(); driver.automatic=false; let clock=ManualImageClock()
        let access=LocalImageAccess(driver:driver,clock:clock)
        let operation=Task { try await access.image("before") }; await Task.yield(); await Task.yield()
        clock.offset = .seconds(14); driver.callbacks[1]?(driver.outcome)
        let result=try await operation.value; XCTAssertEqual(result.byteCount,16)
    }
    @MainActor func testQueuedRequestUsesReceiptTimeInsteadOfDriverStartTime() async {
        let driver=FakeImageDriver(); driver.automatic=false; let clock=ManualImageClock()
        let access=LocalImageAccess(driver:driver,clock:clock)
        var operations=[Task<ImageBuffer,any Error>]()
        for index in 0..<5 { operations.append(Task { try await access.image("\(index)") }) }
        for _ in 0..<10 { await Task.yield() }; XCTAssertEqual(driver.requestCount,4)
        clock.offset = .seconds(15); driver.callbacks[1]?(driver.outcome); access.cancelDisplayRequests()
        for operation in operations { do { _=try await operation.value; XCTFail() } catch { XCTAssertEqual(error as? PickerFailure,.timedOut) } }
        XCTAssertEqual(driver.requestCount,4)
    }
    @MainActor func testSharedValidationDeadlineIsEarlierThanIndividualTimeout() async {
        let driver=FakeImageDriver(); driver.automatic=false; let clock=ManualImageClock()
        let access=LocalImageAccess(driver:driver,clock:clock), deadline=clock.now().advanced(by:.seconds(1))
        let operation=Task { try await access.image("shared",validation:true,deadline:deadline) }; await Task.yield(); await Task.yield()
        clock.offset = .seconds(1); driver.callbacks[1]?(driver.outcome)
        do { _=try await operation.value; XCTFail() } catch { XCTAssertEqual(error as? PickerFailure,.timedOut) }
    }
    @MainActor func testLiveReturnedBuffersRemainInBudgetAfterCacheReplacement() async throws {
        let driver=FakeImageDriver(); let access=LocalImageAccess(driver:driver,timeout:.milliseconds(10),budget:4*1024*1024)
        driver.outcome = .image(.init(pixels:Data(repeating:1,count:1024*1024),width:512,height:512,bytesPerRow:2048),final:true)
        let first=try await access.image("same")
        driver.outcome = .image(.init(pixels:Data(repeating:2,count:1024*1024),width:512,height:512,bytesPerRow:2048),final:true)
        let second=try await access.image("same",validation:true)
        access.release(except:[])
        withExtendedLifetime((first,second)) { XCTAssertEqual(access.retainedBytes,2*1024*1024) }
    }
    @MainActor func testCallbackPastAbsoluteDeadlineFailsEvenBeforeTimerRuns() async {
        let driver=FakeImageDriver(); driver.automatic=false
        let access=LocalImageAccess(driver:driver,timeout:.milliseconds(1))
        let operation=Task { try await access.image("late") }; await Task.yield(); await Task.yield()
        usleep(60_000)
        driver.callbacks[1]?(driver.outcome)
        do { _=try await operation.value; XCTFail("期限後の画像を受理した") } catch { XCTAssertEqual(error as? PickerFailure,.timedOut) }
    }
    @MainActor func testSystemOptionsNeverRequestNetwork() { XCTAssertFalse(SystemImageDriver.requestOptions().isNetworkAccessAllowed) }
    func testSystemDecoderBoundsActualBuffer() throws {
        let image=NSImage(size:NSSize(width:1024,height:512),flipped:false) { rect in NSColor.red.setFill(); rect.fill(); return true }
        let decoded=try XCTUnwrap(SystemImageDriver.decode(image))
        XCTAssertEqual(decoded.width,512); XCTAssertEqual(decoded.height,256)
        XCTAssertEqual(decoded.byteCount,decoded.bytesPerRow*decoded.height)
        XCTAssertLessThanOrEqual(decoded.byteCount,2*1024*1024)
    }
    @MainActor func testFinalImage() async throws { let d=FakeImageDriver(); let image=try await LocalImageAccess(driver:d).image("1"); XCTAssertEqual(image.width,2) }
    @MainActor func testUnavailable() async { let d=FakeImageDriver(); d.outcome = .unavailable; do { _=try await LocalImageAccess(driver:d).image("1"); XCTFail() } catch { XCTAssertEqual(error as? PickerFailure,.unavailable) } }
    @MainActor func testFailure() async { let d=FakeImageDriver(); d.outcome = .failure(.ioFailure); do { _=try await LocalImageAccess(driver:d).image("1"); XCTFail() } catch { XCTAssertEqual(error as? PickerFailure,.ioFailure) } }
    @MainActor func testTimeout() async { let d=FakeImageDriver(); d.automatic=false; do { _=try await LocalImageAccess(driver:d,timeout:.milliseconds(1)).image("1"); XCTFail() } catch { XCTAssertEqual(error as? PickerFailure,.timedOut) } }
    @MainActor func testCacheRelease() async throws { let d=FakeImageDriver(); let i=LocalImageAccess(driver:d); _=try await i.image("1"); XCTAssertEqual(i.retainedBytes,16); d.outcome = .unavailable; i.release(except:[]); XCTAssertEqual(i.retainedBytes,0) }
    @MainActor func testValidationBypassesCache() async throws { let d=FakeImageDriver(); let i=LocalImageAccess(driver:d); _=try await i.image("1"); _=try await i.image("1",validation:true); XCTAssertEqual(d.requestCount,2) }
    @MainActor func testCancellationReleasesSlotAndReservation() async {
        let d=FakeImageDriver(); d.automatic=false; let i=LocalImageAccess(driver:d)
        let operation=Task { try await i.image("1") }; await Task.yield(); await Task.yield()
        XCTAssertEqual(i.activeCount,1); XCTAssertEqual(i.reservedBytes,2*1024*1024)
        i.cancelDisplayRequests()
        do { _=try await operation.value; XCTFail() } catch { XCTAssertEqual(error as? PickerFailure,.cancelled) }
        XCTAssertEqual(i.activeCount,0); XCTAssertFalse(d.cancelled.isEmpty)
    }
    @MainActor func testPreviewDoesNotCompleteThenFinalWins() async throws {
        let d=FakeImageDriver(); d.automatic=false; let i=LocalImageAccess(driver:d)
        let operation=Task { try await i.image("1") }; await Task.yield(); await Task.yield()
        let b=ImageBuffer(pixels:Data(repeating:0,count:16),width:2,height:2,bytesPerRow:8)
        d.callbacks[1]?(.image(b,final:false)); XCTAssertEqual(i.activeCount,1)
        d.callbacks[1]?(.image(b,final:true)); let result=try await operation.value; XCTAssertEqual(result,b)
        d.callbacks[1]?(.unavailable); XCTAssertEqual(i.retainedBytes,16)
    }
}

