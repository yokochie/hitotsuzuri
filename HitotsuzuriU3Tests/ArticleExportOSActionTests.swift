import XCTest
import AppKit
@testable import HitotsuzuriCore

@MainActor final class ArticleExportOSActionTests: XCTestCase {
    private func fixture(_ body: (URL, NSPasteboard, ArticleExportDelivery) async throws -> Void) async throws {
        let root = try ExportFixture.root("os"); defer { try? FileManager.default.removeItem(at: root) }
        let board = NSPasteboard(name: NSPasteboard.Name("hitotsuzuri-export-test-" + UUID().uuidString))
        defer { board.releaseGlobally() }
        try await body(root, board, ArticleExportDelivery(images: ExportTestImages(), journal: ArticleExportJournal(directory: root.appendingPathComponent("jobs"))))
    }
    private func export(_ root: URL, actions: ArticleExportOSActions) async throws -> ExportResult {
        let prepared = try ExportFixture.prepared(), destination = actions.register(ArticleExportDestinationAccess(url: root))
        return try await actions.runExport(jobID: UUID(), savedInput: prepared.savedInput, rendered: prepared.rendered, destination: destination) { _ in }
    }
    func testEditorCopyWritesOnlyPlainTextToDedicatedPasteboard() async throws {
        try await fixture { _, board, delivery in
            let actions = ArticleExportOSActions(delivery: delivery, pasteboard: board)
            let text = "日本語\n👨‍👩‍👧‍👦\n*本文*"
            try await actions.copyPlainText(text, context: .editor(projectID: UUID(), fingerprint: "fingerprint"))
            XCTAssertEqual(board.string(forType: .string), text)
            // macOSはplain stringを旧NSStringPboardTypeとしても公開する。
            XCTAssertTrue(Set(board.types ?? []).isSubset(of: [.string, NSPasteboard.PasteboardType("NSStringPboardType")]))
        }
    }
    func testClipboardFailureIsSeparateFromSave() async throws {
        try await fixture { _, board, delivery in
            let actions = ArticleExportOSActions(delivery: delivery, pasteboard: board, write: { _ in false })
            do { try await actions.copyPlainText("本文", context: .editor(projectID: UUID(), fingerprint: "fingerprint")); XCTFail() }
            catch { XCTAssertEqual(error as? ArticleExportOSFailure, .clipboardFailure) }
        }
    }
    func testEmptyEditorContextIsRejected() async throws {
        try await fixture { _, board, delivery in
            let actions = ArticleExportOSActions(delivery: delivery, pasteboard: board)
            do { try await actions.copyPlainText("本文", context: .editor(projectID: UUID(), fingerprint: "")); XCTFail() } catch { XCTAssertEqual(error as? ArticleFailure, .invalidInput) }
            XCTAssertNil(board.string(forType: .string))
        }
    }
    func testCompletedCopyUsesFixedTextAndRejectsChangedText() async throws {
        try await fixture { root, board, delivery in
            let actions = ArticleExportOSActions(delivery: delivery, pasteboard: board)
            let result = try? await self.export(root, actions: actions)
            XCTAssertNotNil(result)
            if let result {
                let context = ArticleCopyContext.exported(jobID: result.jobID, projectID: result.projectID)
                try await actions.copyPlainText(result.fixedPlainText, context: context)
                XCTAssertEqual(board.string(forType: .string), result.fixedPlainText)
                do { try await actions.copyPlainText("別本文", context: context); XCTFail() } catch { XCTAssertEqual(error as? ArticleFailure, .invalidInput) }
            }
        }
    }
    func testMissingFolderDoesNotInvokeFinder() async throws {
        try await fixture { root, board, delivery in
            var opens = 0
            let actions = ArticleExportOSActions(delivery: delivery, pasteboard: board, open: { _ in opens += 1; return true })
            let result = try? await self.export(root, actions: actions)
            XCTAssertNotNil(result)
            if let result {
                try FileManager.default.removeItem(at: result.directory)
                do { try await actions.revealExport(result); XCTFail() } catch { XCTAssertEqual(error as? ArticleExportOSFailure, .finderFailure) }
                XCTAssertEqual(opens, 0)
            }
        }
    }
    func testFinderFailureDoesNotRemoveSuccessfulOutput() async throws {
        try await fixture { root, board, delivery in
            let actions = ArticleExportOSActions(delivery: delivery, pasteboard: board, open: { _ in false })
            let result = try? await self.export(root, actions: actions)
            XCTAssertNotNil(result)
            if let result {
                do { try await actions.revealExport(result); XCTFail() } catch { XCTAssertEqual(error as? ArticleExportOSFailure, .finderFailure) }
                XCTAssertTrue(FileManager.default.fileExists(atPath: result.directory.appendingPathComponent("article.md").path))
            }
        }
    }
    func testUnregisteredGrantCannotWrite() async throws {
        try await fixture { root, board, delivery in
            let actions = ArticleExportOSActions(delivery: delivery, pasteboard: board), prepared = try ExportFixture.prepared()
            do { _ = try await actions.runExport(jobID: UUID(), savedInput: prepared.savedInput, rendered: prepared.rendered, destination: ArticleExportDestination(grantID: UUID(), selectedDirectory: root)) { _ in }; XCTFail() }
            catch { XCTAssertEqual(error as? ArticleFailure, .permissionDenied) }
        }
    }
    func testScopeIsReleasedExactlyOnceOnSuccessAndMismatch() async throws {
        try await fixture { root, board, delivery in
            let actions = ArticleExportOSActions(delivery: delivery, pasteboard: board), prepared = try ExportFixture.prepared()
            var stops = 0
            let access = ArticleExportDestinationAccess(url: root, start: { true }, stop: { stops += 1 })
            let destination = actions.register(access)
            _ = try? await actions.runExport(jobID: UUID(), savedInput: prepared.savedInput, rendered: prepared.rendered, destination: destination) { _ in }
            XCTAssertEqual(stops, 1)
            actions.releaseDestination(destination); access.release()
            XCTAssertEqual(stops, 1)
            let another = ArticleExportDestinationAccess(url: root, start: { false }, stop: { stops += 1 })
            actions.releaseDestination(actions.register(another)); another.release()
            XCTAssertEqual(stops, 1)
        }
    }
}
