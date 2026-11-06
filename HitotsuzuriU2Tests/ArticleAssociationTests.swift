import XCTest
@testable import HitotsuzuriCore

@MainActor final class ArticleAssociationTests: XCTestCase {
    @MainActor func testCancelledBeforeCommitDoesNotAssociate() async throws {
        let (store, saved, source) = try await setup()
        let task = Task { try await store.resumeWithSelection(projectID: saved.id, operationID: UUID(), expected: saved, source: source) }
        task.cancel()
        do { _ = try await task.value; XCTFail("確定前取消") }
        catch { XCTAssertEqual(error as? ArticleFailure, .cancelled) }
        let reopened = try await store.open(saved.id)
        XCTAssertEqual(reopened, saved)
    }
    func testCancellationAfterCommitReturnsCommittedAssociation() async throws {
        let root = DraftFixtures.root()
        let base = ArticlePersistence(directory: root)
        let source = try DraftFixtures.source()
        let saved = try await base.create(projectID: UUID(), operationID: UUID(), source: source, content: ArticleContent(source: source))
        let store = ArticlePersistence(directory: root, checkpoint: { point in
            if case .afterCurrent = point { withUnsafeCurrentTask { $0?.cancel() } }
        })
        let new = try DraftFixtures.source()
        let task = Task { try await store.resumeWithSelection(projectID: saved.id, operationID: UUID(), expected: saved, source: new) }
        let result = try await task.value
        XCTAssertTrue(result.sourceSelectionIDs.contains(new.selectionID))
        let reopened = try await base.open(saved.id); XCTAssertEqual(reopened, result)
    }
    private func setup(root: URL = DraftFixtures.root()) async throws -> (ArticlePersistence, SavedArticle, ArticleSource) {
        let store = ArticlePersistence(directory: root)
        let source = try DraftFixtures.source()
        var content = ArticleInitialContent(source: source).content
        content.introduction = "私的入力e\u{301}\n👨‍👩‍👧"; content.people = "人物"
        let saved = try await store.create(projectID: UUID(), operationID: UUID(), source: source, content: content)
        return (store, saved, try DraftFixtures.source("新しい名前@260101"))
    }
    func testAssociationAddsOnlySelectionAndPreservesOriginalValues() async throws {
        let (store, saved, new) = try await setup()
        let result = try await store.resumeWithSelection(projectID: saved.id, operationID: UUID(), expected: saved, source: new)
        XCTAssertEqual(result.source, saved.source); XCTAssertEqual(result.content, saved.content)
        XCTAssertEqual(result.fingerprint, saved.fingerprint); XCTAssertEqual(result.createdAt, saved.createdAt)
        XCTAssertEqual(result.sourceSelectionIDs, [saved.source.selectionID, new.selectionID])
        XCTAssertEqual(result.savedRevision, 2)
        let reopened = try await store.open(saved.id); XCTAssertEqual(reopened, result)
    }
    func testDifferentPhotoOrderIsRejected() async throws {
        let (store, saved, _) = try await setup()
        let source = try ArticleSource(selection: CommittedSelection(albumID: saved.source.albumID, albumTitle: "別", orderedAssetIDs: ["b", "a", "c", "d"]))
        do { _ = try await store.resumeWithSelection(projectID: saved.id, operationID: UUID(), expected: saved, source: source); XCTFail("異順序を拒否") }
        catch { XCTAssertEqual(error as? ArticleFailure, .invalidInput) }
        let reopened = try await store.open(saved.id); XCTAssertEqual(reopened, saved)
    }
    func testStaleExpectedRevisionConflicts() async throws {
        let (store, saved, new) = try await setup()
        var content = saved.content; content.closing = "保存後"
        let latest = try await store.save(projectID: saved.id, operationID: UUID(), expected: saved, content: content)
        do { _ = try await store.resumeWithSelection(projectID: saved.id, operationID: UUID(), expected: saved, source: new); XCTFail("競合") }
        catch { XCTAssertEqual(error as? ArticleFailure, .conflict) }
        let reopened = try await store.open(saved.id); XCTAssertEqual(reopened, latest)
    }
    func testSameOperationReturnsOriginalEvenAfterLaterSave() async throws {
        let (store, saved, new) = try await setup(); let operation = UUID()
        let first = try await store.resumeWithSelection(projectID: saved.id, operationID: operation, expected: saved, source: new)
        var content = first.content; content.title = "後続"
        _ = try await store.save(projectID: saved.id, operationID: UUID(), expected: first, content: content)
        let repeated = try await store.resumeWithSelection(projectID: saved.id, operationID: operation, expected: saved, source: new)
        XCTAssertEqual(repeated, first)
    }
    func testOperationReuseWithDifferentSelectionIsRejected() async throws {
        let (store, saved, new) = try await setup(); let operation = UUID()
        _ = try await store.resumeWithSelection(projectID: saved.id, operationID: operation, expected: saved, source: new)
        do { _ = try await store.resumeWithSelection(projectID: saved.id, operationID: operation, expected: saved, source: DraftFixtures.source()); XCTFail("ID再利用") }
        catch { XCTAssertEqual(error as? ArticleFailure, .invalidInput) }
    }
    func testExistingAssociationDoesNotAdvanceRevisionOrTime() async throws {
        let (store, saved, _) = try await setup()
        let result = try await store.resumeWithSelection(projectID: saved.id, operationID: UUID(), expected: saved, source: saved.source)
        XCTAssertEqual(result, saved)
    }
    func testUncertainCommitReconcilesWithSameOperation() async throws {
        let root = DraftFixtures.root(), gate = DraftCheckpoint()
        let store = ArticlePersistence(directory: root, checkpoint: { try gate.check($0) })
        let source = try DraftFixtures.source()
        let saved = try await store.create(projectID: UUID(), operationID: UUID(), source: source, content: ArticleContent(source: source))
        let new = try DraftFixtures.source(), operation = UUID()
        gate.arm()
        do { _ = try await store.resumeWithSelection(projectID: saved.id, operationID: operation, expected: saved, source: new); XCTFail("不確定") }
        catch { XCTAssertEqual(error as? ArticleFailure, .uncertainResult) }
        let retry = try await store.resumeWithSelection(projectID: saved.id, operationID: operation, expected: saved, source: new)
        XCTAssertEqual(retry.savedRevision, 2); XCTAssertEqual(retry.sourceSelectionIDs.count, 2)
        let reopened = try await ArticlePersistence(directory: root).open(saved.id)
        XCTAssertEqual(reopened, retry)
    }
    func testPartialReadFailureDoesNotEraseHealthyAssociation() async throws {
        let root = DraftFixtures.root()
        let (store, saved, new) = try await setup(root: root)
        let broken = try await store.create(projectID: UUID(), operationID: UUID(), source: new, content: ArticleContent(source: new))
        try Data("broken".utf8).write(to: root.appendingPathComponent(broken.id.uuidString).appendingPathComponent("current"))
        let result = try await store.resumeWithSelection(projectID: saved.id, operationID: UUID(), expected: saved, source: new)
        let list = try await store.list()
        XCTAssertEqual(list.articles, [result]); XCTAssertEqual(list.failures, [broken.id: .corruptData])
        XCTAssertEqual(result.schemaVersion, 1)
    }
}
