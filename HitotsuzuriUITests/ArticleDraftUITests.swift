import XCTest

@MainActor final class ArticleDraftUITests:ArticleDraftUITestCase {
    override func setUpWithError() throws {continueAfterFailure=false}
    func testNativeInputMeasurementUsesCurrentFieldEditor() {
        let app=launch("performance"), title=app.textFields["article-title"]
        XCTAssertTrue(title.draftExists(timeout:5))
        app.buttons["article-save"].click(); awaitMetric(app,"saving-draw",count:1)
        title.click(); title.typeKey(.rightArrow,modifierFlags:.command)
        title.typeKey(.leftArrow,modifierFlags:.shift); title.typeKey(.leftArrow,modifierFlags:.shift); title.typeText("00")
        awaitCurrentInputMetric(app)
        XCTAssertEqual((title.value as? String)?.count,200)
        app.buttons["draft-release-save"].click()
        let values=metrics(app)["input-draw"] ?? []
        XCTAssertFalse(values.isEmpty); XCTAssertLessThanOrEqual(values.max() ?? .infinity,0.5)
        XCTAssertEqual(metrics(app)["input-draw-timeouts"]?.last ?? 0,0)
        print("Draft native input diagnostic samples=\(values.count) max=\(values.max() ?? 0) seconds")
    }
    func testEntryAndListLoadingCanComplete() {
        let app=launch("performance")
        XCTAssertTrue(app.textFields["article-title"].draftExists(timeout:5))
        for (kind,item) in [("entry-loading-draw","選択した写真の記事を開く"),("list-loading-draw","保存した下書きを開く")] {
            app.buttons["draft-arm-read"].click()
            XCTAssertTrue(app.staticTexts["draft-read-armed"].draftExists(timeout:5))
            app.menuBars.menuBarItems["記事"].click(); app.menuItems[item].click()
            XCTAssertTrue(app.staticTexts["article-loading"].draftExists(timeout:5))
            awaitMetric(app,kind,count:1)
            app.buttons["draft-release-read"].click()
            if kind == "list-loading-draw" {
                XCTAssertTrue(app.buttons["draft-cancel"].draftExists(timeout:5))
                app.buttons["draft-cancel"].click()
            } else {XCTAssertTrue(app.staticTexts["article-loading"].draftAbsent(timeout:5))}
            XCTAssertTrue(app.textFields["article-title"].exists)
            XCTAssertEqual(metrics(app)[kind+"-timeouts"]?.last ?? 0,0)
        }
    }
    func testCurrentEntryShowsCandidateAndAllMetadataFields() {
        let app=launch(); XCTAssertEqual(field("article-title",app).value as? String,"合成")
        for id in ["article-year","article-month","article-day","article-location","article-equipment","article-film","article-people"] {XCTAssertTrue(field(id,app).exists)}
        XCTAssertTrue(app.staticTexts["article-date-state"].exists)
    }
    func testMenuAndButtonOpenSamePersistedArticle() {
        let app=launch(); replace(field("article-title",app),"同じ記事")
        app.typeKey("s",modifierFlags:.command); XCTAssertTrue(app.staticTexts["下書きを保存しました。"].draftExists(timeout:5))
        app.buttons["article-back"].click()
        app.menuBars.menuBarItems["記事"].click(); app.menuItems["選択した写真の記事を開く"].click()
        XCTAssertEqual(field("article-title",app).value as? String,"同じ記事")
    }
    func testAllMetadataSaveAndRelaunch() {
        let app=launch()
        for (id,value) in [("article-location","場所👩‍👧"),("article-equipment","機材"),("article-film","フィルム"),("article-people","人物"),("article-year","2024"),("article-month","2"),("article-day","29")] {
            let input=field(id,app)
            replace(input,value)
            XCTAssertEqual(input.value as? String,value,"保存前のfixture入力確認: \(id)")
        }
        app.typeKey("s",modifierFlags:.command); XCTAssertTrue(app.staticTexts["下書きを保存しました。"].draftExists(timeout:5))
        app.terminate(); app.launch(); app.buttons["article-open"].click()
        XCTAssertEqual(field("article-location",app).value as? String,"場所👩‍👧")
        XCTAssertEqual(field("article-year",app).value as? String,"2024")
    }
    func testInvalidRawDateBlocksPreviewAndKeepsInput() {
        let app=launch(); replace(field("article-day",app),"99")
        app.buttons["article-mode-preview"].click()
        XCTAssertEqual(field("article-day",app).value as? String,"99")
        XCTAssertTrue(app.staticTexts["article-date-error"].exists); XCTAssertTrue(app.textViews["article-introduction"].exists)
    }
    func testDateConfirmationAndRemovalAreExplicit() {
        let app=launch(); _=field("article-day",app)
        let confirm=app.buttons["article-date-confirm"]
        // 年月日の下にあるボタンも全体を表示してからクリックする。
        scrollForm(app,delta:-100)
        let viewport=app.scrollViews.firstMatch.frame
        XCTAssertGreaterThanOrEqual(confirm.frame.minY,viewport.minY+3)
        XCTAssertLessThanOrEqual(confirm.frame.maxY,viewport.maxY-3)
        XCTAssertTrue(confirm.isEnabled); XCTAssertTrue(confirm.isHittable)
        confirm.click(); XCTAssertTrue(app.staticTexts["確認済み"].draftExists(timeout:3),"state=\(app.staticTexts["article-date-state"].label)")
        app.buttons["article-date-remove"].click(); XCTAssertEqual(field("article-year",app).value as? String,"")
    }
    func testPreviewSwitchPreservesUnsavedCurrentText() {
        let app=launch(); replace(field("article-title",app),"現在の未保存本文")
        app.buttons["article-mode-preview"].click()
        XCTAssertTrue(app.staticTexts["article-rendered-title"].draftExists(timeout:5))
        app.buttons["article-mode-edit"].click()
        XCTAssertEqual(field("article-title",app).value as? String,"現在の未保存本文")
        XCTAssertTrue(app.staticTexts["未保存の変更があります。"].exists)
    }
    func testReconfirmedSelectionCanResumeChosenDraft() {
        let app=launch("reconfirmed")
        XCTAssertTrue(app.buttons["draft-open"].draftExists(timeout:5))
        app.radioButtons.firstMatch.click(); app.buttons["draft-open"].click()
        XCTAssertEqual(field("article-title",app).value as? String,"既存の文章1")
    }
    func testMultipleCandidatesRequireExplicitChoiceAndCancel() {
        let app=launch("multiple")
        XCTAssertTrue(app.buttons["draft-cancel"].draftExists(timeout:5))
        let labels=app.radioButtons.allElementsBoundByIndex.map(\.label)
        XCTAssertEqual(labels.count,2); XCTAssertNotEqual(labels[0],labels[1])
        XCTAssertTrue(labels.allSatisfy {$0.contains("同名記事")})
        XCTAssertFalse(app.buttons["draft-open"].isEnabled)
        app.buttons["draft-cancel"].click(); XCTAssertTrue(app.buttons["article-open"].exists)
        XCTAssertFalse(app.textFields["article-title"].exists)
    }
    func testUnavailablePhotoCanRetryWithoutLosingText() {
        let app=launch(); replace(field("article-title",app),"写真なしでも残る")
        let retry=app.buttons["article-retry-2"]; XCTAssertTrue(retry.draftExists(timeout:5)); retry.click()
        XCTAssertEqual(field("article-title",app).value as? String,"写真なしでも残る")
        XCTAssertTrue(app.staticTexts["article-preview-state-2"].exists)
    }
    func testTabAndShiftTabCanRetryEveryUnavailablePhotoWithoutLosingText() {
        let app=launch("photos-missing"), expected="Keyboard retry text"
        let title=field("article-title",app)
        replace(title,expected); XCTAssertEqual(title.value as? String,expected)
        let body=app.textViews["article-introduction"], bodyText="Body survives every photo retry."
        replace(body,bodyText); XCTAssertEqual(body.value as? String,bodyText)
        let counter=app.staticTexts["draft-photo-request-counts"]
        XCTAssertTrue(counter.draftExists(timeout:5))
        func counts()->[Int] {(counter.value as? String ?? "").split(separator:",").compactMap {Int($0)}}
        let baseline=counts()
        XCTAssertEqual(baseline.count,4); XCTAssertTrue(baseline.allSatisfy {$0 > 0})
        title.click()
        func retry(_ number:Int,backward:Bool) {
            let before=counts()
            app.typeKey(.tab,modifierFlags:backward ? .shift : [])
            app.typeKey(.space,modifierFlags:[])
            let requested=NSPredicate {_,_ in MainActor.assumeIsolated {
                let after=counts()
                return after.count == 4 && after[number-1] == before[number-1]+1
            }}
            XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:requested,object:nil)],timeout:3),.completed,"キーで写真\(number)の実要求が増える")
            let after=counts()
            for index in 0..<4 {XCTAssertEqual(after[index],before[index]+(index == number-1 ? 1 : 0))}
            let button=app.buttons["article-retry-\(number)"], viewport=app.scrollViews.firstMatch.frame
            XCTAssertTrue(button.isHittable)
            XCTAssertGreaterThanOrEqual(button.frame.minY,viewport.minY)
            XCTAssertLessThanOrEqual(button.frame.maxY,viewport.maxY)
            XCTAssertEqual(title.value as? String,expected)
            XCTAssertEqual(body.value as? String,bodyText)
        }
        for number in stride(from:4,through:1,by:-1) {retry(number,backward:true)}
        app.typeKey(.tab,modifierFlags:.shift)
        for number in 1...4 {retry(number,backward:false)}
        XCTAssertEqual(counts(),baseline.map {$0+2})
    }
    func testUnsavedEscapeAndWindowCloseContinueEditing() {
        let app=launch(); replace(field("article-title",app),"閉じない文章")
        app.windows.firstMatch.buttons[XCUIIdentifierCloseWindow].click()
        let dialog=confirmation(app); app.typeKey(.escape,modifierFlags:[])
        XCTAssertTrue(dialog.draftAbsent(timeout:5)); XCTAssertEqual(field("article-title",app).value as? String,"閉じない文章")
    }
    func testWidthBoundariesKeepDraftAndReachMetadata() {
        let app=launch("long"), expected=String(repeating:"長い名称",count:50)
        XCTAssertEqual(field("article-title",app).value as? String,expected)
        for id in ["article-introduction","article-photo-1","article-photo-2","article-photo-3","article-photo-4","article-closing"] {
            XCTAssertEqual((app.textViews[id].value as? String)?.count,10000)
        }
        let window=app.windows.firstMatch
        for width in [640,959,960,961,1200] {
            let marker=app.descendants(matching:.any)["article-layout"]
            XCTAssertTrue(marker.exists,app.debugDescription)
            app.buttons["draft-width-\(width)"].click()
            let actual=Double(marker.label.split(separator:":")[0]) ?? 0
            XCTAssertEqual(actual,Double(width),accuracy:0.25,"window=\(window.frame)")
            XCTAssertTrue(marker.label.hasSuffix(width >= 960 ? ":wide" : ":narrow"))
            scrollForm(app,delta:10000)
            XCTAssertTrue(app.staticTexts["article-preview-state-1"].draftExists(timeout:3),app.debugDescription); XCTAssertTrue(app.staticTexts["article-preview-state-2"].exists)
            let first=app.staticTexts["article-preview-state-1"].frame, second=app.staticTexts["article-preview-state-2"].frame
            let title=app.textFields["article-title"].frame
            if width >= 960 {XCTAssertLessThan(first.minX,title.minX); XCTAssertLessThan(first.minY,second.minY)}
            else {XCTAssertLessThan(first.minX,second.minX); XCTAssertLessThan(first.minY,title.minY)}
            XCTAssertEqual(field("article-title",app).value as? String,expected)
            app.textFields["article-title"].click()
            // 長文TextEditor内へのホイール操作に頼らず、本文から全撮影情報へ実キーで移動する。
            for _ in 0..<15 {app.typeKey(.tab,modifierFlags:[])}
            XCTAssertTrue(field("article-people",app).isHittable)
            print("Draft UI measuredContentWidth=\(actual) layout=\(width >= 960 ? "wide" : "narrow") metadataReachable=true")
        }
        app.typeKey("s",modifierFlags:.command); XCTAssertTrue(state(app,contains:"保存しました").draftExists(timeout:5))
        app.terminate(); app.launch(); app.buttons["article-open"].click()
        XCTAssertEqual(field("article-title",app).value as? String,expected)
        for id in ["article-introduction","article-photo-1","article-photo-2","article-photo-3","article-photo-4","article-closing"] {XCTAssertEqual((app.textViews[id].value as? String)?.count,10000)}
        app.buttons["article-mode-preview"].click(); XCTAssertTrue(app.staticTexts["article-rendered-title"].draftExists(timeout:5))
        app.buttons["article-mode-edit"].click()
        let body=app.textViews["article-closing"]
        for _ in 0..<30 {if body.isHittable {break}; scrollForm(app,delta:-300)}
        body.click(); body.typeKey(.downArrow,modifierFlags:.command); body.typeText("末尾")
        XCTAssertTrue((body.value as? String)?.hasSuffix("末尾") == true)
        app.typeKey("s",modifierFlags:.command); XCTAssertTrue(state(app,contains:"保存しました").draftExists(timeout:5))
    }
    func testBodyReturnAndCommandSaveKeepLongUnicodeInput() {
        let app=launch(), body=app.textViews["article-introduction"]
        XCTAssertTrue(body.draftExists(timeout:5)); body.click(); body.typeText("日本語e\u{301}👩‍👧"); body.typeKey(.return,modifierFlags:[]); body.typeText("二行目")
        app.typeKey("s",modifierFlags:.command)
        XCTAssertTrue(app.staticTexts["下書きを保存しました。"].draftExists(timeout:5))
        XCTAssertTrue((body.value as? String)?.contains("\n二行目") == true)
        XCTAssertFalse(app.buttons["article-copy"].isEnabled)
    }
    func testDirtyDraftSelectionDismissesBeforeSingleLeaveConfirmation() {
        let app=launch("multiple")
        XCTAssertTrue(app.buttons["draft-open"].draftExists(timeout:5))
        app.radioButtons.firstMatch.click(); app.buttons["draft-open"].click()
        replace(field("article-title",app),"編集継続する文章")
        app.menuBars.menuBarItems["記事"].click(); app.menuItems["保存した下書きを開く"].click()
        XCTAssertTrue(app.buttons["draft-open"].draftExists(timeout:5))
        app.radioButtons.element(boundBy:1).click(); app.buttons["draft-open"].click()
        let dialog=confirmation(app)
        XCTAssertFalse(app.buttons["draft-open"].exists)
        app.typeKey(.escape,modifierFlags:[])
        XCTAssertTrue(dialog.draftAbsent(timeout:5))
        XCTAssertEqual(field("article-title",app).value as? String,"編集継続する文章")
        XCTAssertFalse(app.buttons["draft-open"].exists)
    }
    func testTabAndShiftTabReachMetadataAndPreviewWithoutSystemSetting() {
        let app=launch(), closing=app.textViews["article-closing"]
        for _ in 0..<20 {if closing.isHittable {break}; app.scrollViews.firstMatch.scroll(byDeltaX:0,deltaY:-300)}
        closing.click(); app.typeKey(.tab,modifierFlags:.shift); app.typeText("戻る本文")
        XCTAssertTrue((app.textViews["article-photo-4"].value as? String)?.contains("戻る本文") == true)
        app.typeKey(.tab,modifierFlags:[]); app.typeKey(.tab,modifierFlags:[])
        app.typeKey("a",modifierFlags:.command); app.typeText("2024")
        XCTAssertEqual(app.textFields["article-year"].value as? String,"2024")
        app.typeKey(.tab,modifierFlags:[]); app.typeKey("a",modifierFlags:.command); app.typeText("2")
        XCTAssertEqual(app.textFields["article-month"].value as? String,"2")
        app.typeKey(.tab,modifierFlags:.shift); app.typeKey("a",modifierFlags:.command); app.typeText("2000")
        XCTAssertEqual(app.textFields["article-year"].value as? String,"2000")
        app.typeKey(.tab,modifierFlags:[]); app.typeKey(.tab,modifierFlags:[])
        app.typeKey("a",modifierFlags:.command); app.typeText("29")
        app.typeKey(.tab,modifierFlags:[]); app.typeKey(.space,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["確認済み"].exists)
        app.typeKey(.tab,modifierFlags:[]); app.typeKey(.tab,modifierFlags:[]); app.typeText("場所")
        XCTAssertEqual(app.textViews["article-location"].value as? String,"場所")
        for (id,text) in [("article-equipment","機材"),("article-film","フィルム"),("article-people","人物")] {
            app.typeKey(.tab,modifierFlags:[]); app.typeText(text); XCTAssertEqual(app.textViews[id].value as? String,text)
        }
        for _ in 0..<4 {app.typeKey(.tab,modifierFlags:[])}
        app.typeKey(.space,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["article-rendered-title"].draftExists(timeout:5))
    }
    func testFailedSaveKeepsInputAndLastGoodSavedValue() {
        let app=launch("save-failure"); replace(field("article-title",app),"保存できなくても残る")
        app.buttons["article-save"].click(); XCTAssertTrue(state(app,contains:"容量").draftExists(timeout:5))
        XCTAssertEqual(field("article-title",app).value as? String,"保存できなくても残る")
        app.buttons["article-back"].click(); confirmation(app).buttons["編集を続ける"].click()
        XCTAssertEqual(field("article-title",app).value as? String,"保存できなくても残る")
    }
    func testUncertainSaveReconcilesBeforeSavingLaterText() {
        let app=launch("save-uncertain"); replace(field("article-title",app),"元の操作")
        app.buttons["article-save"].click(); XCTAssertTrue(state(app,contains:"照合").draftExists(timeout:5))
        replace(field("article-title",app),"追加の入力"); app.buttons["article-save"].click()
        XCTAssertTrue(state(app,contains:"保存しました").draftExists(timeout:5))
        app.terminate(); app.launch(); app.buttons["article-open"].click()
        XCTAssertEqual(field("article-title",app).value as? String,"追加の入力")
    }
    func testSavingAcceptsFurtherInputAndKeepsItDirty() {
        let app=launch("save-delay"); replace(field("article-title",app),"固定する入力")
        app.buttons["article-save"].click(); XCTAssertTrue(state(app,contains:"保存中").draftExists(timeout:5))
        replace(field("article-title",app),"保存中の追加入力")
        app.buttons["draft-release-save"].click()
        XCTAssertTrue(state(app,contains:"未保存の変更").draftExists(timeout:5))
        XCTAssertEqual(field("article-title",app).value as? String,"保存中の追加入力")
    }
    func testPartialDraftListShowsFailureAndCanReloadHealthyCandidates() {
        let app=launch("partial")
        XCTAssertTrue(app.buttons["draft-retry"].draftExists(timeout:5)); XCTAssertFalse(app.buttons["draft-new"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label CONTAINS %@ OR value CONTAINS %@","読込失敗：1件","読込失敗：1件")).firstMatch.exists)
        app.buttons["draft-retry"].click(); XCTAssertEqual(app.radioButtons.count,1)
        app.radioButtons.firstMatch.click(); app.buttons["draft-open"].click()
        XCTAssertEqual(field("article-title",app).value as? String,"既存の文章1")
    }
    func testApplicationQuitCanBeCancelledWithoutLosingInput() {
        let app=launch(); replace(field("article-title",app),"終了しない文章")
        app.typeKey("q",modifierFlags:.command); let dialog=confirmation(app)
        app.typeKey(.escape,modifierFlags:[]); XCTAssertTrue(dialog.draftAbsent(timeout:5))
        XCTAssertEqual(field("article-title",app).value as? String,"終了しない文章")
    }
    func testAllPhotosUnavailableStillOpensFromStoredSelection() {
        let app=launch("photos-missing")
        XCTAssertTrue(app.staticTexts["article-preview-state-1"].draftExists(timeout:5))
        XCTAssertTrue(app.staticTexts["article-preview-state-4"].exists)
        replace(field("article-title",app),"写真なしの本文")
        app.buttons["article-save"].click(); XCTAssertTrue(state(app,contains:"保存しました").draftExists(timeout:5))
        app.buttons["article-mode-preview"].click(); XCTAssertTrue(app.staticTexts["article-rendered-title"].draftExists(timeout:5))
    }
    func testUnconfirmedSelectionKeepsDraftMenuAvailable() {
        let app=launch("empty",open:false)
        XCTAssertTrue(app.buttons["article-open"].draftExists(timeout:5)); XCTAssertFalse(app.buttons["article-open"].isEnabled)
        app.menuBars.menuBarItems["記事"].click(); app.menuItems["保存した下書きを開く"].click()
        XCTAssertTrue(app.buttons["draft-cancel"].draftExists(timeout:5)); XCTAssertFalse(app.buttons["draft-open"].isEnabled)
        app.buttons["draft-cancel"].click(); XCTAssertTrue(app.buttons["article-open"].exists)
    }
}
