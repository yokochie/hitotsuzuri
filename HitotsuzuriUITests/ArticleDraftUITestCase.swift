import XCTest

// 共通操作のみ。ここにはtestメソッドを置かず、機能/性能の所属を明確にする。
@MainActor class ArticleDraftUITestCase:XCTestCase {
    func launch(_ fixture:String="default", open:Bool=true)->XCUIApplication {
        let app=FixtureLaunch.article(test:self,fixture:fixture)
        XCTAssertTrue(app.windows.firstMatch.draftExists(timeout:10),app.debugDescription)
        if open {
            let button=app.buttons["article-open"]
            let ready=NSPredicate {_,_ in MainActor.assumeIsolated {button.exists && button.isEnabled}}
            XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:ready,object:nil)],timeout:fixture == "performance" ? 60 : 8),.completed,"fixture準備後の記事入口が有効になる")
            button.click()
        }
        return app
    }
    func field(_ id:String,_ app:XCUIApplication)->XCUIElement {
        let multiline=["article-introduction","article-closing","article-location","article-equipment","article-film","article-people"]+(1...4).map {"article-photo-\($0)"}
        let element=multiline.contains(id) ? app.textViews[id] : app.textFields[id]
        XCTAssertTrue(element.draftExists(timeout:5),app.debugDescription)
        func visible()->Bool {
            let frame=element.frame, viewport=app.scrollViews.firstMatch.frame
            return element.isHittable && frame.minY >= viewport.minY+3 && frame.maxY <= viewport.maxY-3
        }
        // 出力完了時にもForm自身が移動するため、固定方向ではなく毎回位置を取り直す。
        // 大きな一括スクロールを避け、上側・下側のどちらにはみ出した欄も追従する。
        for _ in 0..<30 {
            if visible() {break}
            let frame=element.frame, viewport=app.scrollViews.firstMatch.frame
            let distance=viewport.midY-frame.midY
            scrollForm(app,delta:max(-250,min(250,distance)))
        }
        XCTAssertTrue(visible(),"入力欄全体がスクロール領域に見える: \(id), field=\(element.frame), viewport=\(app.scrollViews.firstMatch.frame)")
        return element
    }
    func scrollForm(_ app:XCUIApplication,delta:CGFloat) {
        // TextEditor内部ではなく、外側フォームの16pt余白にホイールを送る。
        app.scrollViews.firstMatch.coordinate(withNormalizedOffset:CGVector(dx:0.01,dy:0.5)).scroll(byDeltaX:0,deltaY:delta)
    }
    func replace(_ element:XCUIElement,_ value:String) {
        element.click(); element.typeKey("a",modifierFlags:.command); element.typeText(value)
        // 日本語入力の候補を確定してから、次の欄のスクロールへ進む。
        element.typeKey(.tab,modifierFlags:[])
    }
    func confirmation(_ app:XCUIApplication)->XCUIElement {
        let sheet = app.sheets.firstMatch
        let dialog = app.dialogs.firstMatch
        if sheet.exists { return sheet }
        if dialog.exists { return dialog }
        let eitherExists = NSPredicate { _, _ in
            MainActor.assumeIsolated { sheet.exists || dialog.exists }
        }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: eitherExists, object: nil)], timeout: 6)
        XCTAssertEqual(result, .completed, "保存確認がシートまたはダイアログとして表示される")
        return sheet.exists ? sheet : dialog
    }
    func state(_ app:XCUIApplication,contains text:String)->XCUIElement {
        app.staticTexts.matching(NSPredicate(format:"identifier == %@ AND (label CONTAINS %@ OR value CONTAINS %@)","article-save-state",text,text)).firstMatch
    }
    func metrics(_ app:XCUIApplication)->[String:[Double]] {
        let element=app.descendants(matching:.any)["draft-display-metrics"]
        for text in [(element.value as? String) ?? "",element.label] {
            if let data=text.data(using:.utf8),let values=try? JSONDecoder().decode([String:[Double]].self,from:data) {return values}
        }
        return [:]
    }
    func awaitMetric(_ app:XCUIApplication,_ kind:String,count:Int) {
        if (metrics(app)[kind]?.count ?? 0) >= count {return}
        let predicate=NSPredicate {_,_ in MainActor.assumeIsolated {(self.metrics(app)[kind]?.count ?? 0) >= count}}
        let result=XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:predicate,object:nil)],timeout:5)
        let element=app.descendants(matching:.any)["draft-display-metrics"]
        XCTAssertEqual(result,.completed,"描画計測 \(kind) \(count)回; counts=\(metrics(app).mapValues(\.count)); label=\(element.label) value=\(String(describing:element.value))")
    }
    func awaitCurrentInputMetric(_ app:XCUIApplication) {
        let current=metrics(app), accepted=current["input-draw-accepted"]?.last ?? 0
        if accepted > 0,accepted == current["input-draw-completed"]?.last {return}
        let predicate=NSPredicate {_,_ in MainActor.assumeIsolated {
            let values=self.metrics(app), accepted=values["input-draw-accepted"]?.last ?? 0
            return accepted > 0 && accepted == values["input-draw-completed"]?.last
        }}
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:predicate,object:nil)],timeout:5),.completed,"最新の入力受付とfield editor描画完了を照合")
    }
}
extension XCUIElement {
    func draftExists(timeout:TimeInterval)->Bool {exists || waitForExistence(timeout:timeout)}
    func draftAbsent(timeout:TimeInterval)->Bool {!exists || waitForNonExistence(timeout:timeout)}
}
