import XCTest
@testable import HitotsuzuriCore

@MainActor final class ArticleEntryTests: XCTestCase {
    func testPartialFailureCanBeExplicitlyReloaded() async throws {
        let h=DraftHarness.make(); _=try await h.savedSession(); _=await h.presentation.requestNavigation(.back)
        await h.store.configure(individual:[UUID():.corruptData])
        await h.presentation.openDrafts(); XCTAssertEqual(h.presentation.candidates?.failures.count,1)
        await h.store.configure(); await h.presentation.retryCandidates()
        XCTAssertTrue(h.presentation.candidates?.failures.isEmpty == true)
        XCTAssertEqual(h.presentation.candidates?.articles.count,1)
        XCTAssertNil(h.presentation.session)
    }
    func testCurrentSelectionStartsNewWithCandidateOnce() async throws {
        let h=DraftHarness.make(); await h.presentation.beginCurrentSelection()
        let session=try XCTUnwrap(h.presentation.session)
        XCTAssertEqual(session.content.title,"散歩"); XCTAssertEqual(session.content.dateCandidateState,.candidate)
        XCTAssertNotNil(session.saved)
        let count=await h.store.createCount; XCTAssertEqual(count,1)
    }
    func testExactSelectionReopensSameArticleFromEitherEntry() async throws {
        let h=DraftHarness.make(), saved=try await h.savedSession().saved
        await h.presentation.requestNavigation(.back)
        await h.presentation.beginCurrentSelection()
        XCTAssertEqual(h.presentation.session?.projectID,saved?.id)
    }
    func testMultipleExactArticlesRequireChoice() async throws {
        let h=DraftHarness.make(), source=try await h.workspace.readCommittedSelection()
        for _ in 0..<2 { _=try await h.store.create(projectID:UUID(),operationID:UUID(),source:source,content:ArticleContent(source:source)) }
        await h.presentation.beginCurrentSelection()
        XCTAssertNil(h.presentation.session); XCTAssertEqual(h.presentation.candidates?.articles.count,2)
        XCTAssertFalse(h.presentation.allowsNew)
    }
    func testReconfirmationOffersNewOrResumeWithoutAutoWrite() async throws {
        let h=DraftHarness.make(); let saved=try await h.savedSession().saved
        _=await h.presentation.requestNavigation(.back)
        await h.selections.set(CommittedSelection(albumID:"draft-album",albumTitle:"再確定",orderedAssetIDs:["a","b","c","d"]))
        await h.presentation.beginCurrentSelection()
        XCTAssertNil(h.presentation.session); XCTAssertEqual(h.presentation.candidates?.articles.first?.id,saved?.id); XCTAssertTrue(h.presentation.allowsNew)
        let count=await h.store.createCount; XCTAssertEqual(count,1)
    }
    func testPartialFailureKeepsHealthyCandidatesAndStopsAutomaticNew() async throws {
        let h=DraftHarness.make(); _=try await h.savedSession(); _=await h.presentation.requestNavigation(.back)
        let broken=UUID(); await h.store.configure(individual:[broken:.corruptData])
        await h.selections.set(CommittedSelection(albumID:"draft-album",albumTitle:"再確定",orderedAssetIDs:["a","b","c","d"]))
        await h.presentation.beginCurrentSelection()
        XCTAssertEqual(h.presentation.candidates?.articles.count,1)
        XCTAssertEqual(h.presentation.candidates?.failures[broken],.corruptData)
        XCTAssertFalse(h.presentation.allowsNew)
    }
    func testGlobalFailureIsNotEmptyDrafts() async throws {
        let h=DraftHarness.make(); await h.store.configure(list:.ioFailure)
        await h.presentation.openDrafts()
        XCTAssertEqual(h.presentation.failure,.ioFailure); XCTAssertNil(h.presentation.candidates)
        XCTAssertNil(h.presentation.session)
    }
    func testCancelCandidatesDoesNotCreateOrModifyAnything() async throws {
        let h=DraftHarness.make(); await h.presentation.openDrafts()
        XCTAssertNotNil(h.presentation.candidates)
        h.presentation.cancelCandidates()
        XCTAssertNil(h.presentation.candidates); XCTAssertNil(h.presentation.session)
        let count=await h.store.createCount; XCTAssertEqual(count,0)
    }
    func testRepeatedEntryDoesNotDuplicateArticle() async throws {
        let h=DraftHarness.make()
        await h.presentation.beginCurrentSelection(); await h.presentation.beginCurrentSelection()
        let count=await h.store.createCount; XCTAssertEqual(count,1)
        XCTAssertNotNil(h.presentation.session)
    }
}
