import XCTest

final class ArticleFoundationUITests: XCTestCase {
    override func setUpWithError() throws {continueAfterFailure=false}
    @MainActor private func launch() -> XCUIApplication {
        let app=FixtureLaunch.article(test:self)
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout:10),app.debugDescription)
        return app
    }
    @MainActor private func open(_ app: XCUIApplication) {
        app.activate()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout:10),app.debugDescription)
        let entry=app.buttons["article-open"]
        XCTAssertTrue(entry.waitForExistence(timeout:10),app.debugDescription)
        entry.click()
        XCTAssertTrue(app.textFields["article-title"].waitForExistence(timeout: 5))
    }
    @MainActor func testStartShowsFourBodyFields() { let app = launch(); open(app); for index in 1...4 { XCTAssertTrue(app.textViews["article-photo-\(index)"].exists) } }
    @MainActor func testJapaneseTitleAndManualSave() {
        let app = launch(); open(app)
        let title = app.textFields["article-title"]; title.click(); title.typeKey("a", modifierFlags: .command); title.typeText("日本語の記事")
        app.buttons["article-save"].click()
        XCTAssertTrue(app.staticTexts["下書きを保存しました。"].waitForExistence(timeout: 5))
    }
    @MainActor func testSavedTitleSurvivesRelaunch() {
        let app = launch(); open(app)
        let title = app.textFields["article-title"]; title.click(); title.typeKey("a", modifierFlags: .command); title.typeText("再開する文章")
        app.buttons["article-save"].click(); XCTAssertTrue(app.staticTexts["下書きを保存しました。"].waitForExistence(timeout: 5))
        app.terminate(); app.launch(); open(app)
        XCTAssertEqual(app.textFields["article-title"].stringValue, "再開する文章")
    }
    @MainActor func testTextOpensWithoutPhotoPreview() {
        let app=launch(); open(app)
        XCTAssertTrue(app.staticTexts["article-preview-state-2"].waitForExistence(timeout:5))
        XCTAssertTrue(app.textViews["article-introduction"].exists)
        app.textViews["article-introduction"].click(); app.textViews["article-introduction"].typeText("写真なしでも文章を保持")
        app.buttons["article-save"].click()
    }
    @MainActor func testUnsavedLeaveCanContinueEditing() {
        let app = launch(); open(app); app.textFields["article-title"].click(); app.textFields["article-title"].typeText("変更")
        app.buttons["article-back"].click()
        let sheet=app.sheets.firstMatch, dialog=app.dialogs.firstMatch
        let confirmation:XCUIElement
        if sheet.waitForExistence(timeout:5) {confirmation=sheet}
        else {XCTAssertTrue(dialog.waitForExistence(timeout:5)); confirmation=dialog}
        confirmation.buttons["編集を続ける"].click()
        XCTAssertTrue(confirmation.waitForNonExistence(timeout:5))
        XCTAssertTrue(app.textFields["article-title"].exists); XCTAssertTrue(app.textFields["article-title"].isEnabled)
    }
    @MainActor func testOneImageExportReportsSuccess() {
        let app = launch(); open(app); app.typeKey("e",modifierFlags:[.command,.shift])
        XCTAssertTrue(app.staticTexts["画像1枚の検証出力が完了しました。"].waitForExistence(timeout: 10))
    }
}
private extension XCUIElement { var stringValue: String { value as? String ?? "" } }
