import XCTest
@testable import HitotsuzuriCore

final class ArticlePersistenceTests: XCTestCase {
    func testEncodedOperationJustBelowLimitCanReopenFromAnotherStore() async throws {
        let root=ArticleFixtures.root(), store=ArticlePersistence(directory:root), article=try await ArticleFixtures.create(store), id=UUID()
        var content=article.content; content.introduction=String(repeating:"x",count:64*1024*1024-4096)
        let saved=try await store.save(projectID:article.projectID,operationID:id,expected:article,content:content)
        let url=root.appendingPathComponent(article.projectID.uuidString).appendingPathComponent("operations").appendingPathComponent(id.uuidString)
        let size=(try FileManager.default.attributesOfItem(atPath:url.path)[.size] as! NSNumber).intValue
        XCTAssertLessThanOrEqual(size,64*1024*1024); XCTAssertGreaterThan(size,64*1024*1024-4096)
        let reopened=try await ArticlePersistence(directory:root).open(article.projectID)
        XCTAssertEqual(reopened.fingerprint,saved.fingerprint); XCTAssertEqual(reopened.content.introduction,content.introduction)
    }
    func testFileWriteAndReadHaveTheSameExactByteBoundary() throws {
        let root=try ArticleDirectory.open(ArticleFixtures.root(),create:true), count=ArticleDirectory.maximumFileBytes
        let bytes=Data(repeating:0,count:count)
        try root.writeNew("boundary",data:bytes)
        XCTAssertEqual(try root.read("boundary").count,count)
        XCTAssertThrowsError(try root.writeNew("over",data:Data(repeating:0,count:count+1))) {XCTAssertEqual($0 as? ArticleFailure,.capacity)}
        XCTAssertThrowsError(try root.read("over")) {XCTAssertEqual($0 as? ArticleFailure,.missing)}
    }
    func testOversizedEncodedOperationNeverReplacesReadableCurrent() async throws {
        let root=ArticleFixtures.root(), store=ArticlePersistence(directory:root), article=try await ArticleFixtures.create(store)
        let current=root.appendingPathComponent(article.projectID.uuidString).appendingPathComponent("current"), before=try Data(contentsOf:current)
        var content=article.content; content.introduction=String(repeating:"x",count:64*1024*1024)
        do {_ = try await store.save(projectID:article.projectID,operationID:UUID(),expected:article,content:content); XCTFail("読めない大きさを確定しない")}
        catch {XCTAssertEqual(error as? ArticleFailure,.capacity)}
        XCTAssertEqual(try Data(contentsOf:current),before)
        let reopened=try await ArticlePersistence(directory:root).open(article.projectID); XCTAssertEqual(reopened,article)
    }
    func testCreateAndReopenFromAnotherStore() async throws {
        let root = ArticleFixtures.root(), store = ArticlePersistence(directory: root)
        let a = try await ArticleFixtures.create(store)
        let loaded = try await ArticlePersistence(directory: root).open(a.projectID)
        XCTAssertEqual(a, loaded)
    }
    func testManualSaveIncrementsRevision() async throws {
        let store = ArticlePersistence(directory: ArticleFixtures.root())
        let a = try await ArticleFixtures.create(store)
        var c = a.content; c.title = "保存済み"
        let b = try await store.save(projectID: a.projectID, operationID: UUID(), expected: a, content: c)
        XCTAssertEqual(b.savedRevision, 2); XCTAssertEqual(b.content.title, "保存済み")
    }
    func testSameContentDoesNotIncrement() async throws {
        let store = ArticlePersistence(directory: ArticleFixtures.root()), a = try await ArticleFixtures.create(store)
        let b = try await store.save(projectID: a.projectID, operationID: UUID(), expected: a, content: a.content)
        XCTAssertEqual(b.savedRevision, a.savedRevision)
    }
    func testOldExpectedRevisionConflicts() async throws {
        let store = ArticlePersistence(directory: ArticleFixtures.root()), a = try await ArticleFixtures.create(store)
        var c = a.content; c.title = "1"
        _ = try await store.save(projectID: a.projectID, operationID: UUID(), expected: a, content: c)
        do { _ = try await store.save(projectID: a.projectID, operationID: UUID(), expected: a, content: c); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .conflict) }
    }
    func testResponseLossRetryReturnsOriginalResultAfterLaterSave() async throws {
        let store = ArticlePersistence(directory: ArticleFixtures.root()), a = try await ArticleFixtures.create(store)
        let operation = UUID(); var c = a.content; c.title = "first"
        let b = try await store.save(projectID: a.projectID, operationID: operation, expected: a, content: c)
        var next = c; next.title = "second"
        _ = try await store.save(projectID: a.projectID, operationID: UUID(), expected: b, content: next)
        let retry = try await store.save(projectID: a.projectID, operationID: operation, expected: a, content: c)
        XCTAssertEqual(retry, b)
    }
    func testReusingOperationForDifferentInputFails() async throws {
        let store = ArticlePersistence(directory: ArticleFixtures.root()), a = try await ArticleFixtures.create(store)
        let operation = UUID(); var c = a.content; c.title = "first"
        _ = try await store.save(projectID: a.projectID, operationID: operation, expected: a, content: c)
        c.title = "different"
        do { _ = try await store.save(projectID: a.projectID, operationID: operation, expected: a, content: c); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .invalidInput) }
    }
    func testMissingAndEmptyListAreDistinctFromCorrupt() async throws {
        let store = ArticlePersistence(directory: ArticleFixtures.root())
        let list = try await store.list(); XCTAssertTrue(list.articles.isEmpty)
        do { _ = try await store.open(UUID()); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .missing) }
    }
}
