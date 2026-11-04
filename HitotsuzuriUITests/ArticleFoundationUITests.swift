import XCTest

final class ArticleFoundationUITests: XCTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--article-test-fixture", "--article-test-root", "ui-article-" + name.replacingOccurrences(of: "/", with: "-")]
        app.launch(); return app
    }
    private func open(_ app: XCUIApplication) {
        app.buttons["article-open"].click()
        XCTAssertTrue(app.textFields["article-title"].waitForExistence(timeout: 5))
    }
    func testStartShowsFourBodyFields() { let app = launch(); open(app); for index in 1...4 { XCTAssertTrue(app.textViews["article-photo-\(index)"].exists) } }
    func testJapaneseTitleAndManualSave() {
        let app = launch(); open(app)
        let title = app.textFields["article-title"]; title.click(); title.typeKey("a", modifierFlags: .command); title.typeText("日本語の記事")
        app.buttons["article-save"].click()
        XCTAssertTrue(app.staticTexts["下書きを保存しました。"].waitForExistence(timeout: 5))
    }
    func testSavedTitleSurvivesRelaunch() {
        let app = launch(); open(app)
        let title = app.textFields["article-title"]; title.click(); title.typeKey("a", modifierFlags: .command); title.typeText("再開する文章")
        app.buttons["article-save"].click(); XCTAssertTrue(app.staticTexts["下書きを保存しました。"].waitForExistence(timeout: 5))
        app.terminate(); app.launch(); open(app)
        XCTAssertEqual(app.textFields["article-title"].stringValue, "再開する文章")
    }
    func testTextOpensWithoutPhotoPreview() { let app = launch(); open(app); XCTAssertTrue(app.textViews["article-introduction"].exists) }
    func testUnsavedLeaveCanContinueEditing() {
        let app = launch(); open(app); app.textFields["article-title"].click(); app.textFields["article-title"].typeText("変更")
        app.buttons["article-back"].click(); XCTAssertTrue(app.dialogs.firstMatch.waitForExistence(timeout: 5))
        app.buttons["編集を続ける"].click(); XCTAssertTrue(app.textFields["article-title"].exists)
    }
    func testOneImageExportReportsSuccess() {
        let app = launch(); open(app); app.buttons["article-probe"].click()
        XCTAssertTrue(app.staticTexts["画像1枚の検証出力が完了しました。"].waitForExistence(timeout: 10))
    }
}
private extension XCUIElement { var stringValue: String { value as? String ?? "" } }
