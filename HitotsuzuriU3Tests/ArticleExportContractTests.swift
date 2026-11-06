import XCTest
@testable import HitotsuzuriCore

final class ArticleExportContractTests: XCTestCase {
    func testAcceptsSavedC3Projection() throws {
        let article = try makeArticle()
        let rendered = try ArticleProjectionContext(projectID: article.projectID).renderArticle(source: article.source, content: article.content)
        let prepared = try PreparedArticleExport(savedInput: SavedExportInput(article: article), rendered: rendered)
        XCTAssertEqual(prepared.savedInput.article, article)
        XCTAssertEqual(prepared.rendered.imagePaths, ["images/01.jpg", "images/02.jpg", "images/03.jpg", "images/04.jpg"])
    }
    func testRejectsFingerprintMismatch() throws {
        let article = try makeArticle()
        var content = article.content
        content.introduction = "別の内容"
        let rendered = try ArticleProjectionContext(projectID: article.projectID).renderArticle(source: article.source, content: content)
        XCTAssertThrowsError(try PreparedArticleExport(savedInput: SavedExportInput(article: article), rendered: rendered))
    }
    func testRejectsDifferentProjectProjection() throws {
        let article = try makeArticle()
        let rendered = try ArticleProjectionContext(projectID: UUID()).renderArticle(source: article.source, content: article.content)
        XCTAssertThrowsError(try PreparedArticleExport(savedInput: SavedExportInput(article: article), rendered: rendered))
    }
    private func makeArticle() throws -> SavedArticle {
        let selection = CommittedSelection(albumID: "album", albumTitle: "テスト", orderedAssetIDs: ["a", "b", "c", "d"], confirmedAt: Date())
        let source = try ArticleSource(selection: selection)
        return try SavedArticle(projectID: UUID(), source: source, content: ArticleContent(source: source))
    }
}
