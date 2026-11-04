import XCTest
@testable import HitotsuzuriCore

final class ArticlePersistenceTests: XCTestCase {
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
