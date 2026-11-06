import XCTest
@testable import HitotsuzuriCore

final class ArticleProbeTests: XCTestCase {
    func testCapacityAtEachPrecommitWriteKeepsOldOutput() async throws {
        let root=ArticleFixtures.root(), article=try await ArticleFixtures.create(ArticlePersistence(directory:ArticleFixtures.root())), image=try ArticleImageConverter.convert(ArticleImageFixture.make(width:30,height:20))
        let old=try await ArticleProbeDelivery().write(article:article,image:image,destination:root,jobID:UUID()), original=try Data(contentsOf:old.directory.appendingPathComponent("01.jpg"))
        for point in [ArticleProbeCheckpoint.beforeReceipt,.beforeImage,.beforeCommit] {
            let delivery=ArticleProbeDelivery(checkpoint:{if $0 == point {throw ArticleFailure.capacity}})
            do {_ = try await delivery.write(article:article,image:image,destination:root,jobID:UUID()); XCTFail()}
            catch {XCTAssertEqual(error as? ArticleFailure,.capacity)}
            XCTAssertEqual(try Data(contentsOf:old.directory.appendingPathComponent("01.jpg")),original)
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:root.path),[old.directory.lastPathComponent])
        }
    }
    func testOutputRenameSyncFailureIsUncertainAndRecoverable() async throws {
        let root=ArticleFixtures.root(), id=UUID(), article=try await ArticleFixtures.create(ArticlePersistence(directory:ArticleFixtures.root())), image=try ArticleImageConverter.convert(ArticleImageFixture.make(width:30,height:20))
        let delivery=ArticleProbeDelivery(checkpoint:{if $0 == .renamedBeforeSync {throw ArticleFailure.ioFailure}})
        do {_ = try await delivery.write(article:article,image:image,destination:root,jobID:id); XCTFail()}
        catch {XCTAssertEqual(error as? ArticleFailure,.uncertainResult)}
        let recovered=try await ArticleProbeDelivery().reconcile(jobID:id,projectID:article.projectID,fingerprint:article.fingerprint,destination:root)
        XCTAssertNotNil(recovered)
    }
    func testIncompleteFinalDoesNotClearPendingRecord() async throws {
        let root=ArticleFixtures.root(), article=try await ArticleFixtures.create(ArticlePersistence(directory:ArticleFixtures.root())), id=UUID()
        let journal=ArticleProbeJournal(directory:ArticleFixtures.root()); try await journal.begin(jobID:id,article:article,destination:root)
        let image=try ArticleImageConverter.convert(ArticleImageFixture.make(width:30,height:20)), delivery=ArticleProbeDelivery()
        let output=try await delivery.write(article:article,image:image,destination:root,jobID:id)
        try FileManager.default.removeItem(at:output.directory.appendingPathComponent("01.jpg"))
        do {_ = try await delivery.reconcile(jobID:id,projectID:article.projectID,fingerprint:article.fingerprint,destination:root); XCTFail()}
        catch {XCTAssertEqual(error as? ArticleFailure,.corruptData)}
        let pending=try await journal.pending(); XCTAssertEqual(pending?.jobID,id)
        XCTAssertTrue(FileManager.default.fileExists(atPath:output.directory.path))
    }
    func testCleanupPermissionFailurePreservesTemporaryLocation() async throws {
        let root=ArticleFixtures.root(), id=UUID(), temporary=root.appendingPathComponent(".article-probe-"+id.uuidString)
        let article=try await ArticleFixtures.create(ArticlePersistence(directory:ArticleFixtures.root())), image=try ArticleImageConverter.convert(ArticleImageFixture.make(width:30,height:20))
        let delivery=ArticleProbeDelivery(checkpoint:{point in
            if point == .beforeCommit {try FileManager.default.setAttributes([.posixPermissions:0o500],ofItemAtPath:temporary.path); throw ArticleFailure.cancelled}
        })
        defer {try? FileManager.default.setAttributes([.posixPermissions:0o700],ofItemAtPath:temporary.path)}
        do {_ = try await delivery.write(article:article,image:image,destination:root,jobID:id); XCTFail()}
        catch {XCTAssertEqual(error as? ArticleFailure,.cleanupFailure)}
        XCTAssertTrue(FileManager.default.fileExists(atPath:temporary.appendingPathComponent("01.jpg").path))
    }
    func testResponseLossAfterOutputCommitReturnsCommittedResult() async throws {
        let root=ArticleFixtures.root(), article=try await ArticleFixtures.create(ArticlePersistence(directory:ArticleFixtures.root())), image=try ArticleImageConverter.convert(ArticleImageFixture.make(width:30,height:20))
        let result=try await ArticleProbeDelivery(checkpoint:{if $0 == .afterCommit {throw ArticleFailure.ioFailure}}).write(article:article,image:image,destination:root,jobID:UUID())
        XCTAssertTrue(FileManager.default.fileExists(atPath:result.directory.appendingPathComponent("01.jpg").path))
    }
    func testUnknownTemporaryDirectoryIsNotDeleted() async throws {
        let root=ArticleFixtures.root(), id=UUID(), temporary=root.appendingPathComponent(".article-probe-"+id.uuidString)
        try FileManager.default.createDirectory(at:temporary,withIntermediateDirectories:true)
        let unrelated=temporary.appendingPathComponent("unrelated"); try Data("preserve".utf8).write(to:unrelated)
        let article=try await ArticleFixtures.create(ArticlePersistence(directory:ArticleFixtures.root())), image=try ArticleImageConverter.convert(ArticleImageFixture.make(width:30,height:20))
        do {_ = try await ArticleProbeDelivery().write(article:article,image:image,destination:root,jobID:id); XCTFail()}
        catch {XCTAssertEqual(error as? ArticleFailure,.conflict)}
        XCTAssertEqual(try Data(contentsOf:unrelated),Data("preserve".utf8))
    }
    func testPendingJobSurvivesRestartWithoutDestinationGrant() async throws {
        let root=ArticleFixtures.root(), article=try await ArticleFixtures.create(ArticlePersistence(directory:ArticleFixtures.root())), id=UUID(), destination=ArticleFixtures.root()
        let journal=ArticleProbeJournal(directory:root)
        try await journal.begin(jobID:id,article:article,destination:destination)
        let pending=try await ArticleProbeJournal(directory:root).pending()
        XCTAssertEqual(pending?.jobID,id); XCTAssertEqual(pending?.destinationPath,destination.path)
        try await journal.finish(jobID:id)
        let finished=try await journal.pending(); XCTAssertNil(finished)
    }
    func testRecoveryUsesStoredJobIdentityAndImageDigest() async throws {
        let root=ArticleFixtures.root(), article=try await ArticleFixtures.create(ArticlePersistence(directory:ArticleFixtures.root())), id=UUID()
        let image=try ArticleImageConverter.convert(ArticleImageFixture.make(width:30,height:20)), delivery=ArticleProbeDelivery()
        let output=try await delivery.write(article:article,image:image,destination:root,jobID:id)
        let recovered=try await ArticleProbeDelivery().reconcile(jobID:id,projectID:article.projectID,fingerprint:article.fingerprint,destination:root)
        XCTAssertEqual(recovered,output)
    }
    func testOneImageCreatesSeparateFolderWithoutArticleSet() async throws {
        let root = ArticleFixtures.root(), image = try ArticleImageConverter.convert(ArticleImageFixture.make(width: 30, height: 20))
        let article = try await ArticleFixtures.create(ArticlePersistence(directory: ArticleFixtures.root()))
        let delivery = ArticleProbeDelivery()
        let result = try await delivery.write(article: article, image: image, destination: root, jobID: UUID())
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.directory.appendingPathComponent("01.jpg").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: result.directory.appendingPathComponent("article.md").path))
    }
    func testRepeatedExportUsesDifferentFolders() async throws {
        let root = ArticleFixtures.root(), image = try ArticleImageConverter.convert(ArticleImageFixture.make(width: 30, height: 20))
        let article = try await ArticleFixtures.create(ArticlePersistence(directory: ArticleFixtures.root())), delivery = ArticleProbeDelivery()
        let a = try await delivery.write(article: article, image: image, destination: root, jobID: UUID())
        let b = try await delivery.write(article: article, image: image, destination: root, jobID: UUID())
        XCTAssertNotEqual(a.directory, b.directory)
    }
    func testSameJobReturnsSameCommittedOutput() async throws {
        let root = ArticleFixtures.root(), image = try ArticleImageConverter.convert(ArticleImageFixture.make(width: 30, height: 20)), id = UUID()
        let article = try await ArticleFixtures.create(ArticlePersistence(directory: ArticleFixtures.root())), delivery = ArticleProbeDelivery()
        let a = try await delivery.write(article: article, image: image, destination: root, jobID: id)
        let b = try await delivery.write(article: article, image: image, destination: root, jobID: id)
        XCTAssertEqual(a, b)
    }
    func testCancelBeforeCommitKeepsOldOutput() async throws {
        let root = ArticleFixtures.root(), image = try ArticleImageConverter.convert(ArticleImageFixture.make(width: 30, height: 20))
        let article = try await ArticleFixtures.create(ArticlePersistence(directory: ArticleFixtures.root()))
        let delivery = ArticleProbeDelivery(checkpoint: { if $0 == .beforeCommit { throw ArticleFailure.cancelled } })
        do { _ = try await delivery.write(article: article, image: image, destination: root, jobID: UUID()); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .cancelled) }
        let remaining = try FileManager.default.contentsOfDirectory(atPath: root.path)
        XCTAssertTrue(remaining.isEmpty)
    }
    func testSymlinkDestinationIsRejected() async throws {
        let target = ArticleFixtures.root(), link = ArticleFixtures.root()
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
        let image = try ArticleImageConverter.convert(ArticleImageFixture.make(width: 30, height: 20)), article = try await ArticleFixtures.create(ArticlePersistence(directory: ArticleFixtures.root()))
        do { _ = try await ArticleProbeDelivery().write(article: article, image: image, destination: link, jobID: UUID()); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .invalidReference) }
    }
    func testCorruptImageResultIsNotSuccessfulOutput() async throws {
        let article = try await ArticleFixtures.create(ArticlePersistence(directory: ArticleFixtures.root()))
        let image = ArticleJPEG(bytes: Data("broken".utf8), width: 30, height: 20)
        do { _ = try await ArticleProbeDelivery().write(article: article, image: image, destination: ArticleFixtures.root(), jobID: UUID()); XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .invalidInput) }
    }
}
