import XCTest

@MainActor final class ArticleDraftPerformanceUITests:ArticleDraftUITestCase {
    override func setUpWithError() throws {continueAfterFailure=false}
    func testLoadingLabelsThirtyEntryAndListRequests() {
        let app=launch("performance")
        XCTAssertTrue(app.textFields["article-title"].draftExists(timeout:5))
        for index in 0..<30 {
            for (kind,item) in [("entry-loading-draw","選択した写真の記事を開く"),("list-loading-draw","保存した下書きを開く")] {
                app.buttons["draft-arm-read"].click(); XCTAssertTrue(app.staticTexts["draft-read-armed"].draftExists(timeout:5))
                app.menuBars.menuBarItems["記事"].click(); app.menuItems[item].click()
                XCTAssertTrue(app.staticTexts["article-loading"].draftExists(timeout:5))
                awaitMetric(app,kind,count:index+1)
                app.buttons["draft-release-read"].click()
                if kind == "list-loading-draw" {
                    XCTAssertTrue(app.buttons["draft-cancel"].draftExists(timeout:5)); app.buttons["draft-cancel"].click()
                } else {XCTAssertTrue(app.staticTexts["article-loading"].draftAbsent(timeout:5))}
            }
        }
        let values=metrics(app)
        for kind in ["entry-loading-draw","list-loading-draw"] {
            let samples=values[kind] ?? [], ordered=samples.sorted()
            print("Draft native loading \(kind) n=\(samples.count) p95=\(ordered.isEmpty ? 0 : ordered[Int(ceil(Double(ordered.count)*0.95))-1]) max=\(samples.max() ?? 0) seconds; response held; 100articles/1000initialOperations")
            XCTAssertGreaterThanOrEqual(samples.count,30); XCTAssertLessThanOrEqual(samples.max() ?? .infinity,0.5)
            XCTAssertEqual(values[kind+"-timeouts"]?.last ?? 0,0)
        }
    }
    func testApplicationColdInputReadyTenLaunches() {
        let app=launch("performance")
        XCTAssertTrue(app.textFields["article-title"].draftExists(timeout:5)); app.terminate()
        app.launchEnvironment["HZS_DRAFT_AUTO_OPEN"]="1"
        var values:[Double]=[], processes=Set<Double>()
        for _ in 0..<10 {
            app.launch(); app.activate()
            XCTAssertTrue(app.textFields["article-title"].draftExists(timeout:10))
            awaitMetric(app,"cold-input-ready",count:1)
            XCTAssertEqual((app.textFields["article-title"].value as? String)?.count,200)
            let result=metrics(app); values.append(contentsOf:result["cold-input-ready"] ?? [])
            if let process=result["fixture-process"]?.last {processes.insert(process)} else {XCTFail("計測対象fixtureプロセスを識別する")}
            XCTAssertEqual(result["cold-input-ready-timeouts"]?.last ?? 0,0)
            app.terminate()
        }
        XCTAssertEqual(values.count,10); XCTAssertEqual(processes.count,10)
        let ordered=values.sorted()
        print("Draft native application-cold n=10 distinctProcesses=\(processes.count) p95=\(ordered.last ?? 0) max=\(values.max() ?? 0) seconds; App.init-to-enabled-editable-firstResponder; prepared100articles/1000operations; process bootstrap before App.init and OS disk-cache cold are not measured")
    }
    func testLongDraftNativeDisplayPerformance() {
        let app=launch("performance"), title=app.textFields["article-title"]
        XCTAssertTrue(title.draftExists(timeout:5)); XCTAssertEqual((title.value as? String)?.count,200)
        for index in 0..<30 {
            app.buttons["draft-restart-photos"].click()
            let photoPending=app.staticTexts.matching(NSPredicate(format:"identifier == %@ AND (label CONTAINS %@ OR value CONTAINS %@)","article-preview-state-1","取得中","取得中")).firstMatch
            XCTAssertTrue(photoPending.draftExists(timeout:5))
            app.buttons["article-save"].click()
            XCTAssertTrue(state(app,contains:"保存中").draftExists(timeout:5))
            awaitMetric(app,"saving-draw",count:index+1)
            title.click(); title.typeKey(.rightArrow,modifierFlags:.command)
            title.typeKey(.leftArrow,modifierFlags:.shift); title.typeKey(.leftArrow,modifierFlags:.shift)
            title.typeText(String(format:"%02d",index))
            XCTAssertEqual((title.value as? String)?.count,200)
            awaitCurrentInputMetric(app)
            XCTAssertTrue(photoPending.exists,"画像要求と保存応答の待機中も入力を反映する")
            app.buttons["draft-release-save"].click()
            XCTAssertTrue(state(app,contains:"未保存の変更").draftExists(timeout:5))
        }
        app.buttons["article-save"].click(); app.buttons["draft-release-save"].click()
        XCTAssertTrue(state(app,contains:"保存しました").draftExists(timeout:5))
        let expected=title.value as? String
        for index in 0..<30 {
            app.buttons["article-mode-preview"].click()
            XCTAssertTrue(app.staticTexts["article-rendered-title"].draftExists(timeout:5))
            awaitMetric(app,"preview-draw",count:index+1)
            app.buttons["article-mode-edit"].click()
            XCTAssertTrue(title.draftExists(timeout:5)); awaitMetric(app,"editor-input-ready",count:index+1)
            XCTAssertEqual(title.value as? String,expected)
        }
        for index in 0..<30 {
            app.buttons["draft-reopen"].click(); awaitMetric(app,"reopen-input-ready",count:index+1)
            XCTAssertEqual(title.value as? String,expected)
            XCTAssertEqual((app.textViews["article-closing"].value as? String)?.count,10000)
        }
        let values=metrics(app)
        var exceeded:[String]=[]
        for (kind,limit) in [("saving-draw",0.5),("input-draw",0.5),("preview-draw",0.5),("editor-input-ready",0.5),("reopen-input-ready",2.0)] {
            let samples=(values[kind] ?? []).sorted()
            XCTAssertGreaterThanOrEqual(samples.count,30)
            guard !samples.isEmpty else {continue}
            let p95=samples[Int(ceil(Double(samples.count)*0.95))-1]
            print("Draft native display \(kind) n=\(samples.count) p95=\(p95) max=\(samples.last!) seconds; 100articles/1000initialOperations/title200/body10000x6; handler-to-native-draw; input-ready requires enabled/editable field editor firstResponder")
            if p95 > limit {exceeded.append(kind+" p95=\(p95)")}
            if (values[kind+"-timeouts"]?.last ?? 0) > 0 {exceeded.append(kind+" not-ready timeout")}
            if (kind == "saving-draw" || kind == "input-draw"),samples.last ?? .infinity > 0.5 {exceeded.append(kind+" max=\(samples.last!)")}
        }
        XCTAssertTrue(exceeded.isEmpty,exceeded.joined(separator:"; "))
    }
}
