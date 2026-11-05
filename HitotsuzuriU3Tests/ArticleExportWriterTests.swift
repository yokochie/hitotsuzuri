import XCTest
@testable import HitotsuzuriCore

@MainActor final class ArticleExportWriterTests: XCTestCase {
    private var root: URL!
    override func setUpWithError() throws {
        root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".build/export-writer-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: root) }
    private func record() throws -> ArticleExportRecoveryRecord {
        try ArticleExportRecoveryRecord(jobID: UUID(), prepared: ExportFixture.prepared(), parentIdentity: ArticleExportFileSystem.identity(of: root))
    }
    private func fill(_ writer: ArticleExportWriter) async throws -> ArticleExportRecoveryRecord {
        _ = try await writer.prepare()
        for index in 1...4 { _ = try await writer.writeImage(ExportFixture.jpeg(), index: index) }
        return try await writer.seal()
    }
    private func expectFailure(_ operation: () async throws -> Void) async {
        do { try await operation(); XCTFail("危険な操作を成功扱いした") } catch { }
    }
    func testPublishesCompleteSixFilesAndNoReceipt() async throws {
        let value = try record(); let writer = ArticleExportWriter(destination: root, record: value)
        let sealed = try await fill(writer), final = try await writer.publish()
        XCTAssertEqual(Set(sealed.expectedDigests.keys), ArticleExportLayout.artifactPaths)
        for path in ArticleExportLayout.artifactPaths { XCTAssertTrue(FileManager.default.fileExists(atPath: final.appendingPathComponent(path).path), path) }
        XCTAssertFalse(FileManager.default.fileExists(atPath: final.appendingPathComponent("owner.json").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(value.stagingName).path))
    }
    func testExistingFinalIsNeverReplaced() async throws {
        let value = try record(); let old = root.appendingPathComponent(value.finalName)
        try FileManager.default.createDirectory(at: old, withIntermediateDirectories: false)
        try Data("old".utf8).write(to: old.appendingPathComponent("old"))
        let writer = ArticleExportWriter(destination: root, record: value)
        _ = try await fill(writer)
        await expectFailure { _ = try await writer.publish() }
        XCTAssertEqual(try String(contentsOf: old.appendingPathComponent("old"), encoding: .utf8), "old")
    }
    func testMissingFourthImageCannotSeal() async throws {
        let writer = ArticleExportWriter(destination: root, record: try record())
        _ = try await writer.prepare()
        for index in 1...3 { _ = try await writer.writeImage(ExportFixture.jpeg(), index: index) }
        await expectFailure { _ = try await writer.seal() }
    }
    func testNonJPEGAndWrongSequenceAreRejected() async throws {
        let writer = ArticleExportWriter(destination: root, record: try record())
        _ = try await writer.prepare()
        await expectFailure { _ = try await writer.writeImage(ArticleJPEG(bytes: Data("bad".utf8), width: 2, height: 2), index: 1) }
        await expectFailure { _ = try await writer.writeImage(ExportFixture.jpeg(), index: 2) }
    }
    func testInjectedCapacityAndPermissionAreReported() async throws {
        for failure in [ArticleFailure.capacity, .permissionDenied] {
            let writer = ArticleExportWriter(destination: root, record: try record(), checkpoint: { point in if point == .beforeImage(1) { throw failure } })
            _ = try await writer.prepare()
            do { _ = try await writer.writeImage(ExportFixture.jpeg(), index: 1); XCTFail("障害を無視した") } catch { XCTAssertEqual(error as? ArticleFailure, failure) }
            try await writer.cleanup()
        }
    }
    func testDirectoryReplacementAfterValidationIsNotPublishedOrDeleted() async throws {
        try await checkReplacement(at: .afterValidation, symlink: false)
    }
    func testSymlinkReplacementAfterLastCheckIsNotAcceptedOrDeleted() async throws {
        try await checkReplacement(at: .beforeRename, symlink: true)
    }
    func testFinalReplacementAfterRenameIsNotAcceptedOrDeleted() async throws {
        try await checkReplacement(at: .afterRename, symlink: false)
    }
    private func checkReplacement(at attackPoint: ArticleExportCheckpoint, symlink: Bool) async throws {
        let value = try record(), base = root!
        let name = attackPoint == .afterRename ? value.finalName : value.stagingName
        let target = base.appendingPathComponent(name), moved = base.appendingPathComponent("preserved-original")
        let writer = ArticleExportWriter(destination: base, record: value, checkpoint: { point in
            guard point == attackPoint else { return }
            try FileManager.default.moveItem(at: target, to: moved)
            if symlink { try FileManager.default.createSymbolicLink(at: target, withDestinationURL: moved) }
            else {
                try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)
                try Data("foreign".utf8).write(to: target.appendingPathComponent("foreign"))
            }
        })
        _ = try await writer.prepare()
        for index in 1...4 { _ = try await writer.writeImage(ExportFixture.jpeg(), index: index) }
        await expectFailure { _ = try await writer.seal(); _ = try await writer.publish() }
        await expectFailure { try await writer.cleanup() }
        XCTAssertTrue(FileManager.default.fileExists(atPath: moved.path))
        if symlink {
            let preserved = FileManager.default.fileExists(atPath: target.path) ? target : base.appendingPathComponent(value.finalName)
            XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: preserved.path), moved.path)
        }
        else { XCTAssertEqual(try String(contentsOf: target.appendingPathComponent("foreign"), encoding: .utf8), "foreign") }
    }
    func testSameDirectoryContentTamperingIsNotAccepted() async throws {
        let value = try record(), path = root.appendingPathComponent(value.stagingName).appendingPathComponent("article.md")
        let writer = ArticleExportWriter(destination: root, record: value, checkpoint: { point in
            if point == .beforeRename { try Data("foreign".utf8).write(to: path) }
        })
        _ = try await fill(writer)
        await expectFailure { _ = try await writer.publish() }
        let preserved = FileManager.default.fileExists(atPath: path.path) ? path : root.appendingPathComponent(value.finalName).appendingPathComponent("article.md")
        XCTAssertEqual(try String(contentsOf: preserved, encoding: .utf8), "foreign")
    }
    func testCleanupProtectsUnknownFiles() async throws {
        let value = try record(); let writer = ArticleExportWriter(destination: root, record: value)
        _ = try await writer.prepare()
        let unknown = root.appendingPathComponent(value.stagingName).appendingPathComponent("foreign")
        if FileManager.default.fileExists(atPath: unknown.deletingLastPathComponent().path) { try Data("foreign".utf8).write(to: unknown) }
        await expectFailure { try await writer.cleanup() }
        XCTAssertTrue(FileManager.default.fileExists(atPath: unknown.path))
    }
    func testCleanupRemovesOnlyOwnedPartialOutput() async throws {
        let value = try record(); let writer = ArticleExportWriter(destination: root, record: value)
        _ = try await writer.prepare(); _ = try await writer.writeImage(ExportFixture.jpeg(), index: 1)
        let stage = root.appendingPathComponent(value.stagingName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: stage.path))
        try await writer.cleanup()
        XCTAssertFalse(FileManager.default.fileExists(atPath: stage.path))
    }
    private func assertUnproducedFileProtected(_ relative: String, partial: Bool = false) async throws {
        let value = try record(), writer = ArticleExportWriter(destination: root, record: value)
        _ = try await writer.prepare()
        let path = root.appendingPathComponent(value.stagingName).appendingPathComponent(relative)
        let bytes = partial ? Data(try ExportFixture.jpeg().bytes.prefix(17)) : Data("external known name".utf8)
        try bytes.write(to: path)
        do { try await writer.cleanup(); XCTFail("未記録bytesを削除した") }
        catch { XCTAssertEqual(error as? ArticleFailure, .cleanupFailure) }
        XCTAssertTrue(FileManager.default.fileExists(atPath: path.path))
        if FileManager.default.fileExists(atPath: path.path) { XCTAssertEqual(try Data(contentsOf: path), bytes) }
    }
    func testCleanupProtectsUnproducedFourthImage() async throws { try await assertUnproducedFileProtected("images/04.jpg") }
    func testCleanupProtectsUnproducedArticle() async throws { try await assertUnproducedFileProtected("article.md") }
    func testCleanupProtectsUnproducedManifest() async throws { try await assertUnproducedFileProtected("manifest.json") }
    func testCleanupProtectsUnrecordedPartialImageBytes() async throws { try await assertUnproducedFileProtected("images/01.jpg", partial: true) }
    func testCleanupProtectsChangedProducedImageBytes() async throws {
        let value = try record(), writer = ArticleExportWriter(destination: root, record: value)
        _ = try await writer.prepare(); _ = try await writer.writeImage(ExportFixture.jpeg(), index: 1)
        let path = root.appendingPathComponent(value.stagingName).appendingPathComponent("images/01.jpg"), changed = Data("changed".utf8)
        try changed.write(to: path)
        do { try await writer.cleanup(); XCTFail("変更済みbytesを削除した") } catch { XCTAssertEqual(error as? ArticleFailure, .cleanupFailure) }
        XCTAssertEqual(try Data(contentsOf: path), changed)
    }
    func testSealConflictCleanupPreservesExternalArticleAndManifest() async throws {
        for relative in ["article.md", "manifest.json"] {
            let value = try record(), writer = ArticleExportWriter(destination: root, record: value)
            _ = try await writer.prepare()
            for index in 1...4 { _ = try await writer.writeImage(ExportFixture.jpeg(), index: index) }
            let path = root.appendingPathComponent(value.stagingName).appendingPathComponent(relative), external = Data("external conflict".utf8)
            try external.write(to: path)
            do { _ = try await writer.seal(); XCTFail("排他生成が既存物を受け入れた") } catch { XCTAssertEqual(error as? ArticleFailure, .conflict) }
            do { try await writer.cleanup(); XCTFail("conflict後に外部物を削除した") } catch { XCTAssertEqual(error as? ArticleFailure, .cleanupFailure) }
            XCTAssertTrue(FileManager.default.fileExists(atPath: path.path))
            if FileManager.default.fileExists(atPath: path.path) { XCTAssertEqual(try Data(contentsOf: path), external) }
        }
    }
    func testWrongParentAndSymlinkAreRejected() async throws {
        var value = try record()
        value = ArticleExportRecoveryRecord(jobID: value.jobID, prepared: try ExportFixture.prepared(), parentIdentity: ExportFixture.identity)
        let writer = ArticleExportWriter(destination: root, record: value)
        await expectFailure { _ = try await writer.prepare() }
    }
    func testFailureAfterRenamePreservesAndReconcilesExactOutput() async throws {
        let value = try record()
        let writer = ArticleExportWriter(destination: root, record: value, checkpoint: { point in if point == .afterRename { throw ArticleFailure.ioFailure } })
        let sealed = try await fill(writer)
        do { _ = try await writer.publish(); XCTFail("確定応答不明を成功にした") } catch { XCTAssertEqual(error as? ArticleFailure, .uncertainResult) }
        let restored = ArticleExportWriter(destination: root, record: sealed)
        let result = try await restored.reconcile()
        XCTAssertEqual(result, root.appendingPathComponent(value.finalName, isDirectory: true))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(value.finalName).appendingPathComponent("article.md").path))
    }
    func testInjectedCleanupFailureLeavesOwnedFiles() async throws {
        let value = try record()
        let writer = ArticleExportWriter(destination: root, record: value, checkpoint: { point in if point == .beforeCleanup { throw ArticleFailure.cleanupFailure } })
        _ = try await writer.prepare()
        do { try await writer.cleanup(); XCTFail("片付け失敗を無視した") } catch { XCTAssertEqual(error as? ArticleFailure, .cleanupFailure) }
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(value.stagingName).path))
    }
    func testParentPathReplacementCannotReturnForeignLocationAsSuccess() async throws {
        let value = try record(), base = root!, moved = root.appendingPathExtension("moved")
        defer { try? FileManager.default.removeItem(at: moved) }
        let writer = ArticleExportWriter(destination: base, record: value, checkpoint: { point in
            guard point == .afterRename else { return }
            try FileManager.default.moveItem(at: base, to: moved)
            try FileManager.default.createDirectory(at: base, withIntermediateDirectories: false)
            try Data("foreign parent".utf8).write(to: base.appendingPathComponent("foreign"))
        })
        _ = try await fill(writer)
        await expectFailure { _ = try await writer.publish() }
        XCTAssertEqual(try String(contentsOf: base.appendingPathComponent("foreign"), encoding: .utf8), "foreign parent")
        XCTAssertTrue(FileManager.default.fileExists(atPath: moved.appendingPathComponent(value.finalName).appendingPathComponent("article.md").path))
    }
}
