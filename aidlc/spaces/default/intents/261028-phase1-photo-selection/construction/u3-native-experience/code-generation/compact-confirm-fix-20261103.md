# 本人requested修正: 狭幅での確定到達

本人38ec67b9の報告を受け、承認済みキーボード到達の範囲で直接修正する。新計画・再承認・reopen等の状態操作は行わない。通常幅のFolder→Album→Photoと逆Tab、4枚未満でのdisabled、既知子折り畳み問題の現状継続判断を保持する。変更前は全201件・90.12%。

## RunnerとRed（製品修正前に記録）

CompactConfirm-Runner-20261103.xcresultで合成UI runner1件成功、exit0を確認後、狭幅で4枚を実キー選択する3回帰を追加した。

```sh
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/NativeInputTests/testCompactPhotoTabConfirmAndShiftTabReturnCanSave -only-testing:HitotsuzuriUITests/NativeInputTests/testCompactAlbumTabCanActivateEnabledConfirm -only-testing:HitotsuzuriUITests/NativeInputTests/testCompactConfirmShiftTabReturnsToAlbumRow -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/CompactConfirm-Red-20261103.xcresult CODE_SIGN_IDENTITY=- test
```

exit65。summaryで2失敗・1成功、skip0。Album画面の前進Tab→Spaceで保存へ到達しない。Photo画面のTab→Shift+Tab復帰後Spaceで直前の写真を解除できない（line24）。一方、Album側のTab→Shift+Tab→Downという系列は既存実装でも成功した。ただし、この成功だけでは最初のTabで確定に到達した証拠にならない。系列の成功と確定への到達を区別する。

観測は実保存メッセージ、枚数、4枠とDown後の別Album枚数のみで、AX焦点probeや業務関数直呼びは使わない。追加でPhotoの前進Tab→Spaceだけの回帰も製品修正前に用意する。fixture Aの12枚とメモリ保存を用い、実Photos/個人保存領域/OS設定へ触れない。

## 最小Green

狭幅かつcanConfirm時のAlbum前進Tabは、非表示の写真画面へ切り替えず確定へ移す。Photoからも同じ確定焦点入口を使い、未完了の領域復帰要求を無効化する。確定の逆Tabは狭幅だけ現在のPaneと記憶IDへ戻す。presentation.regionを書き換えず、同じAlbumを再選択しない。通常幅とdisabled分岐、photoGrid.onAppear自体は変更していない。

```sh
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/NativeInputTests/testCompactPhotoTabConfirmAndShiftTabReturnCanSave -only-testing:HitotsuzuriUITests/NativeInputTests/testCompactPhotoTabCanActivateEnabledConfirm -only-testing:HitotsuzuriUITests/NativeInputTests/testCompactAlbumTabCanActivateEnabledConfirm -only-testing:HitotsuzuriUITests/NativeInputTests/testCompactConfirmShiftTabReturnsToAlbumRow -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/CompactConfirm-Green-20261103.xcresult CODE_SIGN_IDENTITY=- test
```

exit0、4件成功。Photo/Album各PaneからTab→Spaceで保存、確定から逆TabでPhotoの直前写真を解除/再選択して再保存、Albumへ戻りDownで別Albumへ切替を確認した。Photo前進だけの新試験はGreen時にも成功したが、修正前の同経路単独の失敗を確認したとは記録しない。onAppearが確定焦点を奪ったと断定する証拠はなく、根拠のないViewライフサイクル変更を追加していない。

## 全体結果と凍結

```sh
bash scripts/verify-native.sh
xcrun xcresulttool get test-results summary --path .build/Native-20261103-234223-36633.xcresult --format json
```

全体コマンドは一度実行しexit0、全205件成功・失敗0・skip0（既存201＋新規UI4）。絶対結果 /Users/yokochie/works/yokochie/hitotsuzuri/.build/Native-20261103-234223-36633.xcresult。既存計測器で全製品1474/1634行＝90.21%、PickerContent568/580。分母・80%・既存assertion・検証スクリプトの意味を変えていない。全体開始後のsource変更なし。

実source変更はPickerContent.swiftとNativeInputTests.swiftの2パス。既存unitのmanifestは両パスを既に含み、今回新attemptや新manifestへ作り直していない。plan/承認/workflow/reviewの操作も行わず、本人requested修正としてこの記録を引き継ぐ。通常幅と4枚未満disabledを含む既存回帰はすべて成功、既知子折り畳み問題は無変更。修正後の本人確認・VoiceOver/実画面性能等は未確認を保持する。sourceと今回記録を凍結する。
