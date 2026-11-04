import XCTest
@testable import HitotsuzuriCore

@MainActor final class ArticlePreviewRetryTests: XCTestCase {
    func testRealDisplayQueueTerminatesAllAcceptedPhotosAtFifteenSeconds() async throws {
        let driver=DraftDisplayDriver(), clock=DraftDeadlineClock(); driver.held=true
        let images=LocalImageAccess(driver:driver,clock:clock)
        let previews=ArticlePhotoPreviews(assetIDs:["a","b","c","d"],images:images,clock:clock)
        let loading=Task {await previews.load()}
        guard await draftWaitUntil({driver.requests == 1 && clock.pending == 1}) else {
            previews.cancel(); await loading.value; return XCTFail("実表示キューの要求と期限を登録する")
        }
        clock.advance(15)
        let finished=await draftWaitUntil({!previews.isLoading})
        if !finished {previews.cancel()}
        await loading.value; XCTAssertTrue(finished)
        for id in ["a","b","c","d"] {if case .failed(.timedOut)=previews.states[id] {} else {XCTFail("全番号を受付期限で終端")}}
        XCTAssertEqual(driver.requests,1,"期限を過ぎた待機番号はOS要求しない")
        XCTAssertEqual(images.resources?.active,0); XCTAssertEqual(images.resources?.queued,0)
        driver.callbacks[1]?(.image(ImageBuffer(pixels:Data(repeating:0,count:16),width:2,height:2,bytesPerRow:8),final:true))
        if case .failed(.timedOut)=previews.states["a"] {} else {XCTFail("取消後の遅いOS応答を採用しない")}
    }
    func testDisplayMemoryAndCancellationThirtyTrials() async throws {
        let sampler=DraftMemorySampler()
        defer {sampler.stop()}
        let baseline=try await sampler.prepareMeasurement()
        let median=baseline.median, before=try DraftMemorySample.read()
        let driver=DraftDisplayDriver(), images=LocalImageAccess(driver:driver)
        var loads:[Double]=[], accepts:[Double]=[], terminals:[Double]=[], directPeak=0
        for _ in 0..<30 {
            let previews=ArticlePhotoPreviews(assetIDs:["a","b","c","d"],images:images)
            let start=ContinuousClock().now; await previews.load()
            loads.append(draftSeconds(start.duration(to:ContinuousClock().now)))
            let resource=try XCTUnwrap(images.resources)
            directPeak=max(directPeak,resource.retainedBytes+resource.reservedBytes)
            XCTAssertEqual(resource.retainedBytes,4*512*512*4)
            XCTAssertLessThanOrEqual(directPeak,256*1024*1024)
            // 表示済み画像の所有を保ったまま独立samplerが観測できる期間を取る。
            // この保持期間は上の表示完了時間には含めず、応答性能の合格には使わない。
            try await Task.sleep(for:.milliseconds(50))
            let cancel=ContinuousClock().now; previews.cancel()
            accepts.append(draftSeconds(cancel.duration(to:ContinuousClock().now)))
            XCTAssertFalse(previews.isLoading); XCTAssertTrue(previews.states.isEmpty)
            XCTAssertEqual(images.resources?.retainedBytes,0); XCTAssertEqual(images.resources?.active,0)
            terminals.append(draftSeconds(cancel.duration(to:ContinuousClock().now)))
            await Task.yield()
        }
        var pendingAccepts:[Double]=[], pendingTerminals:[Double]=[]
        driver.held=true
        for _ in 0..<30 {
            let next=driver.requests+1, previews=ArticlePhotoPreviews(assetIDs:["a","b","c","d"],images:images)
            let loading=Task {await previews.load()}
            guard await draftWaitUntil({driver.requests >= next}) else {
                previews.cancel(); await loading.value; return XCTFail("取消対象の表示要求を開始する")
            }
            let start=ContinuousClock().now; previews.cancel()
            pendingAccepts.append(draftSeconds(start.duration(to:ContinuousClock().now)))
            await loading.value
            pendingTerminals.append(draftSeconds(start.duration(to:ContinuousClock().now)))
            XCTAssertTrue(previews.states.isEmpty); XCTAssertFalse(previews.isLoading)
            XCTAssertEqual(images.resources?.active,0); XCTAssertEqual(images.resources?.queued,0)
            driver.callbacks.removeAll()
        }
        let report=try sampler.finish(), after=try DraftMemorySample.read()
        let peak=report.peak, interval=report.longestInterval, sampleCount=report.count
        let delta=peak > median ? peak-median : 0
        print("Draft display memory trials=30 baselineSeconds=5 baselineMedian=\(median) samplePeak=\(peak) delta=\(delta) OSpeakBefore=\(before.lifetimePeak) OSpeakAfter=\(after.lifetimePeak) samplerCount=\(sampleCount) longestInterval=\(interval) directPeak=\(directPeak)")
        print("Draft sampler dedicatedThread=true periodSeconds=0.01 baselineActualSeconds=\(baseline.seconds) baselineCount=\(baseline.count) baselineLongestInterval=\(baseline.longestInterval)")
        print("Draft display trials=30 loadMax=\(loads.max() ?? 0) cancelAcceptMax=\(accepts.max() ?? 0) logicalEndMax=\(terminals.max() ?? 0) seconds; synthetic512pxDriver; real Photos timing separate")
        print("Draft pending-display cancellation n=30 acceptMax=\(pendingAccepts.max() ?? 0) logicalEndMax=\(pendingTerminals.max() ?? 0) seconds")
        XCTAssertLessThanOrEqual(delta,512*1024*1024); XCTAssertLessThanOrEqual(interval,0.05)
        XCTAssertGreaterThanOrEqual(baseline.seconds,5); XCTAssertLessThanOrEqual(baseline.longestInterval,0.05)
        XCTAssertGreaterThanOrEqual(sampleCount,30)
        XCTAssertLessThanOrEqual(pendingAccepts.max() ?? .infinity,0.5); XCTAssertLessThanOrEqual(pendingTerminals.max() ?? .infinity,2)
        if after.lifetimePeak > before.lifetimePeak {XCTAssertLessThanOrEqual(after.lifetimePeak > median ? after.lifetimePeak-median : 0,512*1024*1024)}
        XCTAssertLessThanOrEqual(loads.max() ?? .infinity,15)
        XCTAssertLessThanOrEqual(accepts.max() ?? .infinity,0.5); XCTAssertLessThanOrEqual(terminals.max() ?? .infinity,2)
        if before.lifetimePeak >= after.lifetimePeak {print("Draft OS peak predates this display measurement; isolated-process peak attribution remains unverified")}
    }
    func testFourAcceptedPhotosIncludeQueueTimeInOneDeadline() async {
        let images=DraftImages(), clock=DraftClock(), accepted=clock.now()
        images.onRequest={clock.advance(4)}
        let previews=ArticlePhotoPreviews(assetIDs:["a","b","c","d"],images:images,clock:clock)
        await previews.load()
        XCTAssertEqual(images.calls.count,4)
        XCTAssertTrue(images.calls.allSatisfy {$0.2 == accepted + .seconds(15)},"四番号の受付時から待機を含む15秒")
        if case .failed(.timedOut) = previews.states["d"] {} else {XCTFail("受付期限と同時/後の結果は不採用")}
        XCTAssertFalse(previews.isLoading)
    }
    func testUnavailablePhotoDoesNotBlockOtherNumbers() async {
        let images=DraftImages(); images.failures["b"] = .authorization
        let previews=ArticlePhotoPreviews(assetIDs:["a","b","c","d"],images:images)
        await previews.load()
        if case .failed(.permissionDenied) = previews.states["b"] {} else { XCTFail("番号2の許可分類") }
        if case .ready = previews.states["d"] {} else { XCTFail("番号4は取得") }
    }
    func testRetryRequestsOnlySelectedPhotoWithDisplayPurpose() async {
        let images=DraftImages(); images.failures["b"] = .invalidReference
        let previews=ArticlePhotoPreviews(assetIDs:["a","b","c","d"],images:images)
        await previews.load(); images.failures["b"]=nil
        await previews.retry("b")
        XCTAssertEqual(images.calls.map(\.0),["a","b","c","d","b"])
        XCTAssertTrue(images.calls.allSatisfy { !$0.1 })
        if case .ready = previews.states["b"] {} else { XCTFail("番号2を再取得") }
    }
    func testUnknownPhotoCannotStartRequest() async {
        let images=DraftImages()
        let previews=ArticlePhotoPreviews(assetIDs:["a","b","c","d"],images:images)
        await previews.retry("unknown"); XCTAssertTrue(images.calls.isEmpty)
        XCTAssertNil(previews.states["unknown"])
    }
    func testRepeatedRetryIsSerializedPerPhoto() async {
        let images=DraftImages()
        let actual=ArticlePhotoPreviews(assetIDs:["a"],images:images); images.paused="a"
        let task=Task { await actual.retry("a") }
        guard await draftWaitUntil({ images.continuation != nil }) else { await task.value; return XCTFail("画像境界を呼ぶ") }
        await actual.retry("a"); XCTAssertEqual(images.calls.count,1)
        images.releasePending(); await task.value
    }
    func testCancelReleasesImagesAndPropagatesCancellation() async {
        let images=DraftImages()
        let actual=ArticlePhotoPreviews(assetIDs:["a"],images:images)
        await actual.load(); actual.cancel()
        XCTAssertEqual(images.cancelled,1); XCTAssertEqual(images.released.last,[]); XCTAssertTrue(actual.states.isEmpty)
    }
    func testLateResultAfterLeavingIsNotAdopted() async {
        let images=DraftImages()
        let actual=ArticlePhotoPreviews(assetIDs:["a"],images:images); images.paused="a"
        let task=Task { await actual.load() }
        guard await draftWaitUntil({ images.continuation != nil }) else { await task.value; return XCTFail("画像境界を呼ぶ") }
        actual.cancel(); images.releasePending(); await task.value
        XCTAssertTrue(actual.states.isEmpty); XCTAssertFalse(actual.isLoading)
    }
    func testDisplayRequestsHaveFixedFifteenSecondDeadline() async {
        let images=DraftImages(); let before=ContinuousClock().now
        let previews=ArticlePhotoPreviews(assetIDs:["a"],images:images)
        await previews.load()
        let deadline=images.calls.first?.2
        XCTAssertNotNil(deadline)
        if let deadline { XCTAssertLessThanOrEqual(before.duration(to:deadline),.seconds(16)) }
    }
    func testTimedOutPhotoCanBeExplicitlyRetried() async {
        let images=DraftImages(); images.failures["a"] = .timedOut
        let previews=ArticlePhotoPreviews(assetIDs:["a"],images:images)
        await previews.load()
        if case .failed(.timedOut) = previews.states["a"] {} else { XCTFail("期限を分類") }
        images.failures["a"]=nil; await previews.retry("a")
        if case .ready = previews.states["a"] {} else { XCTFail("新しい要求で再試行") }
    }
}
