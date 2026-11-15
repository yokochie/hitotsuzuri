import XCTest

@MainActor final class ArticleDraftUITests:ArticleDraftUITestCase {
    override func setUpWithError() throws {continueAfterFailure=false}
    func testEntryAndListLoadingCanComplete() {
        let app=launch("read-delay"), title=field("article-title",app)
        let expectedTitle="Loading keeps this saved title."
        replace(title,expectedTitle)
        XCTAssertEqual(title.value as? String,expectedTitle)
        app.buttons["article-save"].click()
        XCTAssertTrue(state(app,contains:"保存しました").draftExists(timeout:5))
        for (isList,item) in [(false,"選択した写真の記事を開く"),(true,"保存した下書きを開く")] {
            app.buttons["draft-arm-read"].click()
            XCTAssertTrue(app.staticTexts["draft-read-armed"].draftExists(timeout:5))
            app.menuBars.menuBarItems["記事"].click(); app.menuItems[item].click()
            XCTAssertTrue(app.staticTexts["article-loading"].draftExists(timeout:5))
            app.buttons["draft-release-read"].click()
            if isList {
                XCTAssertTrue(app.buttons["draft-cancel"].draftExists(timeout:5))
                app.buttons["draft-cancel"].click()
            }
            XCTAssertTrue(app.staticTexts["article-loading"].draftAbsent(timeout:5))
            XCTAssertTrue(app.textFields["article-title"].exists)
            XCTAssertEqual(app.textFields["article-title"].value as? String,expectedTitle)
        }
    }
    func testCurrentEntryShowsDateCandidateAndNoBodyOrMemoFields() {
        let app=launch(); XCTAssertEqual(field("article-title",app).value as? String,"合成")
        for id in ["article-year","article-month","article-day"] {XCTAssertTrue(field(id,app).exists)}
        let dateState = app.staticTexts["article-date-state"]
        XCTAssertTrue([dateState.label,dateState.value as? String ?? ""].contains("日付候補・未確認"))
        assertRemovedFieldsAreAbsent(app)
        app.buttons["article-save"].click()
        XCTAssertTrue(state(app,contains:"保存しました").draftExists(timeout:5))
        app.buttons["article-mode-preview"].click()
        assertPlaceholderPreview(app)
    }
    private func assertRemovedFieldsAreAbsent(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let ids = ["article-introduction","article-closing","article-location","article-equipment","article-film","article-people"]
            + (1...4).map { "article-photo-\($0)" }
        for id in ids {
            XCTAssertFalse(app.descendants(matching:.any)[id].exists, id, file:file, line:line)
        }
    }
    private func assertPlaceholderPreview(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.staticTexts["【ダミー】導入文です。"].draftExists(timeout:5), file:file, line:line)
        for number in 1...4 {
            XCTAssertTrue(app.staticTexts["【ダミー】写真\(number)の文章です。"].exists, file:file, line:line)
        }
        XCTAssertTrue(app.staticTexts["【ダミー】締めの文章です。"].exists, file:file, line:line)
    }
    func testMenuAndButtonOpenSamePersistedArticle() {
        let app=launch(); replace(field("article-title",app),"同じ記事")
        app.typeKey("s",modifierFlags:.command); XCTAssertTrue(app.staticTexts["下書きを保存しました。"].draftExists(timeout:5))
        app.buttons["article-back"].click()
        app.menuBars.menuBarItems["記事"].click(); app.menuItems["選択した写真の記事を開く"].click()
        XCTAssertEqual(field("article-title",app).value as? String,"同じ記事")
    }
    func testShootingDateSavesAndSurvivesRelaunch() {
        let app=launch()
        let dateFields = [("article-year","2024"),("article-month","2"),("article-day","29")]
        for (id,value) in dateFields {
            let input=field(id,app)
            replace(input,value)
            XCTAssertEqual(input.value as? String,value,"保存前のfixture入力確認: \(id)")
        }
        app.typeKey("s",modifierFlags:.command); XCTAssertTrue(app.staticTexts["下書きを保存しました。"].draftExists(timeout:5))
        app.terminate(); app.launch(); app.buttons["article-open"].click()
        for (id,value) in dateFields { XCTAssertEqual(field(id,app).value as? String,value) }
    }
    func testInvalidRawDateBlocksPreviewAndKeepsInput() {
        let app=launch(); replace(field("article-day",app),"99")
        app.buttons["article-mode-preview"].click()
        XCTAssertEqual(field("article-day",app).value as? String,"99")
        XCTAssertTrue(app.staticTexts["article-date-error"].exists)
        XCTAssertTrue(app.textFields["article-title"].exists)
        XCTAssertFalse(app.staticTexts["article-rendered-title"].exists)
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
        app.buttons["article-save"].click()
        XCTAssertTrue(state(app,contains:"保存しました").draftExists(timeout:5))
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
        openDraft(0,in:draftPicker(app))
        XCTAssertEqual(field("article-title",app).value as? String,"既存の文章1")
        assertRemovedFieldsAreAbsent(app)
        app.buttons["article-mode-preview"].click()
        assertPlaceholderPreview(app)
        XCTAssertFalse(app.staticTexts["再開して保持する文章"].exists)
    }
    func testMultipleCandidatesRequireExplicitChoiceAndCancel() {
        let app=launch("multiple")
        let picker=draftPicker(app)
        let labels=picker.radioButtons.allElementsBoundByIndex.map(\.label)
        XCTAssertEqual(labels.count,2); XCTAssertNotEqual(labels[0],labels[1])
        XCTAssertTrue(labels.allSatisfy {$0.contains("同名記事")})
        XCTAssertFalse(picker.buttons["draft-open"].isEnabled)
        picker.buttons["draft-cancel"].click(); XCTAssertTrue(app.buttons["article-open"].exists)
        XCTAssertFalse(app.textFields["article-title"].exists)
    }
    func testUnavailablePhotoCanRetryWithoutLosingText() {
        let app=launch("photos-missing"); replace(field("article-title",app),"写真なしでも残る")
        let retry=app.buttons["article-retry-2"]
        let requests=app.staticTexts["draft-photo-request-counts"]
        func counts() -> [Int] { (requests.value as? String ?? "").split(separator:",").compactMap { Int($0) } }
        let ready=NSPredicate { _,_ in MainActor.assumeIsolated {
            let initial=counts()
            return initial.count == 4 && initial.allSatisfy { $0 > 0 } && retry.exists && retry.isEnabled
        }}
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:ready,object:nil)],timeout:5),.completed)
        var expected=counts()
        expected[1] += 1
        retry.click()
        let retried=NSPredicate { _,_ in MainActor.assumeIsolated { counts() == expected && retry.isEnabled } }
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:retried,object:nil)],timeout:5),.completed)
        XCTAssertEqual(field("article-title",app).value as? String,"写真なしでも残る")
        XCTAssertTrue(app.staticTexts["article-preview-state-2"].exists)
    }
    func testTabAndShiftTabCanRetryEveryUnavailablePhotoWithoutLosingText() {
        let app=launch("photos-missing"), expected="Keyboard retry text"
        let title=field("article-title",app)
        replace(title,expected); XCTAssertEqual(title.value as? String,expected)
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
        assertRemovedFieldsAreAbsent(app)
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
            for _ in 0..<3 {app.typeKey(.tab,modifierFlags:[])}
            XCTAssertTrue(app.textFields["article-day"].isHittable)
            print("Draft UI measuredContentWidth=\(actual) layout=\(width >= 960 ? "wide" : "narrow") metadataReachable=true")
        }
        app.typeKey("s",modifierFlags:.command); XCTAssertTrue(state(app,contains:"保存しました").draftExists(timeout:5))
        app.terminate(); app.launch(); app.buttons["article-open"].click()
        XCTAssertEqual(field("article-title",app).value as? String,expected)
        assertRemovedFieldsAreAbsent(app)
        app.buttons["article-mode-preview"].click(); XCTAssertTrue(app.staticTexts["article-rendered-title"].draftExists(timeout:5))
        assertPlaceholderPreview(app)
        app.buttons["article-mode-edit"].click()
        replace(field("article-title",app),"再開後のタイトル")
        app.typeKey("s",modifierFlags:.command); XCTAssertTrue(state(app,contains:"保存しました").draftExists(timeout:5))
    }
    func testCommandSaveKeepsLongUnicodeTitle() {
        let app=launch(), title=field("article-title",app)
        let expected=String(repeating:"日本語e\u{301}👩‍👧",count:20)
        replace(title,expected)
        app.typeKey("s",modifierFlags:.command)
        XCTAssertTrue(app.staticTexts["下書きを保存しました。"].draftExists(timeout:5))
        XCTAssertEqual(title.value as? String,expected)
        XCTAssertTrue(app.buttons["article-copy"].isEnabled)
    }
    func testDirtyDraftSelectionDismissesBeforeSingleLeaveConfirmation() {
        let app=launch("multiple")
        openDraft(0,in:draftPicker(app))
        replace(field("article-title",app),"編集継続する文章")
        app.menuBars.menuBarItems["記事"].click(); app.menuItems["保存した下書きを開く"].click()
        openDraft(1,in:draftPicker(app))
        // 閉じる途中の候補シートを確認ダイアログと取り違えない。
        XCTAssertTrue(app.buttons["draft-open"].draftAbsent(timeout:5))
        XCTAssertTrue(app.buttons["編集を続ける"].draftExists(timeout:5))
        let dialog=confirmation(app)
        XCTAssertFalse(app.buttons["draft-open"].exists)
        app.typeKey(.escape,modifierFlags:[])
        XCTAssertTrue(dialog.draftAbsent(timeout:5))
        XCTAssertEqual(field("article-title",app).value as? String,"編集継続する文章")
        XCTAssertFalse(app.buttons["draft-open"].exists)
    }
    func testTabAndShiftTabReachMetadataAndPreviewWithoutSystemSetting() {
        let app=launch()
        field("article-title",app).click()
        app.typeKey(.tab,modifierFlags:[])
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
        for _ in 0..<5 {app.typeKey(.tab,modifierFlags:[])}
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
        let picker=draftPicker(app)
        XCTAssertTrue(picker.buttons["draft-retry"].draftExists(timeout:5)); XCTAssertFalse(picker.buttons["draft-new"].exists)
        XCTAssertTrue(picker.staticTexts.matching(NSPredicate(format:"label CONTAINS %@ OR value CONTAINS %@","読込失敗：1件","読込失敗：1件")).firstMatch.exists)
        picker.buttons["draft-retry"].click()
        XCTAssertEqual(picker.radioButtons.count,1)
        openDraft(0,in:picker)
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
