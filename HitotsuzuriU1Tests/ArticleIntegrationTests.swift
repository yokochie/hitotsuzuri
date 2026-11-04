import XCTest
@testable import HitotsuzuriCore

final class ArticleIntegrationTests: XCTestCase {
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
        var samples:[Double]=[]
        for index in 0..<30 {
            var content=article.content; content.title=String(repeating:"題",count:199)+String(index)
            content.introduction=String(repeating:"導",count:10000); content.closing=String(repeating:"終",count:10000)
            for photo in 0..<4 {content.photoTexts[photo].text=String(repeating:"写",count:10000)}
            let start=ContinuousClock().now
            article=try await store.save(projectID:article.projectID,operationID:UUID(),expected:article,content:content)
            samples.append(Double(start.duration(to:ContinuousClock().now).components.attoseconds)/1e18 + Double(start.duration(to:ContinuousClock().now).components.seconds))
        }
        samples.sort(); XCTAssertLessThan(samples[28],2,"保存p95秒: \(samples[28])")
        print("Article save samples=30 p95=\(samples[28]) seconds")
    }
    func testColdOpenTenSamples() async throws {
        let root=ArticleFixtures.root(), original=try await ArticleFixtures.create(ArticlePersistence(directory:root))
        for _ in 0..<10 {let restored=try await ArticlePersistence(directory:root).open(original.projectID); XCTAssertEqual(restored,original)}
    }
}
