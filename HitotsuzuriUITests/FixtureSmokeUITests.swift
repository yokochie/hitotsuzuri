import XCTest

@MainActor final class FixtureSmokeUITests:XCTestCase {
    override func setUpWithError() throws {continueAfterFailure=false}
    func testArticleFixtureWindowAndEntryAreReady() {
        let app=FixtureLaunch.article(test:self,fixture:"default")
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout:10),app.debugDescription)
        let button=app.buttons["article-open"]
        XCTAssertTrue(button.waitForExistence(timeout:10),app.debugDescription)
        let ready=NSPredicate {_,_ in MainActor.assumeIsolated {button.isEnabled && button.isHittable}}
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:ready,object:nil)],timeout:8),.completed)
    }
    func testPickerFixtureWindowAndFolderEntryAreReady() {
        let app=FixtureLaunch.picker(test:self)
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout:10),app.debugDescription)
        let entry=app.staticTexts["テスト親A"]
        let switcher=app.radioGroups["region-picker"]
        if !entry.exists && !switcher.exists {
            let ready=NSPredicate {_,_ in MainActor.assumeIsolated {entry.exists || switcher.exists}}
            XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:ready,object:nil)],timeout:10),.completed)
        }
        // 狭幅ではフォルダ以外の領域も表示できるため、既存の領域操作で入口へ移る。
        if switcher.exists {
            let folders=switcher.radioButtons["フォルダ"]
            XCTAssertTrue(folders.isEnabled); XCTAssertTrue(folders.isHittable)
            folders.click()
        }
        XCTAssertTrue(entry.waitForExistence(timeout:10),app.debugDescription)
        XCTAssertTrue(entry.isEnabled); XCTAssertTrue(entry.isHittable)
    }
}
