# U3 TDD証跡

契約sha256:4ba63934ae5f6408d359e3811f73cf0232b97ecb35978a9430d5b1189d83d14f。承認済みU3専用xcodebuildコマンドで各層を実行。XCTestの実行権限を拡張し、環境失敗はRedに数えない。

- 基準: 既存108件成功。12-01-34 xcresult、全製品カバレッジ85.23%。
- Runner: U3 1件成功（12-02-16）。初回のターゲット参照不足は構成修正してから確認し、Redとは数えていない。
- 保存Red: 実ファイルの保存完了直後に認可喪失/呼出しTask取消を注入し、6件中7アサーションが失敗（12-03-02）。ディスクの新確定に対しlastCommittedが旧確定、保存状態がfailedとなることを再現した。

時刻は .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.01_<時刻>-+0900.xcresult を指す。

## 各層の実行

| 層 | Redの実結果 | Green/整理後 |
|---|---|---|
| 保存完了 | 6件中7アサーション失敗、12-03-02 | 6件成功12-03-48。保存後に認可/取消を成功の条件にしない。U1/U2 108件も12-04-00成功 |
| 表示幅 | 640ptへ収まらず760pt、12-04-34 | 以下の状態試験と合わせて成功 |
| 階層/フォーカス | 18件中5アサーション失敗、12-04-59 | 18件成功12-05-51。ID復帰と階層flattenを整理 |
| 操作支援 | 25件中9アサーション失敗、12-06-30 | 25件成功12-07-17。意味の投影をPhotoSemantics、キー移動をGridNavigationへ整理 |
| 資源 | 不要active/queued取消と退出後応答、31件中5アサーション失敗、12-08-35 | 31件成功12-08-59。取消中drainを抑え、同じ生存台帳を使った集計を追加 |
| 測定 | markerのみ/欠測/時刻不一致/負の時間/古い番号/95%判定等、39件中11アサーション失敗、12-09-33 | 39件成功12-10-20。通常無効/不明イベント/現在時刻/不正時刻も追加し44件成功12-11-53 |
| 結合 | 初回から全6境界成功。不足修正のためのRedは発生せず | 50件成功12-12-37。640/820/821/1280pt、長名、領域復帰、保存/再試行/不可画像を実SwiftUIで描画 |

資源試験の初回はテストコードの関数型表記の構文エラーだったためRedに数えていない。先に適用していた自身の資源変更だけを元に戻し、テスト構文を修正して上記の実アサーション失敗を取得してから再適用した。他者の変更は戻していない。

## SDK・測定補助の成立性

- ローカルSDKのSCStream.h 418〜421行で、SCStreamFrameInfoDisplayTimeがwindow serverで表示されたmach absolute timeであることを確認。
- xcrun swiftc -typecheck -parse-as-library -module-cache-path .build/MeasureModuleCache -F .build/DerivedData/Build/Products/Debug scripts/measure-native.swift が成功。
- Swift6モードで補助ツールをビルド成功。コマンドはmanual-verification.mdに記載。
- env DYLD_FRAMEWORK_PATH=.build/DerivedData/Build/Products/Debug .build/measure-native を実行し、**時刻系校正: 一致、numer 125、denom 3**、終了コード0。これはProcessInfo.systemUptimeとmachの同時刻系確認であり、実NSEvent→キャプチャの合格ではない。
- 実フレーム取得/OCRは未実行。キャプチャ権限を自動要求していない。通常起動では測定せず、フレーム/画像を永続保存しない。

## 最終の全体検証

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriU1Tests -only-testing:HitotsuzuriU2Tests -only-testing:HitotsuzuriU3Tests -enableCodeCoverage YES -derivedDataPath .build/DerivedData CODE_SIGN_IDENTITY=- test
swift scripts/check-coverage.swift .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.01_12-14-19-+0900.xcresult
```

U1 60、U2 48、U3 51、全159件成功。全件とカバレッジとも終了コード0。
絶対結果パス: /Users/yokochie/works/yokochie/hitotsuzuri/.build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.01_12-14-19-+0900.xcresult。

| 全製品Swift | 被覆行/対象行 |
|---|---|
| HitotsuzuriApp.swift | 0/7 |
| PickerView.swift | 0/2 |
| Diagnostics.swift | 2/2 |
| FrameMeasurement.swift | 20/20 |
| LocalImageAccess.swift | 153/185 |
| Models.swift | 27/27 |
| NativeMeasurement.swift | 14/14 |
| PhotoLibraryAccess.swift | 38/131 |
| PickerAccessibility.swift | 21/22 |
| PickerContent.swift | 421/476 |
| PickerPresentationState.swift | 39/40 |
| Ports.swift | 37/37 |
| PresentationSnapshot.swift | 29/30 |
| SelectionPersistence.swift | 116/120 |
| SelectionWorkflow.swift | 196/198 |
| 合計 | **1113/1311 = 84.90%** |

App入口・View・実Photosアダプタ・アプリ内の測定本体をすべて分母に含める。除外/閾値変更なし。scripts/measure-native.swiftは通常アプリが呼ばない本人任意の開発者用キャプチャアダプタであり、主判定をCore外へ隠していない。

新しいverify-all.shはbash -n成功、本人の最終コマンド指定は未承認なのでスクリプト本体は未実行。CIは既承認の省略決定を適用。既存CoreSimulator版警告/autoShortcut接続警告はあるが、macOS XCTestは成功。実機の未確認はmanual-verification.mdへ分離した。

## Loop-back 1 — Step22〜26の修正証跡

上記159件/84.90%は修正前の履歴。今回の契約hashは変更なし。承認済み再実装計画だけを実施し、完了済みStep1〜21、U1/U2を保持した。

### RunnerとRed

指定U3コマンドを変更前に実行し51件成功、12-39-23 xcresult。続いてUIの測定入口を内部テストから同じ経路で呼べるようにし、元イベント時刻だけを注入した。選択処理や測定判断はこの時点で変えていない。

- 第1 Red: 55件中10アサーション失敗、12-40-40 xcresult。旧positions-onlyの空選択30回がpassed=trueとなり、5枚目/無効ID/未取得/凍結を実UI入口から呼んでも測定連番が増えた。
- 第2 Red: 61件中18アサーション失敗、12-41-14 xcresult。不変な前後状態、重複通知、不正位置、不連続な状態も受け付けることを追加確認。最初の解除と、変化して元へ戻る正当な操作は正常系として先に固定した。

両Redは実際のXCTestアサーション失敗、実行終了コード65。環境エラーや構文エラーではない。

### GreenとRefactor

- UIは実選択の前後を比較し、採用済みの差だけを渡す。
- 共通MeasurementTransitionで前後の証拠を表す。選択可否の判断はSelectionWorkflowのまま。NativeMeasurementとFrameMeasurementが不変/重複/連続性を検証し、旧positions-only/時刻のみは認定しない。
- HZM2は初回の前状態も明示し、補助ツールが厳密に復号する。同一フレームの4枠・枚数チェックを維持する。
- Green: 61件成功、12-42-43 xcresult。
- 追加結合/整理: U3 68件成功、12-43-19 xcresult。実UI入口から30回の有効変化→マーカー復号→フレーム対応を確認。拒否操作後の連番、初回解除、元の状態への復帰、測定時刻失敗が通常選択を失敗にしないこと、旧/不正マーカーと欠測を検証。
- 以前の95%/時間/欠測/古い番号試験は削除せず、正常入力へ前後状態の証拠を追加して維持した。

### 修正後の全体実行

本人が承認した同じコマンドを内容変更なしで実行:

```bash
bash scripts/verify-all.sh
```

**全176件成功**（U1 60、U2 48、U3 68）、失敗0、終了コード0。
結果: .build/All-20261101-124358-84495.xcresult。
絶対パス: /Users/yokochie/works/yokochie/hitotsuzuri/.build/All-20261101-124358-84495.xcresult。
同スクリプト内の既存check-coverage.swiftが **1168/1359 = 85.95%** を確認し終了コード0。App入口/View/Photosアダプタ/測定Coreを分母に含め、閾値・除外を変更していない。

| 主な変更製品ファイル | 被覆/実行行 |
|---|---|
| FrameMeasurement.swift | 27/27 |
| NativeMeasurement.swift | 47/47 |
| PickerContent.swift | 436/484 |
| 製品全体 | 1168/1359 = 85.95% |

### 公開P-MEASURE再確認

旧プローブはstampを強制unwrapしていた。現在は証拠なし記録が拒否されstampがないため、下記ではif-letで拒否を明示的に扱う。それ以外の30回の空選択とpassed判定を維持した。

```bash
swift -module-cache-path .build/ProbeModuleCache -F .build/DerivedData/Build/Products/Debug -framework HitotsuzuriCore -e 'import Foundation; import HitotsuzuriCore; MainActor.assumeIsolated { let native=NativeMeasurement(enabled:true); var frames=FrameMeasurement(); for _ in 1...30 { native.record(eventSeconds:ProcessInfo.processInfo.systemUptime,positions:[]); if let s=native.stamp { frames.input(sequence:s.sequence,ticks:s.inputTicks); frames.frame(sequence:s.sequence,ticks:s.inputTicks+1,interval:1,selectionMatches:true,calibrated:true) } }; print("unchangedPositions=[] acceptedOperations=\(frames.inputs.count) passed=\(frames.passed)"); if frames.passed { exit(1) } }'
```

実出力: unchangedPositions=[] acceptedOperations=0 passed=false。終了コード0。これは性能合格ではなく、不正な認定を拒否した結果。

### 補助ツールと本人未確認

```bash
xcrun swiftc -swift-version 6 -typecheck -parse-as-library -module-cache-path .build/MeasureModuleCache -F .build/DerivedData/Build/Products/Debug scripts/measure-native.swift
xcrun swiftc -swift-version 6 -parse-as-library -module-cache-path .build/MeasureModuleCache -F .build/DerivedData/Build/Products/Debug -framework HitotsuzuriCore -Xlinker -rpath -Xlinker /Users/yokochie/works/yokochie/hitotsuzuri/.build/DerivedData/Build/Products/Debug scripts/measure-native.swift -o .build/measure-native
env DYLD_FRAMEWORK_PATH=.build/DerivedData/Build/Products/Debug .build/measure-native
```

すべて終了コード0。校正出力: 時刻系校正: 一致、numer 125、denom 3。
実キャプチャ/OCR、100枚以上/30操作/95%以上200ms、10往復、キーボード/VoiceOver、コントラスト、実Photosは引き続き本人未確認。OS許可は要求していない。通常ログや個人画像を追加していない。Build and Testの記録とLoop-back Logは変更していない。

## Loop-back 2 — Step27〜33 実入力の証跡

2026-11-02の本人報告d4963b19（起動・写真アクセス・保存4枚・再起動復元成功）とb8768846（左右キー/Command複数選択/写真キーボード選択失敗）を入力とした。前回176件/85.95%を新しい成功とは扱わず、実UI試験を追加した。

### Runner先行

Debug限定 --ui-test-fixture を追加。実Photos参照/許可要求、Application Supportの保存担当を作る前に、メモリ内の階層/画像/保存担当へ分岐する。HitotsuzuriUITestsは標準XCUITest、追加依存なし。

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests -enableCodeCoverage YES -derivedDataPath .build/DerivedData CODE_SIGN_IDENTITY=- test
```

Runner起動と合成要素取得1件が成功: .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.02_00-27-42-+0900.xcresult、終了コード0。OS許可を自動で与えていない。UI automationの許可ブロッカーはなかった。

### 実Redと原因

- 00-28-36 xcresult: 4件中2失敗。親の要素は取得でき、実Rightキーを送っても子が表示されない。Command追加/解除はこの時点から成功しており、本人の多選択失敗を再現したとは扱わない。
- 写真は最初に2Tabと固定した期待があり、見出しを含む可変経路へ合っていなかった。この回数固定の失敗は最終の製品Red根拠から除いた。
- 写真の試験を最大16回の実Tab/Spaceで到達する形に改め、加えていたfocusable修正だけを一時外して元の写真入力へ戻した。00-37-04 xcresultでは0枚のまま実失敗、終了コード65。写真をマウスで押したり内部toggleを呼んだりしていない。
- 行独自のfocus/onMoveCommandとネイティブListの処理が分かれていたフォルダは、NSOutlineViewへ統一。写真は明示focusableを戻して、同じキー配送/測定入口へ接続した。

### Greenと整理

実UI8件は .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.02_00-44-50-+0900.xcresult で全成功。実入力の範囲:

1. 合成アプリ起動、フォルダと主操作取得、実Photos許可ボタンなし。
2. Right展開/Left折畳み。
3. Commandで別ルート追加/片方解除。
4. 親子選択＋別ルート、親だけ解除、通常クリックで単選択。非同期の要素消失を待つ。
5. 3階層の上下/左右、折畳み後の復帰。
6. マウスを写真に使わずTab/Space1枚→Right/Space2枚→Tab退出。順序と4枠も確認。
7. 実クリック1〜5枚目で4枚維持、上限文、各枠の順序、2枚目解除後の番号詰め。
8. ウィンドウを実ドラッグで765ptまで狭め、領域切替、展開/選択/4枠保持。最終実行ではフォルダ復帰直後のLeft/Rightも確認。

写真はLazyGridの可視要素配列位置でなく、合成写真の固有ラベルで指定する。画面で使われる状態の意味は通常のaccessibilityIdentifier/value/labelから取得した。テスト専用の選択APIで成功させていない。

途中のSDK診断APIのSwift公開不足、AX RadioGroupをSegmentedControlと誤指定、状態文をvalueでなくlabelから読んだ試行、背景化した操作は製品Redに数えない。合成データだけで切り分けた。Spaceは1操作で1枚だけ変化し、二重反転していない。

### 最終全体実行

候補スクリプトの本人承認はまだなので、承認計画に従い直接全4ターゲットを実行した。

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriU1Tests -only-testing:HitotsuzuriU2Tests -only-testing:HitotsuzuriU3Tests -only-testing:HitotsuzuriUITests -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/Native-Loopback2-20261102.xcresult CODE_SIGN_IDENTITY=- test
swift scripts/check-coverage.swift .build/Native-Loopback2-20261102.xcresult
```

両方終了コード0。xcresulttoolの集計でも**passed184、failed0、skipped0、total184**。既存U1 60＋U2 48＋U3 68を維持し、UI8件を追加した。
絶対結果パス: /Users/yokochie/works/yokochie/hitotsuzuri/.build/Native-Loopback2-20261102.xcresult。

全製品Swift **1297/1457 = 89.02%**。主な増分はDebugFixture 29/34、App入口6/10、PickerView 2/2、NativeFolderBrowser 110/114、PickerContent 418/431。fixtureもUIもアダプタも除外せず、80%を維持した。

### Release隔離と候補コマンド

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -configuration Release -destination 'platform=macOS' -derivedDataPath .build/ReleaseValidation CODE_SIGN_IDENTITY=- build
rg -a -l -- '--ui-test-fixture|テスト親A|FixtureLibrary|FixtureStore' .build/ReleaseValidation/Build/Products/Release/Hitotsuzuri.app/Contents/MacOS/Hitotsuzuri
bash -n scripts/verify-native.sh
```

Release BUILD SUCCEEDED、終了コード0。文字列検査は一致なし/終了コード1（期待どおり）。fixtureの型/起動分岐はDEBUG内だけ。Release UI runnerはsetUpWithErrorでskipし、通常アプリを起動しない保護を追加した。Releaseアプリを起動して個人ライブラリを検証してはいない。

verify-native.shは全4ターゲットと既存カバレッジを含む候補。構文検査終了コード0、本体は未承認なので未実行。既存verify-all.shは変更していない。

### 本人の再確認

基本フローの本人成功を保持し、失敗した3操作の修正後本人結果は未確認とした。実UI8件の合成成功を、実ライブラリ/全キーボード主フロー/VoiceOver/コントラスト/実画面/OCR/30操作・10往復性能の合格へ読み替えない。本人再確認手順を更新し、conductor所有のBuild and Test記録とLoop-back Logは編集していない。

## Loop-back 3: Tab停止先の修正

本人23fe949aの計画承認後、UI初期化timeoutで一度停止した（tab-runner-blocker-20261102.md）。本人b2669c54の環境確認後、同じRunner試験を `.build/Tab-Runner-Resume-20261102.xcresult` で実行し1件成功、exit0。変更前基準は親担当の正規実行 `.build/Native-20261102-224614-55105.xcresult` の184件成功・89.29%。

### 観測方式の限界

テストプロセスの公開AX照会は `.build/Tab-Red-20261102.xcresult` でAXError -25211（apiDisabled）。製品Redに含めない。Debug内の公開API読取probeも、NSAppの焦点nil、実NSHostingViewの焦点子がSwiftUI.AccessibilityNodeまで取得できてもrole/label/valueを識別できず、成立しなかった。`.build/Tab-Observation-20261102.xcresult` は試作のprotocol型名のビルド失敗、Observation2〜6は観測識別不成立であり、いずれも製品Redではない。観測補助は全撤去しDebugFixtureを元へ戻した。OS設定・許可は変更していない。

### 実挙動Red（Green実装前に記録）

```sh
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/NativeInputTests/testSingleTabFromAlbumOperatesPhotoAndShiftTabReturns -only-testing:HitotsuzuriUITests/NativeInputTests/testPhotoTabWithDisabledConfirmReachesOperableFolder -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/Tab-BehaviorRed-20261102.xcresult CODE_SIGN_IDENTITY=- test
```

2件とも実assertion失敗、exit65。アルバム操作→Tab→Spaceで1枚選択へ変わらず（line11）、写真のTab退出→Rightで子フォルダが現れず（line26）。前者はアルバムから次の写真操作へ、後者は確定不可時の操作可能領域への退出という期待に基づく。固定回数の空打ちで写真へ到達することを成功にしない。写真に焦点を置くための既存の最大16回Tab/Spaceは退出試験の準備にのみ使い、直後の退出と実Right操作を別assertionで観察した。

直接のAX停止先全列挙は未成立として残し、実Tab/Shift+Tab直後のSpace/矢印で起きる選択・展開を代替回帰とする。見出しfocusableのコードだけをRed証拠にはしていない。

追加境界も製品修正前に実行した。

```sh
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/NativeInputTests/testTabFromFolderOperatesAlbum -only-testing:HitotsuzuriUITests/NativeInputTests/testCompactEmptyRegionRetainsOperableRegionSwitch -only-testing:HitotsuzuriUITests/NativeInputTests/testPhotoTabWithEnabledConfirmCanSaveBySpace -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/Tab-BoundaryRed-20261102.xcresult CODE_SIGN_IDENTITY=- test
```

exit65、実assertion失敗3件。空のアルバム領域でLeftを押しても領域選択を操作できない（line42）、アルバムからのTab後に4枚選択へ進めない（line50）、フォルダからTab→Downで写真が表示されない（line32）。期待は静的見出しを挟まず、隣接する操作領域で実入力が働くこと。これらの実行完了後にPickerContentのGreen実装を開始した。

### Greenと整理

4つの静的見出しを通常Tab順から外し、header属性を保持した。アルバムの行と標準Listの焦点をListへ一本化し、Tab/Shift+Tabを写真/フォルダへ送る。写真のTab退出先を静的trayから、有効な確定またはフォルダへ変更した。空領域は領域Picker等の実在する操作へ戻す。確定ボタンのマウスとSpaceを同一C1入口へまとめ、Pickerの左右キーは表示領域だけを更新する。

途中結果も隠さず区別する。Tab-Greenは新規5件中2件成功・3件失敗。Tab-Green2はonKeyPressのoverloadのビルド誤りで製品Redには含めず、keys指定へ直した。Tab-Green3は3件成功・2件失敗、Tab-Green4は残る空領域/確定の2件が失敗。明示焦点だけでは標準コントロールへSpace/矢印が配送されず、キー接続を追加した。Tab-Green5は残る2件成功、exit0。すべて .build/Tab-Green[2〜5]-20261102.xcresult（初回のみTab-Green-20261102.xcresult）に記録。

狭幅PickerのRadioButtonはAX valueが0/1で、isSelectedによる判定は適切でなかったためvalue判定へ修正した。領域切替後は既存の焦点復帰でフォルダ一覧へ入るため、同じPickerを続けてRightで戻すという試験仮定を、Down/Rightで実フォルダを操作する確認へ修正した。保存Taskは非同期なので保存状態の要素値を最大3秒の存在待機で観察する。写真到達の固定Tab数を増やす回避は行っていない。

### 承認済み全体検証

```sh
bash scripts/verify-native.sh
xcrun xcresulttool get test-results summary --path .build/Native-20261102-232557-72550.xcresult --format json
```

スクリプトexit0。summaryで全189件成功、失敗0、skip0（既存176件＋実UI13件）。結果の絶対パスは /Users/yokochie/works/yokochie/hitotsuzuri/.build/Native-20261102-232557-72550.xcresult。同スクリプト内のswift scripts/check-coverage.swiftで全製品1361/1515行＝89.83%。PickerContent481/489、DebugFixture30/34。全製品のUI/入口/Photosアダプタを含む条件と閾値は不変。追加5件を含む全試験を実行済み。

フォーカス観測probeとAPIの限界は上記のまま残し、実キーの効果を代替証拠とする。本人の3操作成功3fc70abcは保持し、今回のTab修正後の本人再確認・VoiceOver・コントラスト・実画面性能等は別の未確認として記録した。既知の子折り畳み選択問題、測定の保護、他者のBuild and Test記録は変更していない。

## 本人追加要求: Tab入場時の先頭選択（2026-11-03）

本人ab9b87d4承認のStep40〜45。変更前基準は全189件・89.83%。Entry-Runner-20261102.xcresultは日付を跨いで11/03 00:00JSTにUI1件成功、exit0。公開AXの直接観測は繰り返さず、合成UIの実入力と表示結果を使う。

### Red（製品実装前）

```sh
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/NativeInputTests/testTabEntrySelectsFirstFolderAndAlbumButOnlyFocusesPhoto -only-testing:HitotsuzuriUITests/NativeInputTests/testTabIntoUnselectedAlbumSelectsFirstWithoutPhotoSelection -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/Entry-Red-20261103.xcresult CODE_SIGN_IDENTITY=- test
```

実UI2件とも失敗。起動直後は未選択・写真0枚であることを確認後、最初の実Tabで先頭フォルダのアルバムが現れず（line9）。別試験ではマウスでフォルダだけ選びアルバム表示後、実Tabで先頭アルバムの写真が現れず（line23）。どちらも期待した表示変化のassertion失敗で、OS初期化失敗ではない。これを記録してからGreen実装へ進む。

### 境界の追加Red

基本2件はEntry-Green-20261103.xcresultで成功した。その後Entry-Boundary-20261103.xcresultでU3FocusTests9件（新規AppKit3件を含む）が成功。実UIの狭幅/既存ドラフト保持で新しいクラッシュを観測した。合成アプリのクラッシュ記録のasiBacktracesがNSEvent keyCode→selectFirstAlbumForTabEntryを示し、マウスイベントのkeyCodeをtype確認より先に読んだ誤りを特定した。製品の実失敗として記録し、確認順を修正する。

逆Tab試験は初期の無焦点から逆順でフォルダへ着くことを仮定しており、一覧への逆Tab入場そのものを準備できていなかった。空アルバム一覧へ実マウスで焦点を置き、そこからShift+Tabでフォルダへ入る経路へ訂正する。初期表示/マウスだけでは先頭選択しない条件は保持する。

### Green・Refactorの実結果

Entry-Green-20261103.xcresultで基本2件成功。Entry-Green2は通常2件と逆Tab1件成功、狭幅の写真Spaceと既存ドラフト往復の最後のSpaceは失敗した。Entry-Green3も残る2件は失敗。写真領域の明示復帰をView接続後のMainActor turnへ渡し、Entry-Green4では狭幅1件成功、ドラフト往復1件失敗だった。固定時間sleepは使わない。

Entry-TabRoute-20261103.xcresultで前進Tab直後にSpaceを送る診断を一度行った。2枚ドラフトが最初の停止で写真1を解除し写真2だけになり、想定のアルバム停止を通っていないことを確認。ただし「直前の2回の逆Tabで既にフォルダへ着いていた」という仮定までは証明しなかった。前進callbackを試したEntry-Green5とListの明示focusableを加えたEntry-Green6でも当該1件は失敗したため、前進callbackを原因解消の証拠にはしない。

実Shift+Tabのbacktab U+0019もSwiftUIの対象キーに含め、方向を判定したEntry-Green7で当該1件が成功した。keys:[.tab]だけでは逆方向ハンドラを通らず標準focus順へ落ちる経路が残っていた。効果のなかったNativeFolderBrowserの前進callbackは撤去し、Entry-Minimal-20261103.xcresultで同じ1件が引き続き成功。診断printも撤去した。試験は最初の前進Tab後のSpaceで2枚を保持し、次のTab後のSpaceで元の写真を1枚解除することを検証する。余分なTabや待機を足して成功させていない。

最終のNativeFolderBrowserは、Tabによるresponder着地/初期firstResponderでの初回Tabだけを入口とし、非空・未選択・非凍結・pending未選択の場合に先頭を選ぶ。マウスや初回表示では選ばない。アルバムは同じTab条件を確認し、Task実行時にも未選択・非凍結・同じ先頭IDを確認して既存C1へ渡す。写真はfocusのみで、選択は既存Space入口を維持。

アルバムの焦点IDは行IDと結合せず安定した一覧IDとし、選択IDの記憶を別に保つ。写真の遅延焦点は明示領域入場だけで作成し、遷移番号・領域・認可・アルバム・フォルダ集合・ドラフト・対象存在・非凍結を再確認する。画像応答からは作成しない。View挿入/復帰に必要なMainActorのyieldだけで、固定遅延はない。

新しいAppKit3件は合成のNSHostingView/NSWindow/NSOutlineViewへキーイベントを配送し、空/凍結の無操作、非Tabのresponder着地の非自動選択、既存複数選択維持を確認した。個人アプリや実Photosを操作せず、自動UIの実Tab成功とは階層を分けて記録する。

### 最終全体検証

```sh
bash scripts/verify-native.sh
xcrun xcresulttool get test-results summary --path .build/Native-20261103-002552-92644.xcresult --format json
```

スクリプトexit0、summaryで197件成功・失敗0・skip0。前回189件＋新規実UI5件＋AppKit3件。結果絶対パスは /Users/yokochie/works/yokochie/hitotsuzuri/.build/Native-20261103-002552-92644.xcresult。同スクリプトの既存check-coverage.swiftで1442/1597行＝90.29%、NativeFolderBrowser133/138、PickerContent539/547。全製品分母・80%・既存assertion・スクリプトを変更していない。全体検証開始後のソース変更はない。

本人の3操作成功は保持し、今回追加した先頭選択/写真focus動作は本人未確認。従来のVoiceOver/画面性能等と既知子折り畳み問題の判断を変更していない。

## アルバム上下キー修正（本人905a320c、計画承認7ac7b654）

Step46の初回runnerはautomation初期化timeoutで停止し、album-runner-blocker-20261103.mdへ記録した。本人24244e54のUI操作許可後、runnerを単独実行しAlbum-Runner-Resume-20261103.xcresultで1件成功、exit0を確認した。その後にのみfixture/実UI試験の準備を追加した。

合成AlbumはA/B/C/D/Eごとに異なる写真IDと12/10/8/6/4枚を返す。写真領域は実workflow.assets.countをアクセシビリティ値で示す。個人の写真やOS設定を操作せず、同じ写真が最初から見えているだけでは切替成功としない。

### Red（選択/焦点修正前に記録）

```sh
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/NativeInputTests/testAlbumUpDownAfterTabChangesFirstMiddleLastAndPhotos -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/Album-Red-20261103.xcresult CODE_SIGN_IDENTITY=- test
```

exit65、実assertion失敗1件。FolderA選択→実TabでAlbumAの12枚表示は成功。その直後のDownでAlbumCの8枚へ追随しなかった（line11）。初期表示/観測の準備ではなく実上下行移動の期待不成立である。これを記録してから、Listの枠に追加したfocusableが標準行focusを妨げるという仮説の最小修正へ進む。

### 最小Greenと再入場の境界

Listの追加focusableを1か所外したAlbum-Green-20261103.xcresultで実UI1件成功、exit0。A12→DownでC8→DownでE4→末尾Downで4維持→Upで8→Upで12→先頭Upで12維持を確認した。標準Listの行操作へ戻すだけで上下移動が成立し、手書きの上下選択やnative bridgeは追加していない。

Album-Boundaries-20261103.xcresultでは、通常幅の非先頭Albumからの逆Tab/再入・同一Album写真編集保持と空一覧が成功した。狭幅はCからDownでEの4枚へ切替成功後、写真からShift+Tabで一覧を再挿入した直後のUpでC8枚へ戻れず実assertion失敗（line42）。Viewの接続前に焦点を渡す境界を修正するため、既存の写真領域用の接続後焦点復帰を一覧にも共通利用する。

### 再入場Greenと最終構成

```sh
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/NativeInputTests/testAlbumArrowsInCompactAfterMouseSelectionFollowPhotos -only-testing:HitotsuzuriUITests/NativeInputTests/testAlbumUpDownAfterTabChangesFirstMiddleLastAndPhotos -only-testing:HitotsuzuriUITests/NativeInputTests/testAlbumArrowsAfterReverseTabAndReentryKeepSameAlbumDraft -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/Album-Connected-20261103.xcresult CODE_SIGN_IDENTITY=- test
```

exit0、実UI3件成功。狭幅でもC→Down→E4枚、写真から逆Tab→Up→C8枚、再度逆Tab→Up→A12枚と表示が追随した。通常幅は先頭/中間/末尾・上下端の維持に加え、非先頭Albumで写真を選択→逆TabでFolderへ戻る→同じAlbumへ再入して編集保持→Downで別Albumへ変え0枚へクリアという従来規則を確認した。別の空一覧試験もAlbum-Boundariesで成功。写真へのTabだけでは選択せず、Space時だけ1枚選ぶことも含む。

修正本体は追加focusableの除去と、既存の接続後焦点復帰を狭幅Albumへ共通利用すること。標準Listの上下行選択を使い、手書きキー選択やNSTableView追加を行っていない。既存の遷移番号・領域・認可・アルバム/Folder/編集/対象存在・非凍結の照合を保ち、初回未選択Albumだけは既存Tab先頭選択との整合を確認する。画像応答で焦点を要求せず、固定sleepもない。

新規は実UI4件。fixture変更はDebug限定の識別条件であり、既存の「写真1」等のラベル/4枠期待値を変えず、AlbumAは従来12枚を保つ。凍結と権限等の既存C1保証は全単位検証で回帰確認し、実PhotosやOS設定を操作しない。

### アルバム修正後の全体検証

```sh
bash scripts/verify-native.sh
xcrun xcresulttool get test-results summary --path .build/Native-20261103-075736-25503.xcresult --format json
```

exit0、summaryで全201件成功・失敗0・skip0（既存197＋実UI4）。結果絶対パスは /Users/yokochie/works/yokochie/hitotsuzuri/.build/Native-20261103-075736-25503.xcresult。既存check-coverage.swiftで全製品1451/1610行＝90.12%、PickerContent545/556、DebugFixture33/38。分母・80%・既存assertion・スクリプトは不変。全体開始後ソース変更なし。

本人の今回の上下キー修正の再確認、VoiceOver/コントラスト/実画面性能等は未確認として残す。既知の子折り畳み問題は現状継続の判断を保持し、今回のソース3パスへ含めていない。

## 本人requested直接修正: 狭幅確定到達

38ec67b9の直接修正をcompact-confirm-fix-20261103.mdへ記録した。runner1件成功→実キーRed2失敗/1成功→最小Green4成功→承認済み全verify-native一度、の順。新plan/承認/workflow操作はしていない。最終 .build/Native-20261103-234223-36633.xcresult、205件成功・失敗0・skip0、全製品1474/1634行＝90.21%。通常幅/disabled等の既存201件を保持し、全体開始後source変更なし。本人再確認は未確認のまま。
