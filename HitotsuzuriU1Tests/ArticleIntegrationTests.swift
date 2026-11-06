import XCTest
import Darwin
@testable import HitotsuzuriCore

final class ArticleIntegrationTests: XCTestCase {
    func testPrivateTextNeverAppearsInCapturedDiagnostics() async throws {
        let capture=ArticleDiagnosticCapture(), diagnostics=ArticleDiagnostics(sink:{capture.append($0)})
        let store=ArticlePersistence(directory:ArticleFixtures.root(),diagnostics:diagnostics)
        let source=try ArticleSource(selection:CommittedSelection(albumID:"SECRET-ALBUM",albumTitle:"SECRET-ALBUM-TITLE",orderedAssetIDs:(1...4).map {"SECRET-PHOTO-\($0)"})); var content=ArticleContent(source:source)
        content.title="SECRET-ARTICLE-TITLE"; content.people="SECRET-PERSON"; content.location="SECRET-LOCATION"
        let article=try await store.create(projectID:UUID(),operationID:UUID(),source:source,content:content)
        let image=try ArticleImageConverter.convert(ArticleImageFixture.make(width:30,height:20))
        _ = try await ArticleProbeDelivery(diagnostics:diagnostics).write(article:article,image:image,destination:ArticleFixtures.root(),jobID:UUID())
        let log=capture.lines.joined(separator:"\n")
        XCTAssertTrue(log.contains("saveSucceeded")); XCTAssertTrue(log.contains("probeSucceeded"))
        for secret in [content.title,content.people,content.location,source.orderedAssetIDs[0],source.albumID,article.projectID.uuidString] {
            XCTAssertFalse(log.contains(secret))
        }
    }
    func testCreateEditRestartKeepsAllText() async throws {
        let root = ArticleFixtures.root(), store = ArticlePersistence(directory:root), initial = try await ArticleFixtures.create(store)
        var content = initial.content; content.title = "日本語\n🙂"; content.introduction = "導入"; content.closing = "締め"
        for index in 0..<4 { content.photoTexts[index].text = "本文\(index)" }
        _ = try await store.save(projectID:initial.projectID,operationID:UUID(),expected:initial,content:content)
        let restored = try await ArticlePersistence(directory:root).open(initial.projectID)
        XCTAssertEqual(restored.content,content)
    }
    func testRealConversionOutputCanBeReconciledAfterRestart() async throws {
        let destination = ArticleFixtures.root(), id = UUID(), article = try await ArticleFixtures.create(ArticlePersistence(directory:ArticleFixtures.root()))
        let image = try ArticleImageConverter.convert(ArticleImageFixture.make(width:300,height:200))
        let first = try await ArticleProbeDelivery().write(article:article,image:image,destination:destination,jobID:id)
        let second = try await ArticleProbeDelivery().write(article:article,image:image,destination:destination,jobID:id)
        XCTAssertEqual(first,second)
    }
    func testOutputDeadlineProtectsExistingFolder() async throws {
        let destination = ArticleFixtures.root(), article = try await ArticleFixtures.create(ArticlePersistence(directory:ArticleFixtures.root()))
        let image = try ArticleImageConverter.convert(ArticleImageFixture.make(width:30,height:20))
        let delivery = ArticleProbeDelivery(), old = try await delivery.write(article:article,image:image,destination:destination,jobID:UUID())
        let bytes = try Data(contentsOf:old.directory.appendingPathComponent("01.jpg"))
        do { _ = try await delivery.write(article:article,image:image,destination:destination,jobID:UUID(),deadline:ContinuousClock().now); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure,.timedOut) }
        XCTAssertEqual(try Data(contentsOf:old.directory.appendingPathComponent("01.jpg")),bytes)
    }
    func testTwoStoreInstancesDetectStaleWrite() async throws {
        let root=ArticleFixtures.root(), first=ArticlePersistence(directory:root), second=ArticlePersistence(directory:root), initial=try await ArticleFixtures.create(first)
        var content=initial.content; content.title="最初"
        _ = try await first.save(projectID:initial.projectID,operationID:UUID(),expected:initial,content:content)
        content.title="古い入力"
        do { _ = try await second.save(projectID:initial.projectID,operationID:UUID(),expected:initial,content:content); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure,.conflict) }
    }
    func testOneHundredArticleScan() async throws {
        let store=ArticlePersistence(directory:ArticleFixtures.root())
        for _ in 0..<100 { _ = try await ArticleFixtures.create(store) }
        let list=try await store.list(); XCTAssertEqual(list.articles.count,100); XCTAssertTrue(list.failures.isEmpty)
    }
    func testOneThousandOperationsAndOldRetry() async throws {
        let store=ArticlePersistence(directory:ArticleFixtures.root()), id=UUID(), source=try ArticleFixtures.source(), operation=UUID(), content=ArticleContent(source:source)
        var article=try await store.create(projectID:id,operationID:operation,source:source,content:content)
        for index in 0..<1000 { var next=article.content; next.title="版\(index)"; article=try await store.save(projectID:id,operationID:UUID(),expected:article,content:next) }
        let old=try await store.create(projectID:id,operationID:operation,source:source,content:content)
        XCTAssertEqual(old.savedRevision,1); XCTAssertEqual(article.savedRevision,1001)
    }
    func testLongTextSaveThirtySamples() async throws {
        let store=ArticlePersistence(directory:ArticleFixtures.root()); var article=try await ArticleFixtures.create(store)
        for _ in 0..<99 {_ = try await ArticleFixtures.create(store)}
        for index in 0..<1000 {var content=article.content; content.title="準備\(index)"; article=try await store.save(projectID:article.projectID,operationID:UUID(),expected:article,content:content)}
        var samples:[Double]=[]
        for index in 0..<30 {
            var content=article.content; content.title=String(repeating:"題",count:200-String(index).count)+String(index)
            content.introduction=String(repeating:"導",count:10000); content.closing=String(repeating:"終",count:10000)
            for photo in 0..<4 {content.photoTexts[photo].text=String(repeating:"写",count:10000)}
            let start=ContinuousClock().now
            article=try await store.save(projectID:article.projectID,operationID:UUID(),expected:article,content:content)
            let duration=start.duration(to:ContinuousClock().now).components
            samples.append(Double(duration.seconds)+Double(duration.attoseconds)/1e18)
        }
        samples.sort(); XCTAssertLessThan(samples[28],2,"保存p95秒: \(samples[28])")
        print("Article save samples=30 p95=\(samples[28]) seconds")
    }
    func testColdOpenTenSamples() async throws {
        let root=ArticleFixtures.root(), original=try await ArticleFixtures.create(ArticlePersistence(directory:root))
        var samples:[Double]=[]
        for _ in 0..<10 {
            let start=ContinuousClock().now
            let restored=try await ArticlePersistence(directory:root).open(original.projectID); XCTAssertEqual(restored,original)
            let duration=start.duration(to:ContinuousClock().now).components; samples.append(Double(duration.seconds)+Double(duration.attoseconds)/1e18)
        }
        print("Article cold store reopen samples=10 seconds=\(samples); process cold launch is separate manual verification")
    }
    func testImageMemoryAndThirtyConversions() async throws {
        let input=try ArticleImageFixture.make(width:4000,height:3000)
        var baseline:[UInt64]=[]
        for _ in 0..<100 {baseline.append(try ArticleMemorySample.read().footprint); try await Task.sleep(for:.milliseconds(50))}
        baseline.sort(); let median=baseline[50], before=try ArticleMemorySample.read()
        let measurement=Task.detached { () throws -> [Double] in
            var samples:[Double]=[]
            for _ in 0..<30 {
                let start=ContinuousClock().now
                let image=try ArticleImageConverter.convert(input)
                XCTAssertEqual(image.width,2560)
                let duration=start.duration(to:ContinuousClock().now).components
                samples.append(Double(duration.seconds)+Double(duration.attoseconds)/1e18)
            }
            return samples
        }
        var peak=median
        // 独立の実変換タスクを計測し、UI actor の同期ブロックを避ける。
        let sampler=Task { () throws -> UInt64 in
            var maximum=median
            while !Task.isCancelled {maximum=max(maximum,try ArticleMemorySample.read().footprint); try? await Task.sleep(for:.milliseconds(25))}
            return maximum
        }
        let times=try await measurement.value; sampler.cancel(); peak=max(peak,try await sampler.value)
        let after=try ArticleMemorySample.read()
        let delta=peak > median ? peak-median : 0
        XCTAssertLessThanOrEqual(delta,512*1024*1024)
        XCTAssertTrue(times.allSatisfy {$0 < 30})
        print("Article image trials=30 baselineMedian=\(median) samplePeak=\(peak) delta=\(delta) lifetimePeakBefore=\(before.lifetimePeak) lifetimePeakAfter=\(after.lifetimePeak) maxSeconds=\(times.max()!)")
        if before.lifetimePeak >= after.lifetimePeak {print("Article OS lifetime peak predates trial: short-peak attribution remains unverified; isolated process verification required")}
    }
}
private final class ArticleDiagnosticCapture:@unchecked Sendable {
    private let lock=NSLock()
    private var values:[String]=[]
    var lines:[String] {lock.lock(); defer {lock.unlock()}; return values}
    func append(_ value:String) {lock.lock(); values.append(value); lock.unlock()}
}
private struct ArticleMemorySample {
    let footprint:UInt64, lifetimePeak:UInt64
    static func read() throws ->ArticleMemorySample {
        var info=task_vm_info_data_t(), count=mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size/MemoryLayout<integer_t>.size)
        let result=withUnsafeMutablePointer(to:&info) {pointer in
            pointer.withMemoryRebound(to:integer_t.self,capacity:Int(count)) {task_info(mach_task_self_,task_flavor_t(TASK_VM_INFO),$0,&count)}
        }
        guard result == KERN_SUCCESS else {throw ArticleFailure.ioFailure}
        guard info.ledger_phys_footprint_peak >= 0 else {throw ArticleFailure.ioFailure}
        return ArticleMemorySample(footprint:info.phys_footprint,lifetimePeak:UInt64(info.ledger_phys_footprint_peak))
    }
}
