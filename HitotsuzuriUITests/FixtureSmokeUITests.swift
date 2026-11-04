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
        XCTAssertTrue(entry.waitForExistence(timeout:10),app.debugDescription)
        XCTAssertTrue(entry.isEnabled); XCTAssertTrue(entry.isHittable)
    }
}
