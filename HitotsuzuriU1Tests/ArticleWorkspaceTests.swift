import XCTest
@testable import HitotsuzuriCore

final class ArticleWorkspaceTests: XCTestCase {
    func testNewSelectionResolvesWithoutImageAccess() async throws {
        let selection = ArticleSelectionStore()
        let work = ArticleWorkspace(selections: selection, articles: ArticlePersistence(directory: ArticleFixtures.root()))
        guard case .newArticle(let source) = try await work.resolve() else { return XCTFail() }
        XCTAssertEqual(source.orderedAssetIDs.count, 4)
    }
    func testExactSelectionReopensSameProject() async throws {
        let selection = ArticleSelectionStore(), store = ArticlePersistence(directory: ArticleFixtures.root())
        let work = ArticleWorkspace(selections: selection, articles: store)
        guard case .newArticle(let source) = try await work.resolve() else { return XCTFail() }
        let a = try await store.create(projectID: UUID(), operationID: UUID(), source: source, content: ArticleContent(source: source))
        guard case .existing(let b) = try await work.resolve() else { return XCTFail() }
        XCTAssertEqual(a.projectID, b.projectID)
    }
    func testReconfirmedSelectionRequiresChoice() async throws {
        let selection = ArticleSelectionStore(), store = ArticlePersistence(directory: ArticleFixtures.root())
        _ = try await ArticleFixtures.create(store)
        let work = ArticleWorkspace(selections: selection, articles: store)
        guard case .matchingCandidates(let values) = try await work.resolve() else { return XCTFail() }
        XCTAssertEqual(values.count, 1)
    }
    func testMissingSelectionDoesNotCreateDraft() async throws {
        let selection = ArticleSelectionStore(); await selection.set(nil)
        let work = ArticleWorkspace(selections: selection, articles: ArticlePersistence(directory: ArticleFixtures.root()))
        do { _ = try await work.resolve(); XCTFail() } catch { XCTAssertEqual(error as? ArticleFailure, .missing) }
    }
    func testDifferentPhotoOrderIsNotSameCandidate() async throws {
        let selection = ArticleSelectionStore(), store = ArticlePersistence(directory: ArticleFixtures.root())
        _ = try await ArticleFixtures.create(store)
        await selection.set(CommittedSelection(albumID: "album", albumTitle: "記事", orderedAssetIDs: ["d", "c", "b", "a"]))
        let work = ArticleWorkspace(selections: selection, articles: store)
        guard case .newArticle = try await work.resolve() else { return XCTFail() }
    }
    func testSelectionReadFailureIsNotMissing() async throws {
        let selection = ArticleSelectionStore(); await selection.fail()
        let work = ArticleWorkspace(selections: selection, articles: ArticlePersistence(directory: ArticleFixtures.root()))
        do { _ = try await work.resolve(); XCTFail() } catch { XCTAssertEqual(error as? ArticleFailure, .corruptData) }
    }
}

actor ArticleSelectionStore: SelectionStoring {
    var selection: CommittedSelection? = .init(albumID: "album", albumTitle: "記事", orderedAssetIDs: ["a", "b", "c", "d"])
    var failure = false
    func set(_ value: CommittedSelection?) { selection = value }
    func fail() { failure = true }
    func loadSelection() -> StoredValue<CommittedSelection> { failure ? .failure(.corruptData) : selection.map { .valid($0) } ?? .missing }
    func saveSelection(_ selection: CommittedSelection) { self.selection = selection }
    func loadSettings() -> StoredValue<TargetFolderSettings> { .missing }
    func saveSettings(_ settings: TargetFolderSettings) {}
}
