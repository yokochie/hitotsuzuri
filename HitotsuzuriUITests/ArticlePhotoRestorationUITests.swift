import XCTest

// T1–T11: 実Coordinator/View/LocalImageAccess/出力Sessionを通る接続回帰。
// fixtureはdriver応答と失敗条件だけを制御し、表示ownerの生成/復帰は行わない。
// restore-* はPickerの検証adapterを分離し、記事要求自体を計数する。
// Pickerと共有した場合の相互作用はこのclassの対象外。既存資源/通常UI試験と実機確認を併用する。
@MainActor final class ArticlePhotoRestorationUITests: ArticleDraftUITestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private var observedApp:XCUIApplication?
    override func launch(_ fixture:String="default",open:Bool=true)->XCUIApplication {
        let app=super.launch(fixture,open:open)
        observedApp=app
        return app
    }

    private func wait(_ reason:String, timeout:TimeInterval=6, _ condition:@escaping @MainActor () -> Bool) {
        let predicate=NSPredicate {_,_ in MainActor.assumeIsolated {condition()}}
        let outcome=XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:predicate,object:nil)],timeout:timeout)
        if outcome != .completed, let app=observedApp {
            // このclassは合成fixtureだけを起動する。本人写真や他アプリを取得しない。
            let element=app.staticTexts["restoration-diagnostic"]
            let attachment=XCTAttachment(string:"reason=\(reason)\nlatestDiagnostic=\(diagnostic(app))\nlatestCounts=\(counts(app))\ndiagnostic.label=\(element.exists ? element.label : "missing")\ndiagnostic.value=\(element.exists ? String(describing:element.value) : "missing")\n\(app.windows.firstMatch.debugDescription)")
            attachment.name="photo-restoration-wait-failure"; attachment.lifetime = .keepAlways; add(attachment)
        }
        XCTAssertEqual(outcome,.completed,reason)
    }
    private func value(_ element:XCUIElement)->String {
        guard element.exists else {return "<missing>"}
        if let value=element.value as? String, !value.isEmpty {return value}
        return element.label
    }
    private func diagnostic(_ app:XCUIApplication)->String {value(app.staticTexts["restoration-diagnostic"])}
    private func counts(_ app:XCUIApplication)->[Int] {
        value(app.staticTexts["draft-photo-request-counts"]).split(separator:",").compactMap {Int($0)}
    }
    private func diagnosticCounts(_ text:String)->[Int] {
        (text.components(separatedBy:"requests=").last?.components(separatedBy:";").first ?? "").split(separator:",").compactMap {Int($0)}
    }
    private func action(_ id:String,_ app:XCUIApplication)->XCUIElement {
        let button=app.buttons[id]
        if !button.exists {scrollForm(app,delta:10000)}
        func visible()->Bool {
            guard button.exists else {return false}
            let frame=button.frame, viewport=app.scrollViews.firstMatch.frame
            return button.isHittable && frame.minY >= viewport.minY+3 && frame.maxY <= viewport.maxY-3
        }
        for _ in 0..<30 {
            if visible() {break}
            if !button.exists {scrollForm(app,delta:-250)}
            else {scrollForm(app,delta:button.frame.midY > app.scrollViews.firstMatch.frame.midY ? -350 : 350)}
        }
        XCTAssertTrue(visible(),id); return button
    }
    private func ready(_ app:XCUIApplication, requested:[Int]?=nil) {
        wait("4番号が実際にreadyになる: \(diagnostic(app))") {
            let text=self.diagnostic(app)
            let pixels=text.components(separatedBy:"pixels=").last?.components(separatedBy:";").first?.split(separator:",") ?? []
            // 1つのAX診断snapshot内の状態と実要求を照合し、predicate中のremote lookupを減らす。
            let countsMatch=requested.map {self.diagnosticCounts(text) == $0} ?? true
            return text.contains("owner=true") && pixels.count == 4 && !pixels.contains("none") && countsMatch
        }
        if let requested {XCTAssertEqual(counts(app),requested,"独立した要求数表示も一致する")}
        scrollForm(app,delta:10000)
        for number in 1...4 {
            let image=app.images["article-preview-\(number)"]
            for _ in 0..<12 {
                if image.exists {break}
                scrollForm(app,delta:-220)
            }
            XCTAssertTrue(image.exists,"写真\(number)の実Image要素")
            let state=app.staticTexts["article-preview-state-\(number)"]
            XCTAssertTrue([state.label,(state.value as? String) ?? ""].contains("画像を取得しました"),"写真\(number)の実状態。label=\(state.label), value=\(String(describing:state.value))")
        }
        XCTAssertTrue(diagnostic(app).contains("ids=album-a-photo-1,album-a-photo-2,album-a-photo-3,album-a-photo-4"),"保存された写真順")
    }
    private func export(_ app:XCUIApplication) {action("article-export",app).click()}
    private func ended(_ app:XCUIApplication) {
        wait("実Coordinator入口から出力終端へ到達") {
            self.diagnostic(app).contains("entered=1") && app.buttons["article-export"].isEnabled
        }
    }
    private func outputMessage(_ app:XCUIApplication,_ fragment:String) {
        wait("出力結果に\(fragment)を示す") {
            let e=app.staticTexts["article-export-message"]
            return e.exists && (e.label+" "+self.value(e)).contains(fragment)
        }
    }

    // T1: fresh再起動は同一sessionへの出力復帰と区別する対照。
    func testFreshDraftReopenDisplaysFourImagesAndPreservesTextAndOrder() {
        let app=launch("restore-normal")
        ready(app,requested:[1,1,1,1])
        replace(field("article-title",app),"Saved photo order")
        replace(field("article-introduction",app),"Saved introduction.")
        app.buttons["article-save"].click()
        XCTAssertTrue(state(app,contains:"保存しました").draftExists(timeout:5))
        app.terminate(); app.launch(); app.buttons["article-open"].click()
        ready(app,requested:[1,1,1,1])
        XCTAssertEqual(field("article-title",app).value as? String,"Saved photo order")
        XCTAssertEqual(field("article-introduction",app).value as? String,"Saved introduction.")
    }
    // T2: 成功後、編集と記事プレビューの両方で実画像を確認。
    func testSuccessfulExportRestoresEditorAndRenderedImages() {
        let app=launch("restore-normal"); ready(app,requested:[1,1,1,1])
        export(app); outputMessage(app,"完了しました"); ended(app)
        ready(app,requested:[2,2,2,2])
        XCTAssertEqual(field("article-title",app).value as? String,"合成")
        app.buttons["article-mode-preview"].click()
        XCTAssertTrue(app.staticTexts["article-rendered-title"].draftExists(timeout:5))
        scrollForm(app,delta:10000)
        for number in 1...4 {
            let image=app.images["article-rendered-image-\(number)"]
            for _ in 0..<15 {if image.exists {break}; scrollForm(app,delta:-250)}
            XCTAssertTrue(image.exists,"記事プレビューの写真\(number)")
        }
    }
    // T3: 出力画像と表示画像のadapterは別。画像2の出力失敗でも表示は戻す。
    func testImageExportFailureRestoresAllDisplayImagesAndText() {
        let app=launch("restore-failure"); ready(app,requested:[1,1,1,1])
        export(app); outputMessage(app,"写真 2"); ended(app)
        ready(app,requested:[2,2,2,2])
        XCTAssertEqual(field("article-title",app).value as? String,"合成")
        XCTAssertFalse(app.staticTexts["article-export-result"].exists)
    }
    // T4: reader取消を受けてもcallbackまで実busy。論理取消後に重ねて取得しない。
    func testCancellationWaitsForActualImageTerminalBeforeRestoring() {
        let app=launch("restore-cancel"); ready(app,requested:[1,1,1,1])
        export(app)
        wait("合成出力readerを保留") {self.diagnostic(app).contains("outputPending=1")}
        action("article-export-cancel",app).click()
        wait("取消が実readerへ届き、応答保留中も実処理を保持する") {
            let text=self.diagnostic(app)
            return text.contains("outputCancelled=1;") && text.contains("outputPending=1;") && text.contains("imageBusy=true;")
        }
        XCTAssertTrue(diagnostic(app).contains("imageBusy=true"))
        XCTAssertFalse(app.buttons["article-export"].isEnabled,"実reader終端まで出力Sessionも待機する")
        XCTAssertEqual(counts(app),[1,1,1,1],"実画像処理中は表示要求を開始しない")
        app.buttons["restoration-release-output"].click()
        ended(app)
        wait("旧出力readerの実終端") {self.diagnostic(app).contains("imageBusy=false")}
        ready(app,requested:[2,2,2,2])
        XCTAssertFalse(app.staticTexts["article-export-result"].exists)
    }
    // T5: 表示解放後に到達する保存先選択の取消。
    func testDestinationCancellationRestoresFourImages() {
        let app=launch("restore-destination-cancel"); ready(app,requested:[1,1,1,1])
        export(app); outputMessage(app,"取り消しました"); ended(app)
        ready(app,requested:[2,2,2,2])
    }
    // T6: 大きい画像を作らず、既存の予算判定へ合成保持量を注入。
    func testCapacityRejectionAfterReleaseRestoresFourImages() {
        let app=launch("restore-capacity"); ready(app,requested:[1,1,1,1])
        export(app); ended(app)
        XCTAssertFalse(value(app.staticTexts["article-export-os-message"]).isEmpty)
        ready(app,requested:[2,2,2,2])
    }
    // T7: save adapter失敗は実prepareSavedExportを通り、未保存本文を残す。
    func testSaveFailureDuringExportRestoresImagesAndUnsavedText() {
        let app=launch("restore-save"); ready(app,requested:[1,1,1,1])
        replace(field("article-title",app),"Unsaved survives save failure")
        export(app); confirmation(app).buttons["保存して出力"].click(); ended(app)
        ready(app,requested:[2,2,2,2])
        XCTAssertEqual(field("article-title",app).value as? String,"Unsaved survives save failure")
        XCTAssertFalse(state(app,contains:"保存しました").exists,"保存失敗を保存済みと表示しない")
        XCTAssertFalse(app.staticTexts["article-export-result"].exists)
    }
    // T8: 解放後の実入力validatorで不正日付を拒否し、そのraw入力を保持。
    func testInputValidationFailureRestoresImagesAndKeepsInvalidInput() {
        let app=launch("restore-input"); ready(app,requested:[1,1,1,1])
        export(app); ended(app)
        ready(app,requested:[2,2,2,2])
        XCTAssertEqual(field("article-day",app).value as? String,"31")
        XCTAssertTrue(app.staticTexts["article-date-error"].exists)
        XCTAssertFalse(app.staticTexts["article-export-result"].exists)
    }
    // T9: マウスは取得不能なまま実要求、切替後のキーボードは画像へ回復。
    func testMouseAndKeyboardRetryIssueOnlyTargetRequestAndRecoverImage() {
        let app=launch("restore-retry")
        let retry=action("article-retry-2",app)
        wait("初回の4要求が終端へ到達") {self.counts(app) == [1,1,1,1] && retry.isEnabled}
        replace(field("article-title",app),"Retry keeps unsaved text")
        action("article-retry-2",app).click()
        wait("マウスによる番号2の実要求") {self.counts(app) == [1,2,1,1] && app.buttons["article-retry-2"].isEnabled}
        app.buttons["restoration-available"].click()
        field("article-title",app).click()
        for _ in 0..<3 {app.typeKey(.tab,modifierFlags:.shift)}
        app.typeKey(.space,modifierFlags:[])
        ready(app,requested:[1,3,1,1])
        XCTAssertEqual(field("article-title",app).value as? String,"Retry keeps unsaved text")
    }
    // T10: 旧表示応答を取消後にも返し、新sessionの画像/保持へ混入させない。
    func testLateOldDisplayResponseCannotPopulateNewSessionOrRetainOldBuffer() {
        let app=launch("restore-late")
        wait("旧sessionの要求がdriverで保留") {self.diagnostic(app).contains("displayPending=1")}
        let oldSession=diagnostic(app).components(separatedBy:";")[0]
        app.buttons["article-back"].click()
        XCTAssertTrue(app.buttons["article-open"].draftExists(timeout:5))
        app.buttons["article-open"].click()
        wait("新sessionの要求も保留") {self.diagnostic(app).contains("displayPending=2")}
        XCTAssertNotEqual(diagnostic(app).components(separatedBy:";")[0],oldSession)
        app.buttons["restoration-release-display"].click()
        ready(app,requested:[2,1,1,1])
        wait("旧callbackの画像を保持せず現在4枚だけ保持") {
            let text=self.diagnostic(app)
            return text.contains("pixels=64,81,98,115;") && text.contains("retained=4096;") && text.contains("active=0;queued=0;") && text.contains("unnecessary=0;")
        }
    }
    // T11: 出力Sessionの終了後も、Coordinatorの後照会が終わるまで所有を維持する。
    func testPostExportQueryKeepsOwnershipUntilNextExportCanStart() {
        let app=launch("restore-reentry")
        ready(app,requested:[1,1,1,1])
        export(app)
        wait("最初の出力Sessionが終了し、実pending照会相当のawaitで保留") {
            let text=self.diagnostic(app)
            return text.contains("postQueryWaiters=1;") && text.contains("exportSessionBusy=false;") && text.contains("accepted=1;")
        }
        // 通常ボタンの無効化を迂回して実入口へ送る。fixtureはbusyも復帰も代行しない。
        app.buttons["restoration-request-export"].click()
        wait("実入口が再要求を拒否して返る、または誤って次を受理する") {
            let text=self.diagnostic(app)
            return text.contains("reentryCompleted=1;") || text.contains("accepted=2;")
        }
        let held=diagnostic(app)
        let accepted=Int(held.components(separatedBy:"accepted=").last?.components(separatedBy:";").first ?? "")
        XCTAssertEqual(accepted,1,"後照会中の再要求は実Coordinatorでも拒否する。\(held)")
        XCTAssertTrue(held.contains("working=true;"),"出力後の照会まで所有する。\(held)")
        XCTAssertTrue(held.contains("owner=false;"),"所有期間中に表示を復帰しない。\(held)")
        XCTAssertEqual(counts(app),[1,1,1,1],"後照会/再要求中に表示要求を増やさない")
        XCTAssertFalse(app.buttons["article-export"].isEnabled,"通常ボタンも同じ所有期間を守る")
        app.buttons["restoration-release-query"].click()
        wait("最初の照会が終了して所有を解放") {
            let text=self.diagnostic(app)
            return text.contains("postQueryWaiters=0;") && text.contains("working=false;")
        }
        ready(app,requested:[2,2,2,2])
        export(app)
        wait("解放後は次の出力が受理され、実出力と後照会が終了する") {
            let text=self.diagnostic(app)
            return text.contains("accepted=2;") && text.contains("postQueryCalls=2;") && text.contains("working=false;")
        }
        ready(app,requested:[3,3,3,3])
        outputMessage(app,"完了しました")
        XCTAssertEqual(field("article-title",app).value as? String,"合成")
    }
}
