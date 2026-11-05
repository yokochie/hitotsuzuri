import XCTest

@MainActor final class ArticleExportUITests: ArticleDraftUITestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private func action(_ id: String, _ app: XCUIApplication) -> XCUIElement {
        let button = app.buttons[id]
        XCTAssertTrue(button.draftExists(timeout: 5), app.debugDescription)
        func visible() -> Bool {
            let frame = button.frame, viewport = app.scrollViews.firstMatch.frame
            return button.isHittable && frame.minY >= viewport.minY + 3 && frame.maxY <= viewport.maxY - 3
        }
        for _ in 0..<35 {
            if visible() { break }
            let frame = button.frame, viewport = app.scrollViews.firstMatch.frame
            scrollForm(app, delta: frame.midY > viewport.midY ? -350 : 350)
        }
        XCTAssertTrue(visible(), "操作ボタン全体がviewport内に見える: \(id)"); return button
    }
    private func completed(_ app: XCUIApplication) -> XCUIElement {
        let result = app.staticTexts["article-export-result"]
        XCTAssertTrue(result.draftExists(timeout: 10), app.debugDescription)
        return result
    }
    private func displayedText(_ element: XCUIElement) -> String {
        guard element.exists else { return "" }
        return element.label + " " + ((element.value as? String) ?? "")
    }
    func testUnsavedExportConfirmationCanCancelWithoutSaving() {
        let app = launch(); replace(field("article-title", app), "Unsaved export text")
        action("article-export", app).click()
        let dialog = confirmation(app); dialog.buttons["取り消す"].click()
        XCTAssertTrue(dialog.draftAbsent(timeout: 5)); XCTAssertTrue(state(app, contains: "未保存").exists)
        XCTAssertFalse(app.staticTexts["article-export-result"].exists)
    }
    func testFourImageExportCompletesAndKeepsProbeSeparate() {
        let app = launch()
        action("article-export", app).click(); _ = completed(app)
        XCTAssertTrue(app.buttons["article-export-copy-fixed"].exists)
        XCTAssertTrue(app.buttons["article-export-reveal"].exists)
        XCTAssertTrue(app.buttons["article-probe"].exists)
        XCTAssertTrue(app.buttons["article-export"].isEnabled)
    }
    func testUnavailableImageKeepsDraftAndCopyAvailable() {
        let app = launch("export-failure")
        action("article-export", app).click()
        let failure = app.staticTexts["article-export-message"]
        let ready = NSPredicate { _, _ in MainActor.assumeIsolated { self.displayedText(failure).contains("写真 2") && self.displayedText(failure).contains("取得") } }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: nil)], timeout: 10), .completed)
        XCTAssertTrue(app.buttons["article-copy"].isEnabled); XCTAssertFalse(app.staticTexts["article-export-result"].exists)
        XCTAssertEqual(field("article-title", app).value as? String, "合成")
    }
    func testCancelWaitsAndCleanupFailureIsShownSeparately() {
        let app = launch("export-slow")
        action("article-export", app).click()
        let cancel = action("article-export-cancel", app); cancel.click()
        XCTAssertTrue(cancel.draftAbsent(timeout: 10)); XCTAssertFalse(app.staticTexts["article-export-result"].exists)
        let other = launch("export-cleanup")
        action("article-export", other).click()
        XCTAssertTrue(other.buttons["article-export-recover"].draftExists(timeout: 10))
        XCTAssertFalse(other.staticTexts["article-export-result"].exists)
    }
    func testFixedCompletionCopyDoesNotUseLaterEditorChanges() {
        let app = launch(); replace(field("article-title", app), "Fixed output text")
        XCTAssertEqual(field("article-title", app).value as? String, "Fixed output text")
        app.buttons["article-save"].click(); XCTAssertTrue(state(app, contains: "保存しました").draftExists(timeout: 5))
        action("article-export", app).click(); _ = completed(app)
        replace(field("article-title", app), "Later unsaved text")
        XCTAssertEqual(field("article-title", app).value as? String, "Later unsaved text")
        action("article-export-copy-fixed", app).click()
        let copied = app.staticTexts["article-export-fixture-copy"]
        XCTAssertTrue(copied.draftExists(timeout: 5)); XCTAssertTrue(displayedText(copied).contains("Fixed output text")); XCTAssertFalse(displayedText(copied).contains("Later unsaved text"))
        XCTAssertTrue(state(app, contains: "未保存").exists)
    }
    func testFinderFailureKeepsSuccessfulResult() {
        let app = launch("export-finder-failure")
        action("article-export", app).click(); _ = completed(app)
        action("article-export-reveal", app).click()
        let message = app.staticTexts["article-export-os-message"]
        let predicate = NSPredicate { _, _ in MainActor.assumeIsolated { self.displayedText(message).contains("Finder") && self.displayedText(message).contains("開けません") } }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: nil)], timeout: 5), .completed)
        XCTAssertTrue(app.staticTexts["article-export-result"].exists)
    }
    func testWidthBoundariesAndKeyboardCanReachExport() {
        let app = launch("long")
        for width in [640, 959, 960, 961, 1200] {
            app.buttons["draft-width-\(width)"].click()
            XCTAssertTrue(action("article-export", app).isEnabled)
            XCTAssertTrue(app.buttons["article-copy"].isEnabled)
        }
        let title = field("article-title", app)
        XCTAssertEqual((title.value as? String)?.count, 200)
        title.click()
        for _ in 0..<21 { app.typeKey(.tab, modifierFlags: []) }
        app.typeKey(.space, modifierFlags: [])
        _ = completed(app)
        XCTAssertTrue(app.buttons["article-export"].isEnabled)
    }
    func testRestartShowsRecoveryAndRequiresExplicitCleanup() {
        let app = launch("export-cleanup")
        action("article-export", app).click()
        XCTAssertTrue(app.buttons["article-export-recover"].draftExists(timeout: 10))
        app.terminate(); app.launch(); app.buttons["article-open"].click()
        let recover = action("article-export-recover", app); recover.click()
        XCTAssertTrue(app.buttons["article-export-cleanup"].draftExists(timeout: 5))
        XCTAssertFalse(app.staticTexts["article-export-result"].exists)
    }
}
