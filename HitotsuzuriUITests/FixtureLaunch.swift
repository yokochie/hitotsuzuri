import XCTest

@MainActor enum FixtureLaunch {
    static let isolationArguments=["-ApplePersistenceIgnoreState","YES","-NSTreatUnknownArgumentsAsOpen","NO"]
    static func article(test:XCTestCase,fixture:String?=nil)->XCUIApplication {
        launch(test:test,flag:"--article-test-fixture",fixture:fixture)
    }
    static func picker(test:XCTestCase)->XCUIApplication {
        launch(test:test,flag:"--ui-test-fixture",fixture:nil)
    }
    private static func launch(test:XCTestCase,flag:String,fixture:String?)->XCUIApplication {
        let token="uitest-"+UUID().uuidString
        let app=XCUIApplication()
        app.launchArguments=[flag]+isolationArguments
        app.launchEnvironment["HZS_ARTICLE_TEST_ROOT"]=token
        app.launchEnvironment["HZS_DRAFT_CASE"]=fixture
        // 同一ケースの再起動ではrootを保持。最後だけapp自身のsandbox内で回収する。
        test.addTeardownBlock {
            await MainActor.run {
                app.terminate()
                app.launchArguments=["--article-test-fixture"]+isolationArguments
                app.launchEnvironment["HZS_DRAFT_CASE"]=nil
                app.launchEnvironment["HZS_DRAFT_AUTO_OPEN"]=nil
                app.launchEnvironment["HZS_FIXTURE_CLEANUP"]="1"
                app.launch(); app.activate()
                XCTAssertTrue(app.staticTexts["試験データを回収しました。"].waitForExistence(timeout:10),"当該ケース所有rootの回収を確認")
                app.terminate()
            }
        }
        app.launch(); app.activate()
        return app
    }
}
