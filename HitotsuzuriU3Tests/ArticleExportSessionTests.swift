import XCTest
@testable import HitotsuzuriCore

@MainActor final class ArticleExportSessionTests: XCTestCase {
    private func fixture(_ body: (URL, ArticlePresentation, ExportTestActions, ArticleExportSession) async throws -> Void) async throws {
        let root = try ExportFixture.root("session"); defer { try? FileManager.default.removeItem(at: root) }
        let prepared = try ExportFixture.prepared(), store = ArticlePersistence(directory: root.appendingPathComponent("articles"))
        let article = try await store.create(projectID: prepared.savedInput.article.projectID, operationID: UUID(), source: prepared.savedInput.article.source, content: prepared.savedInput.article.content)
        let actions = ExportTestActions(), presentation = ArticlePresentation(workspace: ArticleWorkspace(selections: U3Store(), articles: store), store: store, output: actions)
        presentation.adopt(ArticleEditSession(article: article, store: store))
        try await body(root, presentation, actions, ArticleExportSession(presentation: presentation, actions: actions))
    }
    func testCleanSavedInputIsExportedAndFocusReturns() async throws {
        try await fixture { root, _, actions, session in
            await session.start(choice: .save) { ArticleExportDestination(grantID: UUID(), selectedDirectory: root) }
            XCTAssertEqual(actions.calls, 1); XCTAssertNotNil(session.result); XCTAssertFalse(session.isBusy); XCTAssertEqual(session.focusReturn, 1)
        }
    }
    func testDirtyInputNeedsExplicitSaveChoice() async throws {
        try await fixture { root, presentation, actions, session in
            presentation.session?.content.title = "未保存"
            await session.start(choice: .keepEditing) { XCTFail("保存先を先に選択した"); return ArticleExportDestination(grantID: UUID(), selectedDirectory: root) }
            XCTAssertEqual(actions.calls, 0); XCTAssertTrue(presentation.session!.isDirty)
        }
    }
    func testSavingBeforeExportPreservesExactSnapshot() async throws {
        try await fixture { root, presentation, _, session in
            presentation.session?.content.title = "保存して出力"
            await session.start(choice: .save) { ArticleExportDestination(grantID: UUID(), selectedDirectory: root) }
            XCTAssertFalse(presentation.session!.isDirty); XCTAssertTrue(session.result?.fixedPlainText.contains("保存して出力") == true)
        }
    }
    func testDestinationAwaitInputChangeCannotExportStaleSnapshot() async throws {
        try await fixture { root, presentation, actions, session in
            await session.start(choice: .save) {
                presentation.session?.content.title = "選択待ち中の変更"
                return ArticleExportDestination(grantID: UUID(), selectedDirectory: root)
            }
            XCTAssertEqual(actions.calls, 0); XCTAssertNil(session.result); XCTAssertFalse(session.message.isEmpty)
        }
    }
    func testDuplicateStartAndNavigationAreBlockedUntilTerminal() async throws {
        try await fixture { root, presentation, actions, session in
            let latch = U3Latch(); actions.pause = latch
            let task = Task { await session.start(choice: .save) { ArticleExportDestination(grantID: UUID(), selectedDirectory: root) } }
            try await ExportFixture.waitUntil { latch.waiting }
            XCTAssertTrue(session.isBusy)
            await session.start(choice: .save) { ArticleExportDestination(grantID: UUID(), selectedDirectory: root) }
            let navigation = await presentation.requestNavigation(.back)
            XCTAssertFalse(navigation)
            latch.open(); await task.value
            XCTAssertEqual(actions.calls, 1); XCTAssertFalse(session.isBusy)
        }
    }
    func testOldProgressIsDiscarded() async throws {
        try await fixture { root, _, actions, session in
            let latch = U3Latch(); actions.pause = latch
            let task = Task { await session.start(choice: .save) { ArticleExportDestination(grantID: UUID(), selectedDirectory: root) } }
            try await ExportFixture.waitUntil { latch.waiting }
            let before = session.progress?.jobID
            session.receive(ExportProgress(jobID: UUID(), stage: "succeeded", completedImages: 4))
            XCTAssertEqual(session.progress?.jobID, before); XCTAssertEqual(session.progress?.completedImages, 1)
            latch.open(); await task.value
        }
    }
    func testCancellationReturnsControlAfterActualTerminal() async throws {
        try await fixture { root, presentation, actions, session in
            let latch = U3Latch(); actions.pause = latch
            let task = Task { await session.start(choice: .save) { ArticleExportDestination(grantID: UUID(), selectedDirectory: root) } }
            try await ExportFixture.waitUntil { latch.waiting }
            session.cancel(); await task.value
            XCTAssertEqual(actions.cancelCalls, 1); XCTAssertFalse(session.isBusy); XCTAssertNil(session.result)
            XCTAssertEqual(session.focusReturn, 1); XCTAssertNotNil(presentation.session)
        }
    }
    func testFailureKeepsArticleAndDisplaysReason() async throws {
        try await fixture { root, presentation, actions, session in
            let content = presentation.session!.content; actions.runFailure = .assetUnavailable
            await session.start(choice: .save) { ArticleExportDestination(grantID: UUID(), selectedDirectory: root) }
            XCTAssertEqual(presentation.session?.content, content); XCTAssertNil(session.result)
            XCTAssertTrue(session.message.contains("画像")); XCTAssertEqual(session.focusReturn, 1)
        }
    }
}
