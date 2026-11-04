import XCTest
@testable import HitotsuzuriCore

final class ArticleRecoveryTests: XCTestCase {
    func testFailureBeforeCurrentPreservesOldArticle() async throws {
        let root = ArticleFixtures.root(), store = ArticlePersistence(directory: root)
        let a = try await ArticleFixtures.create(store)
        let failed = ArticlePersistence(directory: root, checkpoint: { if $0 == .beforeCurrent { throw ArticleFailure.ioFailure } })
        var c = a.content; c.title = "new"
        do { _ = try await failed.save(projectID: a.projectID, operationID: UUID(), expected: a, content: c); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .ioFailure) }
        let old = try await store.open(a.projectID); XCTAssertEqual(old, a)
    }
    func testFailureAfterCommitReconcilesSuccess() async throws {
        let root = ArticleFixtures.root(), store = ArticlePersistence(directory: root)
        let a = try await ArticleFixtures.create(store)
        let failed = ArticlePersistence(directory: root, checkpoint: { if $0 == .afterCurrent { throw ArticleFailure.ioFailure } })
        var c = a.content; c.title = "new"
        let b = try await failed.save(projectID: a.projectID, operationID: UUID(), expected: a, content: c)
        XCTAssertEqual(b.content.title, "new")
    }
    func testCorruptCurrentIsNotTreatedAsMissing() async throws {
        let root = ArticleFixtures.root(), store = ArticlePersistence(directory: root)
        let a = try await ArticleFixtures.create(store)
        try Data("broken".utf8).write(to: root.appendingPathComponent(a.projectID.uuidString).appendingPathComponent("current"))
        do { _ = try await store.open(a.projectID); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .corruptData) }
        let list = try await store.list(); XCTAssertEqual(list.failures[a.projectID], .corruptData)
    }
    func testUnknownCurrentVersionIsProtected() async throws {
        let root = ArticleFixtures.root(), store = ArticlePersistence(directory: root)
        let a = try await ArticleFixtures.create(store)
        let url = root.appendingPathComponent(a.projectID.uuidString).appendingPathComponent("current")
        let original = Data("{\"schemaVersion\":99}".utf8); try original.write(to: url)
        do { _ = try await store.open(a.projectID); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .unsupportedVersion) }
        XCTAssertEqual(try Data(contentsOf: url), original)
    }
    func testSymlinkRootIsRejected() async throws {
        let target = ArticleFixtures.root(), root = ArticleFixtures.root()
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: root, withDestinationURL: target)
        do { _ = try await ArticleFixtures.create(ArticlePersistence(directory: root)); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .invalidReference) }
    }
    func testUnreferencedOperationRetryDoesNotDuplicate() async throws {
        let root = ArticleFixtures.root(), source = try ArticleFixtures.source(), project = UUID(), op = UUID()
        let failing = ArticlePersistence(directory: root, checkpoint: { if $0 == .beforeCurrent { throw ArticleFailure.ioFailure } })
        do { _ = try await failing.create(projectID: project, operationID: op, source: source, content: ArticleContent(source: source)); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .ioFailure) }
        let store = ArticlePersistence(directory: root)
        let a = try await store.create(projectID: project, operationID: op, source: source, content: ArticleContent(source: source))
        XCTAssertEqual(a.projectID, project)
        let list = try await store.list(); XCTAssertEqual(list.articles.count, 1)
    }
}
