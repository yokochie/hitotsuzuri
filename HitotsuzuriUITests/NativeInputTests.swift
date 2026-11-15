import XCTest

final class NativeInputTests:XCTestCase {
    @MainActor private func compactWithFourSelected()->XCUIApplication {
        let app=launch(); openAlbum(app)
        recordInputStage("album-open",app)
        app.typeKey(.tab,modifierFlags:[]); expectInputFocus("photo:1",stage:"photo-tab-entry",app)
        app.typeKey(.space,modifierFlags:[]); expectSelectionCount(1,stage:"space-1",app)
        for number in 2...4 {
            app.typeKey(.rightArrow,modifierFlags:[])
            expectInputFocus("photo:\(number)",stage:"right-\(number)",app)
            app.typeKey(.space,modifierFlags:[])
            expectSelectionCount(number,stage:"space-\(number)",app)
            XCTAssertTrue(app.otherElements["selection-slot-\(number)"].label.contains("写真 \(number)"))
        }
        XCTAssertTrue(app.staticTexts["4 / 4枚"].waitForExistence(timeout:3))
        let window=app.windows.firstMatch
        let corner=window.coordinate(withNormalizedOffset:CGVector(dx:1,dy:1)).withOffset(CGVector(dx:-1,dy:-1))
        corner.click(forDuration:0.2,thenDragTo:window.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:760,dy:660)))
        XCTAssertTrue(app.radioGroups["region-picker"].waitForExistence(timeout:3))
        expectInputFocus("photo:4",stage:"compact-photo-restoration",app)
        XCTAssertTrue(app.buttons["selection-confirm"].isEnabled)
        return app
    }
    @MainActor private func inputDiagnostic(_ app:XCUIApplication)->String {
        app.descendants(matching:.any)["picker-input-diagnostic"].value as? String ?? "diagnostic-unavailable"
    }
    @MainActor private func recordInputStage(_ stage:String,_ app:XCUIApplication) {
        print("Native input stage=\(stage) \(inputDiagnostic(app))")
    }
    @MainActor private func expectInputFocus(_ expected:String,stage:String,_ app:XCUIApplication) {
        let diagnostic=app.descendants(matching:.any)["picker-input-diagnostic"]
        if (diagnostic.value as? String)?.contains("focus=\(expected);") == true {
            recordInputStage(stage,app); return
        }
        let predicate=NSPredicate(format:"value CONTAINS %@","focus=\(expected);")
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:predicate,object:diagnostic)],timeout:3),.completed,"\(stage): \(inputDiagnostic(app))")
        recordInputStage(stage,app)
    }
    @MainActor private func expectSelectionCount(_ count:Int,stage:String,_ app:XCUIApplication) {
        let selected=app.staticTexts["\(count) / 4枚"]
        XCTAssertTrue(selected.exists || selected.waitForExistence(timeout:3),"\(stage): \(inputDiagnostic(app))")
        recordInputStage(stage,app)
    }
    @MainActor private func expectSaved(_ app:XCUIApplication) {
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"identifier == %@ AND value CONTAINS %@","selection-status","保存しました")).firstMatch.waitForExistence(timeout:3))
    }
    @MainActor func testCompactPhotoTabConfirmAndShiftTabReturnCanSave() {
        let app=compactWithFourSelected()
        app.typeKey(.tab,modifierFlags:[])
        app.typeKey(.tab,modifierFlags:.shift)
        app.typeKey(.space,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["3 / 4枚"].waitForExistence(timeout:3))
        XCTAssertTrue(app.otherElements["selection-slot-1"].label.contains("写真 1"))
        XCTAssertTrue(app.otherElements["selection-slot-3"].label.contains("写真 3"))
        app.typeKey(.space,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["4 / 4枚"].waitForExistence(timeout:3))
        app.typeKey(.tab,modifierFlags:[]); app.typeKey(.space,modifierFlags:[])
        expectSaved(app)
    }
    @MainActor func testCompactPhotoTabCanActivateEnabledConfirm() {
        let app=compactWithFourSelected()
        app.typeKey(.tab,modifierFlags:[]); app.typeKey(.space,modifierFlags:[])
        expectSaved(app)
    }
    @MainActor func testCompactAlbumTabCanActivateEnabledConfirm() {
        let app=compactWithFourSelected()
        app.radioGroups["region-picker"].radioButtons["アルバム"].click()
        app.typeKey(.tab,modifierFlags:[]); app.typeKey(.space,modifierFlags:[])
        expectSaved(app)
    }
    @MainActor func testCompactConfirmShiftTabReturnsToAlbumRow() {
        let app=compactWithFourSelected()
        app.radioGroups["region-picker"].radioButtons["アルバム"].click()
        app.typeKey(.tab,modifierFlags:[]); app.typeKey(.tab,modifierFlags:.shift)
        app.typeKey(.downArrow,modifierFlags:[]); app.typeKey(.tab,modifierFlags:[])
        expectPhotoCount(8,app)
        XCTAssertTrue(app.staticTexts["0 / 4枚"].exists)
    }
    @MainActor private func expectPhotoCount(_ count:Int,_ app:XCUIApplication,file:StaticString=#filePath,line:UInt=#line) {
        let grid=app.descendants(matching:.any).matching(NSPredicate(format:"identifier == %@ AND value == %@","photo-grid","\(count)枚")).firstMatch
        XCTAssertTrue(grid.waitForExistence(timeout:3),"実アルバムの写真枚数が\(count)枚へ追随する",file:file,line:line)
    }
    @MainActor func testAlbumUpDownAfterTabChangesFirstMiddleLastAndPhotos() {
        let app=launch(); app.staticTexts["テスト親A"].click()
        app.typeKey(.tab,modifierFlags:[]); expectPhotoCount(12,app)
        app.typeKey(.downArrow,modifierFlags:[]); expectPhotoCount(8,app)
        app.typeKey(.downArrow,modifierFlags:[]); expectPhotoCount(4,app)
        app.typeKey(.downArrow,modifierFlags:[]); expectPhotoCount(4,app)
        app.typeKey(.upArrow,modifierFlags:[]); expectPhotoCount(8,app)
        app.typeKey(.upArrow,modifierFlags:[]); expectPhotoCount(12,app)
        app.typeKey(.upArrow,modifierFlags:[]); expectPhotoCount(12,app)
    }
    @MainActor func testAlbumArrowsAfterReverseTabAndReentryKeepSameAlbumDraft() {
        let app=launch(); app.staticTexts["テスト親A"].click()
        app.typeKey(.tab,modifierFlags:[]); expectPhotoCount(12,app)
        app.typeKey(.downArrow,modifierFlags:[]); expectPhotoCount(8,app)
        app.typeKey(.tab,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["0 / 4枚"].exists)
        app.typeKey(.space,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["1 / 4枚"].waitForExistence(timeout:3))
        app.typeKey(.tab,modifierFlags:.shift); app.typeKey(.tab,modifierFlags:.shift)
        app.typeKey(.tab,modifierFlags:[])
        expectPhotoCount(8,app); XCTAssertTrue(app.staticTexts["1 / 4枚"].exists)
        app.typeKey(.downArrow,modifierFlags:[]); expectPhotoCount(4,app)
        XCTAssertTrue(app.staticTexts["0 / 4枚"].exists)
        app.typeKey(.upArrow,modifierFlags:[]); expectPhotoCount(8,app)
    }
    @MainActor func testAlbumArrowsInCompactAfterMouseSelectionFollowPhotos() {
        let app=launch(); app.staticTexts["テスト親A"].click(); app.staticTexts["テストアルバムC"].click()
        expectPhotoCount(8,app)
        recordInputStage("mouse-album-C",app)
        expectInputFocus("albums",stage:"mouse-album-C-focus",app)
        let window=app.windows.firstMatch
        let corner=window.coordinate(withNormalizedOffset:CGVector(dx:1,dy:1)).withOffset(CGVector(dx:-1,dy:-1))
        corner.click(forDuration:0.2,thenDragTo:window.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:760,dy:660)))
        XCTAssertTrue(app.radioGroups["region-picker"].waitForExistence(timeout:3))
        expectInputFocus("albums",stage:"compact-album-restoration",app)
        app.typeKey(.downArrow,modifierFlags:[]); recordInputStage("compact-album-down",app)
        app.typeKey(.tab,modifierFlags:[]); expectPhotoCount(4,app)
        app.typeKey(.tab,modifierFlags:.shift); expectInputFocus("albums",stage:"compact-album-backtab",app)
        app.typeKey(.upArrow,modifierFlags:[]); recordInputStage("compact-album-up",app)
        app.typeKey(.tab,modifierFlags:[]); expectPhotoCount(8,app)
        app.typeKey(.tab,modifierFlags:.shift); app.typeKey(.upArrow,modifierFlags:[])
        app.typeKey(.tab,modifierFlags:[]); expectPhotoCount(12,app)
        XCTAssertTrue(app.staticTexts["0 / 4枚"].exists)
    }
    @MainActor func testEmptyAlbumArrowsDoNotChooseOrLoadPhotos() {
        let app=launch()
        let albums=app.descendants(matching:.any).matching(identifier:"album-list").firstMatch
        XCTAssertTrue(albums.exists); albums.click()
        app.typeKey(.downArrow,modifierFlags:[]); app.typeKey(.upArrow,modifierFlags:[])
        XCTAssertEqual(app.buttons.matching(identifier:"photo-cell").count,0)
        XCTAssertFalse(app.staticTexts["テストアルバムA"].exists)
        XCTAssertTrue(app.staticTexts["0 / 4枚"].exists)
    }
    @MainActor func testTabEntrySelectsFirstFolderAndAlbumButOnlyFocusesPhoto() {
        let app=launch()
        XCTAssertFalse(app.staticTexts["テストアルバムA"].exists)
        XCTAssertEqual(app.buttons.matching(identifier:"photo-cell").count,0)
        app.typeKey(.tab,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["テストアルバムA"].waitForExistence(timeout:3))
        app.typeKey(.tab,modifierFlags:[])
        XCTAssertTrue(app.buttons.matching(identifier:"photo-cell").element(boundBy:0).waitForExistence(timeout:3))
        app.typeKey(.tab,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["0 / 4枚"].exists)
        app.typeKey(.space,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["1 / 4枚"].waitForExistence(timeout:3))
        XCTAssertTrue(app.otherElements["selection-slot-1"].label.contains("写真 1"))
    }
    @MainActor func testTabIntoUnselectedAlbumSelectsFirstWithoutPhotoSelection() {
        let app=launch(); app.staticTexts["テスト親A"].click()
        XCTAssertTrue(app.staticTexts["テストアルバムA"].waitForExistence(timeout:3))
        XCTAssertEqual(app.buttons.matching(identifier:"photo-cell").count,0)
        app.typeKey(.tab,modifierFlags:[])
        XCTAssertTrue(app.buttons.matching(identifier:"photo-cell").element(boundBy:0).waitForExistence(timeout:3))
        XCTAssertTrue(app.staticTexts["0 / 4枚"].exists)
    }
    @MainActor func testTabReentryPreservesMultipleFoldersAlbumAndPhotoDraft() {
        let app=launch(); app.staticTexts["テスト親A"].click()
        XCUIElement.perform(withKeyModifiers:.command) {app.staticTexts["テスト親B"].click()}
        XCTAssertTrue(app.staticTexts["テストアルバムB"].waitForExistence(timeout:3))
        app.staticTexts["テストアルバムB"].click()
        app.typeKey(.tab,modifierFlags:[]); app.typeKey(.space,modifierFlags:[])
        app.typeKey(.rightArrow,modifierFlags:[]); app.typeKey(.space,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["2 / 4枚"].waitForExistence(timeout:3))
        app.typeKey(.tab,modifierFlags:.shift); app.typeKey(.tab,modifierFlags:.shift)
        XCTAssertTrue(app.staticTexts["テストアルバムA"].exists)
        XCTAssertTrue(app.staticTexts["テストアルバムB"].exists)
        XCTAssertTrue(app.staticTexts["2 / 4枚"].exists)
        app.typeKey(.tab,modifierFlags:[])
        app.typeKey(.space,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["2 / 4枚"].exists)
        app.typeKey(.tab,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["2 / 4枚"].exists)
        app.typeKey(.space,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["1 / 4枚"].waitForExistence(timeout:3))
        XCTAssertTrue(app.otherElements["selection-slot-1"].label.contains("写真 1"))
    }
    @MainActor func testReverseTabSelectsUnselectedFolderWithoutInitialMouseSelection() {
        let app=launch()
        XCTAssertFalse(app.staticTexts["テストアルバムA"].exists)
        let albums=app.descendants(matching:.any).matching(identifier:"album-list").firstMatch
        XCTAssertTrue(albums.exists); albums.click()
        XCTAssertFalse(app.staticTexts["テストアルバムA"].exists)
        app.typeKey(.tab,modifierFlags:.shift)
        XCTAssertTrue(app.staticTexts["テストアルバムA"].waitForExistence(timeout:3))
    }
    @MainActor func testCompactTabSelectsUnselectedAlbumButPhotoNeedsSpace() {
        let app=launch(); app.staticTexts["テスト親A"].click()
        let window=app.windows.firstMatch
        let corner=window.coordinate(withNormalizedOffset:CGVector(dx:1,dy:1)).withOffset(CGVector(dx:-1,dy:-1))
        corner.click(forDuration:0.2,thenDragTo:window.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:760,dy:660)))
        let switcher=app.radioGroups["region-picker"]
        XCTAssertTrue(switcher.waitForExistence(timeout:3)); switcher.radioButtons["アルバム"].click()
        XCTAssertTrue(app.staticTexts["テストアルバムA"].exists)
        XCTAssertEqual(app.buttons.matching(identifier:"photo-cell").count,0)
        app.typeKey(.tab,modifierFlags:[])
        app.typeKey(.tab,modifierFlags:[])
        XCTAssertTrue(app.buttons.matching(identifier:"photo-cell").element(boundBy:0).waitForExistence(timeout:3))
        XCTAssertTrue(app.staticTexts["0 / 4枚"].exists)
        app.typeKey(.space,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["1 / 4枚"].waitForExistence(timeout:3))
    }
    @MainActor private func openAlbum(_ app:XCUIApplication) {
        app.staticTexts["テスト親A"].click(); app.staticTexts["テストアルバムA"].click()
        XCTAssertTrue(app.buttons.matching(identifier:"photo-cell").element(boundBy:0).waitForExistence(timeout:3))
    }
    @MainActor func testSingleTabFromAlbumOperatesPhotoAndShiftTabReturns() {
        let app=launch(); openAlbum(app)
        recordInputStage("wide-album-before-tab",app)
        expectInputFocus("albums",stage:"wide-mouse-album-focus",app)
        app.typeKey(.tab,modifierFlags:[]); expectInputFocus("photo:1",stage:"wide-tab-photo",app)
        app.typeKey(.space,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["1 / 4枚"].waitForExistence(timeout:3))
        XCTAssertTrue(app.otherElements["selection-slot-1"].label.contains("写真 1"))
        app.typeKey(.tab,modifierFlags:.shift)
        app.typeKey(.tab,modifierFlags:[]); app.typeKey(.space,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["0 / 4枚"].waitForExistence(timeout:3))
    }
    @MainActor func testPhotoTabWithDisabledConfirmReachesOperableFolder() {
        let app=launch(); openAlbum(app)
        for _ in 0..<16 {
            app.typeKey(.tab,modifierFlags:[]); app.typeKey(.space,modifierFlags:[])
            if app.staticTexts["1 / 4枚"].exists {break}
        }
        XCTAssertTrue(app.staticTexts["1 / 4枚"].exists)
        XCTAssertFalse(app.buttons["selection-confirm"].isEnabled)
        app.typeKey(.tab,modifierFlags:[]); app.typeKey(.rightArrow,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["テスト子A"].waitForExistence(timeout:3))
        XCTAssertTrue(app.staticTexts["1 / 4枚"].exists)
    }
    @MainActor func testTabFromFolderOperatesAlbum() {
        let app=launch(); app.staticTexts["テスト親A"].click()
        app.typeKey(.tab,modifierFlags:[]); app.typeKey(.downArrow,modifierFlags:[])
        XCTAssertTrue(app.buttons.matching(identifier:"photo-cell").element(boundBy:0).waitForExistence(timeout:3))
    }
    @MainActor func testCompactEmptyRegionRetainsOperableRegionSwitch() {
        let app=launch(),window=app.windows.firstMatch
        let corner=window.coordinate(withNormalizedOffset:CGVector(dx:1,dy:1)).withOffset(CGVector(dx:-1,dy:-1))
        corner.click(forDuration:0.2,thenDragTo:window.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:760,dy:660)))
        let switcher=app.radioGroups["region-picker"]
        XCTAssertTrue(switcher.waitForExistence(timeout:3))
        switcher.radioButtons["アルバム"].click()
        app.typeKey(.leftArrow,modifierFlags:[])
        XCTAssertEqual(String(describing:switcher.radioButtons["フォルダ"].value ?? ""),"1")
        app.typeKey(.downArrow,modifierFlags:[])
        app.typeKey(.rightArrow,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["テスト子A"].waitForExistence(timeout:3))
    }
    @MainActor func testPhotoTabWithEnabledConfirmCanSaveBySpace() {
        let app=launch(); openAlbum(app)
        app.typeKey(.tab,modifierFlags:[]); app.typeKey(.space,modifierFlags:[])
        for _ in 0..<3 {app.typeKey(.rightArrow,modifierFlags:[]); app.typeKey(.space,modifierFlags:[])}
        XCTAssertTrue(app.staticTexts["4 / 4枚"].waitForExistence(timeout:3))
        XCTAssertTrue(app.buttons["selection-confirm"].isEnabled)
        app.typeKey(.tab,modifierFlags:[]); app.typeKey(.space,modifierFlags:[])
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"identifier == %@ AND value CONTAINS %@","selection-status","保存しました")).firstMatch.waitForExistence(timeout:3))
    }
    override func setUpWithError() throws {
        #if !DEBUG
        throw XCTSkip("UI fixtureはDebug専用です。Releaseではアプリを起動しません。")
        #endif
    }
    @MainActor func launch(randomAlbumID:String?=nil)->XCUIApplication {
        continueAfterFailure=false
        let app=FixtureLaunch.picker(test:self,randomAlbumID:randomAlbumID)
        let window=app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout:10))
        // 前の狭幅試験が保存したフレームからも開始できるよう、試験ごとに
        // 実ウィンドウを通常幅へ戻す。利用者の設定や業務状態は書き換えない。
        let corner=window.coordinate(withNormalizedOffset:CGVector(dx:1,dy:1)).withOffset(CGVector(dx:-1,dy:-1))
        let normal=window.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:1100,dy:740))
        corner.click(forDuration:0.2,thenDragTo:normal)
        XCTAssertGreaterThan(window.frame.width,820)
        XCTAssertTrue(app.staticTexts["テスト親A"].waitForExistence(timeout:10))
        return app
    }
    @MainActor func testRunnerLaunchesSyntheticFoldersOnly() {
        let app=launch()
        XCTAssertTrue(app.staticTexts["テスト親B"].exists)
        XCTAssertFalse(app.buttons["permission-allow"].exists)
        XCTAssertTrue(app.buttons["selection-confirm"].exists)
    }
    @MainActor func testRandomAlbumDrawIsAvailableOnlyForDisplayedAlbums() {
        let app=launch(randomAlbumID:"album-c")
        let draw=app.buttons["album-random-draw"]
        XCTAssertTrue(draw.exists)
        XCTAssertFalse(draw.isEnabled)
        app.staticTexts["テスト親A"].click()
        XCTAssertTrue(app.staticTexts["テストアルバムC"].waitForExistence(timeout:3))
        XCTAssertTrue(draw.isEnabled)
        draw.click()
        expectPhotoCount(8,app)
    }
    @MainActor func testRandomAlbumDrawConfirmsDraftLossAndStaysInCompactAlbumList() {
        let app=launch(randomAlbumID:"album-c")
        openAlbum(app)
        app.buttons.matching(identifier:"photo-cell").element(boundBy:0).click()
        expectSelectionCount(1,stage:"random-album-before-draw",app)

        let window=app.windows.firstMatch
        let corner=window.coordinate(withNormalizedOffset:CGVector(dx:1,dy:1)).withOffset(CGVector(dx:-1,dy:-1))
        corner.click(forDuration:0.2,thenDragTo:window.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:760,dy:660)))
        let switcher=app.radioGroups["region-picker"]
        XCTAssertTrue(switcher.waitForExistence(timeout:3))
        switcher.radioButtons["アルバム"].click()

        let draw=app.buttons["album-random-draw"]
        XCTAssertTrue(draw.waitForExistence(timeout:3))
        draw.click()
        let cancel=window.buttons["album-random-cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout:3))
        cancel.click()
        expectSelectionCount(1,stage:"random-album-cancelled",app)
        XCTAssertTrue(inputDiagnostic(app).contains("albumRow=1;"))

        draw.click()
        let confirm=window.buttons["album-random-confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout:3))
        confirm.click()
        expectSelectionCount(0,stage:"random-album-applied",app)
        XCTAssertTrue(draw.exists)
        XCTAssertTrue(inputDiagnostic(app).contains("albumRow=2;"))
        XCTAssertFalse(app.descendants(matching:.any).matching(identifier:"photo-grid").firstMatch.exists)
        switcher.radioButtons["写真"].click()
        expectPhotoCount(8,app)
    }
    @MainActor func testRightExpandsAndLeftCollapsesFolder() {
        let app=launch()
        app.staticTexts["テスト親A"].click()
        app.typeKey(.rightArrow,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["テスト子A"].waitForExistence(timeout:3))
        app.typeKey(.leftArrow,modifierFlags:[])
        XCTAssertFalse(app.staticTexts["テスト子A"].exists)
    }
    @MainActor func testCommandClickAddsAndRemovesTargetFolder() {
        let app=launch()
        app.staticTexts["テスト親A"].click()
        XCTAssertTrue(app.staticTexts["テストアルバムA"].waitForExistence(timeout:3))
        XCUIElement.perform(withKeyModifiers:.command) {app.staticTexts["テスト親B"].click()}
        XCTAssertTrue(app.staticTexts["テストアルバムA"].exists)
        XCTAssertTrue(app.staticTexts["テストアルバムB"].waitForExistence(timeout:3))
        XCUIElement.perform(withKeyModifiers:.command) {app.staticTexts["テスト親A"].click()}
        XCTAssertFalse(app.staticTexts["テストアルバムA"].exists)
        XCTAssertTrue(app.staticTexts["テストアルバムB"].exists)
    }
    @MainActor func testPhotoKeyboardSpaceArrowAndTabExit() {
        let app=launch()
        app.staticTexts["テスト親A"].click()
        app.staticTexts["テストアルバムA"].click()
        let first=app.buttons.matching(identifier:"photo-cell").element(boundBy:0)
        XCTAssertTrue(first.waitForExistence(timeout:3))
        // マウスで写真を押さず、アルバムからTabで写真へ到達する。
        for _ in 1...16 {
            app.typeKey(.tab,modifierFlags:[])
            app.typeKey(.space,modifierFlags:[])
            if app.staticTexts["1 / 4枚"].exists {break}
        }
        XCTAssertTrue(app.staticTexts["1 / 4枚"].waitForExistence(timeout:3))
        XCTAssertTrue((first.value as? String)?.contains("選択順 1") ?? false)
        XCTAssertTrue(app.otherElements["selection-slot-1"].label.contains("写真 1"))
        app.typeKey(.rightArrow,modifierFlags:[])
        app.typeKey(.space,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["2 / 4枚"].waitForExistence(timeout:3))
        app.typeKey(.tab,modifierFlags:[])
        app.typeKey(.space,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["2 / 4枚"].exists)
    }
    @MainActor func testParentChildCommandSelectionAndSingleSelectionStayIndependent() {
        let app=launch()
        app.staticTexts["テスト親A"].click(); app.typeKey(.rightArrow,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["テスト子A"].waitForExistence(timeout:3))
        XCUIElement.perform(withKeyModifiers:.command) {app.staticTexts["テスト子A"].click()}
        XCUIElement.perform(withKeyModifiers:.command) {app.staticTexts["テスト親B"].click()}
        XCTAssertTrue(app.staticTexts["テストアルバムA"].exists); XCTAssertTrue(app.staticTexts["テストアルバムB"].exists)
        XCUIElement.perform(withKeyModifiers:.command) {app.staticTexts["テスト親A"].click()}
        XCTAssertFalse(app.staticTexts["テストアルバムA"].exists)
        XCTAssertTrue(app.staticTexts["テストアルバムC"].exists); XCTAssertTrue(app.staticTexts["テストアルバムE"].exists); XCTAssertTrue(app.staticTexts["テストアルバムB"].exists)
        app.staticTexts["テスト親B"].click()
        XCTAssertTrue(app.staticTexts["テストアルバムC"].waitForNonExistence(timeout:3)); XCTAssertTrue(app.staticTexts["テストアルバムB"].exists)
    }
    @MainActor func testDeepExpansionCollapseAndReturn() {
        let app=launch()
        app.staticTexts["テスト親A"].click(); app.typeKey(.rightArrow,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["テスト子A"].waitForExistence(timeout:3))
        app.typeKey(.downArrow,modifierFlags:[]); app.typeKey(.rightArrow,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["テスト孫A"].waitForExistence(timeout:3))
        app.typeKey(.leftArrow,modifierFlags:[])
        XCTAssertFalse(app.staticTexts["テスト孫A"].exists)
        app.typeKey(.upArrow,modifierFlags:[]); app.typeKey(.leftArrow,modifierFlags:[])
        XCTAssertFalse(app.staticTexts["テスト子A"].exists)
        app.typeKey(.rightArrow,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["テスト子A"].waitForExistence(timeout:3))
    }
    @MainActor func testPhotoOrderFifthRefusalAndMouseDeselection() {
        let app=launch(); app.staticTexts["テスト親A"].click(); app.staticTexts["テストアルバムA"].click()
        let photos=app.buttons.matching(identifier:"photo-cell")
        XCTAssertTrue(photos.element(boundBy:0).waitForExistence(timeout:3))
        for i in 1...5 {
            let photo=photos.matching(NSPredicate(format:"label == %@", "写真 \(i)")).firstMatch
            photo.click()
            XCTAssertTrue(app.staticTexts["\(min(i,4)) / 4枚"].waitForExistence(timeout:3))
        }
        XCTAssertTrue(app.staticTexts["4 / 4枚"].exists)
        XCTAssertTrue((app.staticTexts["selection-status"].value as? String)?.contains("4枚まで") ?? false)
        for slot in 1...4 {XCTAssertTrue(app.otherElements["selection-slot-\(slot)"].label.contains("写真 \(slot)"))}
        photos.matching(NSPredicate(format:"label == %@", "写真 2")).firstMatch.click(); XCTAssertTrue(app.staticTexts["3 / 4枚"].exists)
        XCTAssertTrue(app.otherElements["selection-slot-2"].label.contains("写真 3"))
    }
    @MainActor func testCompactRegionSwitchKeepsSelectionAndExpandedFolders() {
        let app=launch()
        app.staticTexts["テスト親A"].click(); app.typeKey(.rightArrow,modifierFlags:[])
        app.staticTexts["テストアルバムA"].click()
        let photos=app.buttons.matching(identifier:"photo-cell")
        XCTAssertTrue(photos.element(boundBy:0).waitForExistence(timeout:3)); photos.element(boundBy:0).click()
        let window=app.windows.firstMatch
        let corner=window.coordinate(withNormalizedOffset:CGVector(dx:1,dy:1)).withOffset(CGVector(dx:-1,dy:-1))
        let smaller=window.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:760,dy:660))
        corner.click(forDuration:0.2,thenDragTo:smaller)
        let switcher=app.radioGroups["region-picker"]
        XCTAssertTrue(switcher.waitForExistence(timeout:3)); XCTAssertLessThanOrEqual(window.frame.width,820)
        switcher.radioButtons["フォルダ"].click()
        XCTAssertTrue(app.staticTexts["テスト子A"].exists)
        app.typeKey(.leftArrow,modifierFlags:[])
        XCTAssertFalse(app.staticTexts["テスト子A"].exists)
        app.typeKey(.rightArrow,modifierFlags:[])
        XCTAssertTrue(app.staticTexts["テスト子A"].waitForExistence(timeout:3))
        switcher.radioButtons["アルバム"].click()
        XCTAssertTrue(app.staticTexts["テストアルバムA"].exists)
        switcher.radioButtons["写真"].click()
        XCTAssertTrue(app.staticTexts["1 / 4枚"].exists)
        XCTAssertTrue(app.otherElements["selection-slot-1"].label.contains("写真 1"))
    }
}

