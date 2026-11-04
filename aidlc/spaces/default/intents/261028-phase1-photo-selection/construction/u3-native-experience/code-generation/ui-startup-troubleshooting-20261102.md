# UI試験の起動状態の安定化（2026-11-02）

## 対象と原因

承認済みU3計画の試験fixture・ランナー準備の範囲で、`HitotsuzuriUITests/NativeInputTests.swift` の共通 `launch()` のみ修正した。製品ソース、試験の業務操作・期待値、検証スクリプトは変更していない。折り畳み時の非表示子フォルダ選択の既知問題は、人の判断どおり保留を維持する。

先行する `.build/Native-20261102-223406-51134.xcresult` は184件中178件成功、UI6件が親Aの起動待機で失敗した。先頭のCommand試験・狭幅試験は成功していた。

共通起動直後にウィンドウ寸法と狭幅用 `region-picker` の有無を一時記録して単独Runner試験を実行した。実測は `frame=(260,204,771,664)`、`compact=true`。親A待機が実際に失敗した。狭幅試験が保存したウィンドウ寸法を次の起動が引き継ぎ、初期の写真領域ではフォルダが表示されないことが原因だった。キーボード処理の回帰とは区別する。

## 修正と確認

各fixture起動で、ウィンドウ存在待機後に実際の右下角ドラッグで1100×740ポイントを目標に通常幅へ戻す。幅が820ポイントを超えることを検証し、その後に従来の親A存在検証・実キーボード操作・Command操作へ進む。業務モデルを直接操作せず、OS設定やUserDefaultsの一括削除も行わない。データは従来のDebug専用合成fixtureのままで、個人の写真へのアクセスはない。寸法を記録した一時診断printは最終ソースから除去した。

### 診断

```sh
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/NativeInputTests/testRunnerLaunchesSyntheticFoldersOnly -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/Native-Startup-Diagnosis2-20261102.xcresult CODE_SIGN_IDENTITY=- test
```

実assertion失敗1件、exit65。上記寸法と狭幅領域を記録。最初の診断試行 `.build/Native-Startup-Diagnosis-20261102.xcresult` は一時printの引用符の構文誤りによるビルド失敗であり、実行時の失敗証拠には含めない。直ちに構文を修正して上記を実行した。

### 対象試験

```sh
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/NativeInputTests/testCompactRegionSwitchKeepsSelectionAndExpandedFolders -only-testing:HitotsuzuriUITests/NativeInputTests/testRunnerLaunchesSyntheticFoldersOnly -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/Native-Startup-Green-20261102.xcresult CODE_SIGN_IDENTITY=- test
```

保存済み狭幅状態から開始。Compact、Runnerの順に2件成功、exit0。Compact自身の起動と、Compactが再保存した狭幅からの次回起動の両方を確認した。

### 承認済み全体検証

```sh
bash scripts/verify-native.sh
xcrun xcresulttool get test-results summary --path .build/Native-20261102-224338-54127.xcresult --format json
```

スクリプトexit0。結果バンドルは `/Users/yokochie/works/yokochie/hitotsuzuri/.build/Native-20261102-224338-54127.xcresult`。結果summaryで全184件成功、失敗0、スキップ0（U1/U2/U3の176件とUI8件）。スクリプト内の `swift scripts/check-coverage.swift` により、製品全体1301/1457行＝89.29%、80%条件を満たした。除外・閾値の変更はない。

## 残る確認と凍結

利用者による通常アプリでのキーボード操作の再確認、VoiceOver、配色、実キャプチャによる性能確認など、従来の未確認項目をこの試験成功で代替しない。実写真の基本操作についての既存の利用者報告は維持する。今回のソース変更は共通試験起動処理のみ。本書とソースを全体検証後に凍結し、凍結済みcode-summary/source-manifest等の整合は主担当へ引き継ぐ。
