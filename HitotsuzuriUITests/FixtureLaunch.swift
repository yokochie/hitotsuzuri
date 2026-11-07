import XCTest

@MainActor enum FixtureLaunch {
    enum Storage: String { case temporary, applicationSupport = "application-support" }
    static let isolationArguments=["-ApplePersistenceIgnoreState","YES","-NSTreatUnknownArgumentsAsOpen","NO"]
    static func article(test:XCTestCase,fixture:String?=nil,storage:Storage = .temporary)->XCUIApplication {
        launch(test:test,flag:"--article-test-fixture",fixture:fixture,storage:storage)
    }
    static func picker(test:XCTestCase)->XCUIApplication {
        launch(test:test,flag:"--ui-test-fixture",fixture:nil,storage:.temporary)
    }
    private static func launch(test:XCTestCase,flag:String,fixture:String?,storage:Storage)->XCUIApplication {
        let token="uitest-"+UUID().uuidString
        let app=XCUIApplication()
        app.launchArguments=[flag]+isolationArguments
        app.launchEnvironment["HZS_ARTICLE_TEST_ROOT"]=token
        app.launchEnvironment["HZS_DRAFT_CASE"]=fixture
        app.launchEnvironment["HZS_ARTICLE_TEST_STORAGE"]=storage.rawValue
        // 同一ケースの再起動ではrootを保持。最後だけapp自身のsandbox内で回収する。
        test.addTeardownBlock {
            await MainActor.run {
                app.terminate()
                app.launchArguments=["--article-test-fixture"]+isolationArguments
                app.launchEnvironment["HZS_DRAFT_CASE"]=nil
                app.launchEnvironment["HZS_DRAFT_AUTO_OPEN"]=nil
                app.launchEnvironment["HZS_FIXTURE_CLEANUP"]="1"
                app.launchEnvironment["HZS_ARTICLE_TEST_STORAGE"]=storage.rawValue
                app.launch(); app.activate()
                let cleanupConfirmation = app.staticTexts["試験データを回収しました。"]
                XCTAssertTrue(cleanupConfirmation.draftExists(timeout: 10), "当該ケース所有rootの回収を確認")
                app.terminate()
            }
        }
        app.launch(); app.activate()
        return app
    }
}
