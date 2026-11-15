import XCTest

@MainActor final class ArticleSandboxStorageUITests: ArticleDraftUITestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testArticleCanStartSaveAndReopenInApplicationSupport() {
        let app = FixtureLaunch.article(test: self, fixture: "default", storage: .applicationSupport)
        let storageMarker = app.staticTexts["試験保存領域：Application Support"]
        XCTAssertTrue(storageMarker.draftExists(timeout: 10), "通常APIで解決した隔離Application Supportを選ぶ")
        openArticle(app)
        let title = "Application Support saved article"
        replace(field("article-title", app), title)
        replace(field("article-day", app), "14")
        app.typeKey("s", modifierFlags: .command)
        XCTAssertTrue(state(app, contains: "保存しました").draftExists(timeout: 5))
        let savedIdentity = draftIdentity(app)

        app.terminate()
        app.launch()
        app.activate()
        XCTAssertTrue(storageMarker.draftExists(timeout: 10))
        openArticle(app)
        XCTAssertEqual(field("article-title", app).value as? String, title)
        XCTAssertEqual(field("article-day", app).value as? String, "14")
        for number in 1...4 { XCTAssertTrue(app.staticTexts["article-preview-state-\(number)"].exists) }
        XCTAssertEqual(draftIdentity(app), savedIdentity, "タイトルと日付に加えて、同じ候補のproject識別子で再開する")
        // FixtureLaunchのteardownが同じstorage selector/UUIDでapp内cleanupを実行し、成功表示を確認する。
    }

    private func openArticle(_ app: XCUIApplication) {
        let entry = app.buttons["article-open"]
        XCTAssertTrue(entry.draftExists(timeout: 5))
        let ready = NSPredicate { _, _ in MainActor.assumeIsolated { entry.isEnabled && entry.isHittable } }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: nil)], timeout: 8), .completed)
        entry.click()
        XCTAssertTrue(app.textFields["article-title"].draftExists(timeout: 5))
    }

    private func draftIdentity(_ app: XCUIApplication) -> String {
        app.menuBars.menuBarItems["記事"].click()
        app.menuItems["保存した下書きを開く"].click()
        let picker = draftPicker(app)
        let cancel = picker.buttons["draft-cancel"]
        XCTAssertTrue(cancel.draftExists(timeout: 5))
        XCTAssertEqual(picker.radioButtons.count, 1, "同じ確定選択から記事を重複作成しない")
        let identity = picker.radioButtons.firstMatch.label
        XCTAssertFalse(identity.isEmpty)
        cancel.click()
        XCTAssertTrue(cancel.draftAbsent(timeout: 5))
        return identity
    }
}
