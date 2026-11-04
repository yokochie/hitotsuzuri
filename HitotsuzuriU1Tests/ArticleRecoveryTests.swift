import XCTest
@testable import HitotsuzuriCore

final class ArticleRecoveryTests: XCTestCase {
    func testIndependentStoreCannotWriteWhileOSLockIsHeld() async throws {
        let root=ArticleFixtures.root(), original=try await ArticleFixtures.create(ArticlePersistence(directory:root)), gate=ArticleCheckpointGate()
        let first=ArticlePersistence(directory:root,checkpoint:{if $0 == .beforeCurrent {gate.wait()}})
        var content=original.content; content.title="排他保存"
        let snapshot=content
        let task=Task {try await first.save(projectID:original.projectID,operationID:UUID(),expected:original,content:snapshot)}
        while !gate.started {await Task.yield()}
        do {_ = try await ArticlePersistence(directory:root).save(projectID:original.projectID,operationID:UUID(),expected:original,content:snapshot); XCTFail()}
        catch {XCTAssertEqual(error as? ArticleFailure,.busy)}
        gate.resume()
        let result=try await task.value; XCTAssertEqual(result.savedRevision,2)
    }
    func testCapacityBeforeOperationKeepsCurrentBytes() async throws {
        let root=ArticleFixtures.root(), store=ArticlePersistence(directory:root), article=try await ArticleFixtures.create(store)
        let current=root.appendingPathComponent(article.projectID.uuidString).appendingPathComponent("current"), bytes=try Data(contentsOf:current)
        let failing=ArticlePersistence(directory:root,checkpoint:{if $0 == .beforeOperation {throw ArticleFailure.capacity}})
        var content=article.content; content.title="容量不足"
        do {_ = try await failing.save(projectID:article.projectID,operationID:UUID(),expected:article,content:content); XCTFail()}
        catch {XCTAssertEqual(error as? ArticleFailure,.capacity)}
        XCTAssertEqual(try Data(contentsOf:current),bytes)
    }
    func testRealWritePermissionLossKeepsOldArticle() async throws {
        let root=ArticleFixtures.root(), store=ArticlePersistence(directory:root), article=try await ArticleFixtures.create(store)
        let project=root.appendingPathComponent(article.projectID.uuidString), current=project.appendingPathComponent("current"), bytes=try Data(contentsOf:current)
        try FileManager.default.setAttributes([.posixPermissions:0o500],ofItemAtPath:project.path)
        defer {try? FileManager.default.setAttributes([.posixPermissions:0o700],ofItemAtPath:project.path)}
        var content=article.content; content.title="権限喪失"
        do {_ = try await store.save(projectID:article.projectID,operationID:UUID(),expected:article,content:content); XCTFail()}
        catch {XCTAssertEqual(error as? ArticleFailure,.permissionDenied)}
        XCTAssertEqual(try Data(contentsOf:current),bytes)
    }
    func testRenameBeforeSyncRemainsUncertainUntilSameOperationReconciles() async throws {
        let root=ArticleFixtures.root(), store=ArticlePersistence(directory:root), article=try await ArticleFixtures.create(store), id=UUID()
        var content=article.content; content.title="同期確認待ち"
        let failing=ArticlePersistence(directory:root,checkpoint:{if $0 == .currentRenamed {throw ArticleFailure.ioFailure}})
        do {_ = try await failing.save(projectID:article.projectID,operationID:id,expected:article,content:content); XCTFail()}
        catch {XCTAssertEqual(error as? ArticleFailure,.uncertainResult)}
        let recovered=try await store.save(projectID:article.projectID,operationID:id,expected:article,content:content)
        XCTAssertEqual(recovered.savedRevision,2); XCTAssertEqual(recovered.content,content)
    }
    func testDuplicateJSONKeysAreRejectedWithoutChangingBytes() async throws {
        let root=ArticleFixtures.root(), store=ArticlePersistence(directory:root), article=try await ArticleFixtures.create(store)
        let url=root.appendingPathComponent(article.projectID.uuidString).appendingPathComponent("current")
        let valid=try String(contentsOf:url,encoding:.utf8)
        let bytes=Data(("{\"schemaVersion\":1," + valid.dropFirst()).utf8)
        try bytes.write(to:url)
        do {_ = try await store.open(article.projectID); XCTFail("重複キーは不正")}
        catch {XCTAssertEqual(error as? ArticleFailure,.corruptData)}
        XCTAssertEqual(try Data(contentsOf:url),bytes)
    }
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
private final class ArticleCheckpointGate:@unchecked Sendable {
    private let lock=NSLock(), semaphore=DispatchSemaphore(value:0)
    private var value=false
    var started:Bool {lock.lock(); defer {lock.unlock()}; return value}
    func wait() {lock.lock(); value=true; lock.unlock(); semaphore.wait()}
    func resume() {semaphore.signal()}
}
