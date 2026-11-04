import XCTest
@testable import HitotsuzuriCore

final class ArticleProbeTests: XCTestCase {
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
