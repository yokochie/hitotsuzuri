import XCTest

// 実Coordinator→Delivery→ImageAccess→合成readerを通す。UI状態をfixtureで代行しない。
@MainActor final class ArticleCloudExportUITests: ArticleDraftUITestCase {
    override func setUpWithError() throws {continueAfterFailure=false}

    private func value(_ element:XCUIElement)->String {
        guard element.exists else {return "<missing>"}
        return (element.value as? String).flatMap {$0.isEmpty ? nil : $0} ?? element.label
    }
    private func diagnostic(_ app:XCUIApplication)->String {value(app.staticTexts["restoration-diagnostic"])}
    private func wait(_ reason:String,_ app:XCUIApplication,_ condition:@escaping @MainActor ()->Bool) {
        let predicate=NSPredicate {_,_ in MainActor.assumeIsolated {condition()}}
        let result=XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:predicate,object:nil)],timeout:8)
        if result != .completed {
            let snapshot=observations(app)
            print("cloud-export wait failure: \(reason); \(snapshot)")
            let attachment=XCTAttachment(string:"\(reason)\n\(snapshot)\n\(app.windows.firstMatch.debugDescription)")
            attachment.name="cloud-export-wait"; attachment.lifetime = .keepAlways; add(attachment)
        }
        XCTAssertEqual(result,.completed,reason)
    }
    private func action(_ id:String,_ app:XCUIApplication)->XCUIElement {
        let button=app.buttons[id]
        for _ in 0..<30 {
            if button.exists {
                let frame=button.frame, viewport=app.scrollViews.firstMatch.frame
                if button.isHittable && frame.minY >= viewport.minY+3 && frame.maxY <= viewport.maxY-3 {return button}
                scrollForm(app,delta:frame.midY > viewport.midY ? -350 : 350)
            } else {scrollForm(app,delta:-350)}
        }
        XCTAssertTrue(button.isHittable,id); return button
    }
    private func ready(_ app:XCUIApplication) {
        wait("記事の4枚表示",app) {
            let text=self.diagnostic(app)
            return text.contains("owner=true;") && !text.contains("none") && text.contains("working=false;")
        }
    }
    private func beginHeld(_ app:XCUIApplication) {
        ready(app); action("article-export",app).click()
        wait("実readerへのcloud許可と応答保留",app) {
            let text=self.diagnostic(app)
            return text.contains("cloudNetwork=1;") && text.contains("outputPending=1;")
        }
        XCTAssertFalse(app.buttons["article-export"].isEnabled)
    }
    private func message(_ app:XCUIApplication)->String {
        let element=app.staticTexts["article-export-message"]
        guard element.exists else {return "<missing>"}
        // 選択可能Textのvalueはfield-editor由来の旧値を残す場合がある。
        // 画面Text自身のlabelを優先し、実Session/ProgressViewも独立観測する。
        return element.label.isEmpty ? value(element) : element.label
    }
    private func observations(_ app:XCUIApplication)->String {
        let element=app.staticTexts["article-export-message"], progress=app.progressIndicators["article-export-progress"]
        return "\(diagnostic(app));message.exists=\(element.exists);message.label=\(element.exists ? element.label : "missing");message.value=\(element.exists ? String(describing:element.value) : "missing");progress.exists=\(progress.exists);progress.value=\(progress.exists ? String(describing:progress.value) : "missing")"
    }
    private func progressVisible(_ app:XCUIApplication) {
        // Formのscroll位置を整えてから現在の文字と実progressbarを照合する。
        _=action("article-export-cancel",app)
        wait("実readerのfractionと画面文字/ProgressViewの50%が一致",app) {
            let progress=app.progressIndicators["article-export-progress"]
            return self.diagnostic(app).contains("exportFraction=0.5;") && self.message(app).contains("50%") && progress.exists && String(describing:progress.value).contains("50")
        }
    }
    private func finished(_ app:XCUIApplication) {
        wait("一式出力の完了",app) {app.staticTexts["article-export-result"].exists && app.buttons["article-export"].isEnabled}
        ready(app)
        wait("現在の画面文字と実Sessionの一式完了",app) {
            self.message(app).contains("完了しました") && self.diagnostic(app).contains("exportMessage=記事と4枚の出力が完了しました。;")
        }
        XCTAssertEqual(field("article-title",app).value as? String,"合成")
    }

    // U1: 番号付き待機→実progress→実画像取得/一式完了。
    func testCloudDownloadShowsPhotoNumberAndProgressBeforeBundleCompletes() {
        let app=launch("cloud-progress")
        beginHeld(app)
        XCTAssertTrue(message(app).contains("写真 1/4"),"取得対象は完了枚数0ではなく写真番号1で示す: \(message(app))")
        XCTAssertFalse(app.staticTexts["article-export-result"].exists)
        app.buttons["cloud-progress"].click()
        progressVisible(app)
        XCTAssertFalse(app.staticTexts["article-export-result"].exists,"1枚の進捗は一式成功ではない")
        app.buttons["cloud-release"].click()
        finished(app)
    }

    // U2: 待機/進捗中に取消を受け、実終端を待って表示へ戻る。
    func testCloudCancellationKeepsOwnershipUntilActualTerminalAndRestoresPhotos() {
        let app=launch("cloud-cancel")
        beginHeld(app)
        app.buttons["cloud-progress"].click()
        progressVisible(app)
        action("article-export-cancel",app).click()
        wait("取消が実readerへ到達",app) {self.diagnostic(app).contains("outputCancelled=1;")}
        XCTAssertFalse(app.buttons["article-export"].isEnabled)
        XCTAssertTrue(message(app).contains("取消"))
        app.buttons["cloud-progress"].click()
        XCTAssertTrue(message(app).contains("取消"),"取消後進捗で待機表示へ戻さない")
        app.buttons["cloud-release"].click()
        wait("実画像終端と記事の操作復帰",app) {self.diagnostic(app).contains("imageBusy=false;") && app.buttons["article-export"].isEnabled}
        ready(app)
        XCTAssertFalse(app.staticTexts["article-export-result"].exists)
        XCTAssertEqual(field("article-title",app).value as? String,"合成")
    }

    // U3: 不明な取得失敗を事前取得だけへ誘導せず、アプリ内で新規再出力。
    func testSecondPhotoFailureOffersInAppRetryAndNextExportSucceeds() {
        let app=launch("cloud-retry")
        ready(app); action("article-export",app).click()
        wait("写真2の実取得失敗",app) {self.message(app).contains("写真 2") && app.buttons["article-export"].isEnabled}
        XCTAssertFalse(message(app).contains("写真アプリ"),"アプリ内取得で事前取得を唯一の解決策にしない")
        XCTAssertTrue(message(app).contains("もう一度出力"))
        XCTAssertFalse(app.staticTexts["article-export-result"].exists)
        ready(app); action("article-export",app).click()
        finished(app)
        XCTAssertTrue(diagnostic(app).contains("cloudNetwork=1,1,1,1,1,1;"),"失敗2枚＋再出力4枚の実要求")
    }
}
