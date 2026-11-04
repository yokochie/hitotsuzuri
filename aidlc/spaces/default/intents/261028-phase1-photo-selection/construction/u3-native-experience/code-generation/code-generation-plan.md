# U3 実装計画

## Summary

- Builds: アルバム一覧へTabで入った後、上下キーで行を選択し、写真表示が選んだアルバムへ追随する操作を修正する。
- Touches: PickerContent.swiftと実UI試験を中心に最小変更。必要な場合だけ標準NSTableView等の薄い接続を追加し、今回の実変更をmanifestへ記録する。
- Tests: 実Tab→上下キーの先頭/中間/末尾移動、再入・逆Tab・狭幅をRed→Greenで検証。既存197件と全製品80%以上を維持する。

## 根拠と範囲

[機能仕様](../functional-design/functional-spec.md)、[規則](../functional-design/rules.md)、[表示構成](../functional-design/frontend-components.md)、[品質条件](../nfr-requirements/performance-requirements.md)、[性能設計](../nfr-design/performance-design.md)、[保護設計](../nfr-design/security-design.md)、[実行環境](../infrastructure-design/infrastructure-specification.md)と共有の[契約](../../../inception/contract-design/contract-summary.md)に従う。
US1.1〜US1.8のU3寄与を完成させる。4枚ルールと永続形式を変更せず、既存5責務を保つ。入力資料や本人README、AI-DLC設定は変更しない。

## 実装順序

- [ ] Step 1: 現在のU1/U2全108件と85.23%を基準に、変更前の実行結果と差分を確認。未コミットの既存変更を保持。（全ストーリー）
- [ ] Step 2: Xcodeプロジェクト/共有schemeへhostless HitotsuzuriU3Testsを追加し、U3専用コマンドを最初のRedより前に実行可能にする。必要なテスト用データ/境界を配置。（全ストーリー）
- [ ] Step 3: 保存結果の整合Red。正常保存直後の認可喪失と呼出しTask取消をFakeで競合させ、ディスク・lastCommitted・保存状態の不一致を回帰テストで再現。実書込失敗の旧確定保持も検証。（US1.6、1.8）
- [ ] Step 4: 保存結果Green。SelectionWorkflowの保存前認可検証と保存後の実結果反映を分離。成功を後続の権限/取消で未保存の失敗へ変換せず、新確定と権限案内を両立。固定内容と操作IDを照合し二重保存を防ぐ。（US1.6、1.8）
- [ ] Step 5: 保存結果Refactor。認可検証の安全条件と書込成功の意味を整理し、U1/U2回帰を確認。（US1.6、1.8）
- [ ] Step 6: 表示状態Red。領域切替、820pt境界、640×560pt、長名、IDによるフォーカス復帰、階層展開と複数選択の独立をU3LayoutTests/U3FocusTestsで検証。（US1.1、1.2、1.5）
- [ ] Step 7: 表示状態Green。表示担当へ領域別フォーカスIDと展開IDを追加。通常3領域、820pt以下の切替、下部4枠と折返し操作を実装。フォルダ階層と名称の全名への到達を仕上げる。（US1.1、1.2、1.5）
- [ ] Step 8: 表示状態Refactor。選択/保存判断を表示へ複製せず、ID不在時の移動先と非同期完了でフォーカスを奪わない動作を整理。（US1.1、1.2、1.5）
- [ ] Step 9: 操作支援Red。写真の矢印/Space/Tab、取得不可の理由への到達、可視フォーカス、選択順/4枠/保存状態の意味をU3AccessibilityTestsで検証。（US1.1〜1.8）
- [ ] Step 10: 操作支援Green。標準一覧の複数選択、グリッド退出可能なキー操作、番号と選択状態の読み上げ、領域名、4枠の順番ラベル、無効化理由を実装。5枚目は追加せず文言で案内。（US1.1〜1.8）
- [ ] Step 11: 操作支援Refactor。色だけに依存せず、システムの意味的な色とフォーカス表示を整え、状態の過剰通知を避ける。（US1.1〜1.8）
- [ ] Step 12: 表示資源Red。可視/選択の必要集合、セル退出/領域切替/10往復相当、不要要求取消、遅延応答・生存バッファ/予約上限をU3ResourceTestsで検証。（US1.3、1.4）
- [ ] Step 13: 表示資源Green。進行/画像担当の不要な表示要求とキューを取消し保持参照を解放。256MiB、通常4/検証4最大8、512物理pixel、個別/4枚全体15秒の既存上限を維持。（US1.3、1.4）
- [ ] Step 14: 表示資源Refactor。実測用にIDを含まない件数/bytesの読取用スナップショットを最小追加。所有境界を変えず表示の二重コピーを防ぐ。（US1.3、1.4）
- [ ] Step 15: 測定境界Red。連番・入力時刻とフレーム表示時刻の対応、欠測/古い番号/時刻ずれ、95%判定とフレーム間隔の不確かさをU3MeasurementTestsで検証。内部状態更新を終点にできないことを固定。（US1.3、1.4、1.8）
- [ ] Step 16: 測定境界Green。任意の測定用起動と最小のローカル測定補助を追加。ScreenCaptureKitの表示済みフレーム時刻と入力側のmach単調時計の対応をSDKで型検査/校正。選択表示と連番が同じフレームへ現れたことを照合する。フレームはメモリ内で照合後破棄、通常ログ/Git/外部へ出さない。実フレーム採取は本人のOS許可後だけ行い、許可なし/不成立は未確認として停止・説明。（US1.3、1.4、1.8）
- [ ] Step 17: 測定境界Refactor。通常起動では測定を無効化し、出力を連番/時間/件数/bytesの集計に限定。測定用の失敗を性能合格へ読み替えない。（US1.3、1.4、1.8）
- [ ] Step 18: U3IntegrationTestsで狭幅→領域復帰→選択解除→確定/再試行と表示整合を結合検証。各不足はRed→Green→Refactorで補完。1280×800pt/640×560pt/820pt境界の描画を確認。（全ストーリー）
- [ ] Step 19: 日本語の本人確認手順を作成。キーボードのみの主フロー、VoiceOver、ライト/ダーク/コントラスト、実Photos復元、100枚以上/30操作/95%以上200ms、10往復と不要要求15秒以内0を記録する表を用意。未観測を合格としない。（全ストーリー）
- [ ] Step 20: 全U1/U2/U3テストとビルドを実行、全製品Swift加重行80%以上を既存計測器で確認。新規scripts/verify-all.shに全単位を含め、承認済みverify-phase1.shの意味は変えない。最終コマンドの変更は本人へ後で確認。（全ストーリー）
- [ ] Step 21: code-summary、traceability、source-manifest、TDD証跡、操作/性能/実機の実結果と未確認を保存し、完成コードの独立レビューへ渡す。Constructionフェーズが終わった時点で関連成果物をGitへコミット。（全ストーリー）

## 変更対象

既存HitotsuzuriCore/PickerContent.swift、PresentationSnapshot.swift、SelectionWorkflow.swift、LocalImageAccess.swift、必要なPorts/Modelsと表示専用モデルを変更する。必要な小さな表示/測定ファイルを同じCoreへ追加する。Hitotsuzuri/HitotsuzuriApp.swiftとPickerView.swiftは測定用起動/最小幅配線のため必要な範囲だけ更新。測定補助はscripts/measure-native.swift等のローカルファイルへ配置し、外部依存を追加しない。
Xcodeプロジェクトとscheme、新規HitotsuzuriU3Tests、scripts/verify-all.shを追加/更新する。既存テストの保証を削除せず、互換性のためのFake更新だけ許容する。UIの自動識別にはaccessibilityIdentifierを使う。保存JSONの変更、配布、ネットワーク、クラウドは対象外。

## 品質と本人確認

約35〜45件は目安であり、境界条件を優先して増やす。全製品コードの80%を維持し、App入口・UI・Photosアダプタを除外しない。実キーボード/VoiceOver/写真/実画面時刻/コントラストは自動状態試験と区別する。
[本人によるCI省略](../../../change-decisions/2026-10-31-local-verification.md)を契約中の旧CI記述へ適用し、統合前ローカル検証を維持。最終検証コマンドは新しい内容の本人確認後にだけ指定する。測定用OS許可は自動で与えず、測定の不成立や未確認を明示して本人判断を受ける。

## 再実装の範囲と順序

Build and Testの[Loop-back 1](../../build-and-test/test-results.md)を受けた再実装。上記Step1〜21で完成した内容を保持し、以下だけを追加する。既存159件成功・84.90%は修正前の基準であり、今回の修正後成功とは扱わない。U1/U2のコードと計画はKeep、U3とBuild and Testの結果はModifyとする。

- [ ] Step 22: 既存U3専用コマンドを実行確認後、測定件数の回帰をRedで追加。同じ空選択30回、5枚目拒否、取得不可、凍結中、無効IDは有効操作に数えず、正常な選択と解除は数える。初回が解除の場合や一度変えて元へ戻した場合も検証する。（US1.3、1.4、1.8）
- [ ] Step 23: Green。UI入力前後の実選択を比較し、実際に採用された選択/解除だけを測定へ渡す。測定モデルでも前後状態の不変・重複を拒否し、最初の基準状態・連番・欠測の意味を保つ。必要なら同一フレーム照合用のマーカーとローカル測定補助を互換的に更新する。（US1.3、1.4、1.8）
- [ ] Step 24: Refactor。選択ルールを測定側へ複製せず、測定の拒否を通常操作の失敗へ変えない。無効操作で正常な後続測定の連番に穴を作らず、未対応/欠測を合格にしない。（US1.3、1.4、1.8）
- [ ] Step 25: UI入口→選択変化→測定→フレーム対応の結合回帰、全U1/U2/U3、全製品80%以上、測定補助の型検査/キャプチャなし校正を再実行。P-MEASURE再現を期待どおり拒否できることを確認。承認済みverify-all.shの意味と品質閾値は変えない。（全ストーリー）
- [ ] Step 26: code-summary、source-manifest、traceability、TDD/本人手順を現在結果へ更新し、今回の変更を独立レビューへ渡す。実画面/OCR、30操作・10往復、VoiceOver/キーボード、コントラスト、実Photosは本人未確認のまま維持する。（全ストーリー）

変更予定はCoreのNativeMeasurement.swift、FrameMeasurement.swift、PickerContent.swift、U3MeasurementTests.swift/U3IntegrationTests.swift、必要なscripts/measure-native.swiftと対応するFake。手戻りの目安20〜40分、追加サービス費用0、通常の選択/保存へのリスクは低い。測定連番と照合の互換性は回帰で確認する。実機未確認を成功へ置き換えない。

## Loop-back 2: 実入力の修正

本人の実機報告b8768846と[Loop-back 2](../../build-and-test/test-results.md)に基づく。Step1〜26の完成物を保持し、今回の実装は次のStep27〜33だけ。起動・写真アクセス・4枚保存・再起動復元の本人成功は保持する。左右キー・Command複数選択・写真キーボード選択はNot Metであり、純粋な状態計算テストだけでは修正済みとしない。

- [ ] Step 27: UI試験の準備。Debug限定の --ui-test-fixture 起動を追加し、複数の親子フォルダ・別アルバム・ローカル合成画像をメモリ内のライブラリ/保存担当へ注入する。実Photosへの参照・許可要求と本人の保存領域への書込を行わない。HitotsuzuriUITestsターゲットを共有schemeへ追加し、単位フィルター付きUIコマンドで起動と要素取得が実行可能なことを最初のRedより前に確認する。（US1.1、1.2、1.4）
- [ ] Step 28: 実入力Red。XCUITestで実アプリにキーとCommandクリックを送り、フォルダのRight展開/Left折畳み、Commandで2行選択/片方解除、写真へキーボードで到達して矢印/Space選択解除/Tab退出を検証する。表示された子・対象アルバム集合・写真番号/4枠を観察する。内部関数を直接呼んだだけの試験をこの成功条件にしない。失敗を再現して原因を特定する。（US1.2、1.4、1.8）
- [ ] Step 29: Green。行独自のfocusとネイティブ一覧選択の競合、写真ボタンのフォーカス取得とキー配送を実際の失敗に沿って修正する。フォルダの展開・選択と写真操作を一貫したネイティブ入力経路へ接続し、SwiftUIだけで成立しない箇所はNSOutlineView等の標準AppKitコントロールを薄く橋渡ししてよい。OS全体のキーボード設定変更を前提にしない。選択ルールは既存進行担当を唯一の所有者とする。（US1.2、1.4、1.8）
- [ ] Step 30: Refactor。フォーカス復帰、長名、狭幅切替、フォルダ展開/複数選択の分離、取得不可理由、保存中凍結、VoiceOverの意味と測定用入力時刻を保持する。マウス操作も回帰確認し、フォルダ選択の非同期反映で複数選択を失わないようにする。（US1.1〜1.8）
- [ ] Step 31: UI回帰を拡張。少なくとも3つの本人報告を自動化し、単一/複数/解除、折畳み復帰、写真の選択順・5枚上限・キー退出、狭幅切替を追加する。XCUITestの実行不能/OS許可不足/要素未発見を期待した製品Redに数えず、具体的に記録する。（US1.2、1.4、1.8）
- [ ] Step 32: ビルド、既存176件、新規UIテスト、全製品80%以上を検証。UIターゲットを含むscripts/verify-native.shを追加し、承認済みverify-all.shの意味を変更しない。全体の新しい検証コマンドは生成後に本人へ確認する。fixtureを通常起動・Release版から隔離し、製品コードの除外追加で基準を下げない。（全ストーリー）
- [ ] Step 33: 今回のソースmanifest、summary、traceability、TDDの実入力Red/Green証跡、本人の再確認手順を更新し、完成コードを独立レビューへ渡す。本人が失敗した3操作は修正後も本人の再確認結果を別に記録する。VoiceOver/コントラスト/実性能等は未確認を維持。（全ストーリー）

追加変更候補: CoreのPickerContent.swiftと必要なNativeFolderBrowser.swift/NativePhotoGrid.swift等、HitotsuzuriAppのDebug限定fixture配線とDebugFixture.swift、Xcodeプロジェクト/共有scheme、HitotsuzuriUITests内の実UIテスト、scripts/verify-native.sh。標準AppKit/SwiftUI/XCTest/XCUITestのみを使い、外部依存や写真ライブラリ変更を追加しない。データ所有・保存形式・4枚ルールは変更しない。作業規模は中、フォーカス/複数選択/読み上げを主要な回帰リスクとして扱う。

## Loop-back 3: 静的見出しへのTab停止

本人報告3fc70abcにより、左右キー・Command複数選択・写真キーボード選択の3操作の成功を保持する。一方、操作不能な「フォルダ」「アルバム」「写真」の静的見出しへのTab停止はNot Metとして修正する。現在のheadingのfocusable/focused、静的trayへのTab退出、空領域でのheadingへの復帰を今回の範囲とする。Step1〜33の完成物は保持し、以下だけを追加する。以下は本人承認待ちであり、承認前に製品・テストの実装や実行を行わない。

- [ ] Step 34: 準備。現行184件成功・89.29%の記録と通常幅へ戻すUI起動処理を維持する。承認後に既存UI専用コマンドでrunnerを確認し、通常幅/狭幅、空の領域、写真0〜3枚で確定不可・4枚で確定可能というフォーカス境界を整理する。（US1.1、1.2、1.4、1.8）
- [ ] Step 35: 実入力Red。合成fixtureの実アプリへTab/Shift+Tabを送り、静的領域見出し・「選んだ写真」への停止と写真から静的trayへの退出を回帰で再現する。停止先のAXフォーカスと実際の操作結果を確認し、単にTabを何回も送って最終的に写真へ着くことを合格条件にしない。通常幅・狭幅、空領域への復帰、確定可能/不可を区別する。必要な観測補助はテスト内を優先し、製品へ必要ならDebug fixture限定・焦点情報のみの最小構成とする。（US1.1、1.2、1.4、1.8）
- [ ] Step 36: Green。「フォルダ」「アルバム」「写真」「選んだ写真」の4つの静的見出しを通常Tab順から外し、キーボード用focusable/focusedと見出しフォーカスIDを除去する。VoiceOverでのheader属性・領域名は維持する。静的trayを退出先にせず、有効な確定/領域切替等の操作可能な要素または自然なTab順へ退出する。空領域では無効な行・静的見出しへ強制せず、実在する操作可能な移動先または自然な退出を選ぶ。Shift+Tabで戻れ、フォーカストラップを作らず、非同期更新で焦点を奪わない。（US1.1、1.2、1.4、1.8）
- [ ] Step 37: Refactor。実フォーカスと復帰先の所有を最小限に整理する。写真の矢印/Space、Command複数選択、フォルダ展開、狭幅切替、可視焦点、VoiceOverの意味、入力計測の時刻を保持する。受入済みの非表示子フォルダの折り畳み選択問題には変更を加えない。（US1.1〜1.8）
- [ ] Step 38: 承認済みbash scripts/verify-native.shで既存184件と追加回帰、ビルド、全製品80%以上を確認する。閾値・分母・既存assertion・検証コマンドの意味を変更しない。合成UI試験を本人のVoiceOver/実写真/性能確認の代用としない。（全ストーリー）
- [ ] Step 39: 今回の変更だけをsource-manifestへ列挙し、code-summary・traceability・TDD証跡・本人のTab/Shift+Tab再確認手順を実結果へ更新する。本人の3操作成功と未確認項目・保留問題を分けて残し、現在attemptの独立レビューへ渡す。（全ストーリー）

変更予定の製品ファイルは `HitotsuzuriCore/PickerContent.swift` のみを基本とし、試験は `HitotsuzuriUITests/NativeInputTests.swift`、必要な既存 `HitotsuzuriU3Tests` のフォーカス/結合試験に限定する。Debug側の観測が不可欠な場合だけ `Hitotsuzuri/DebugFixture.swift` の合成試験配線を最小変更する。新たなサービス・依存・保存形式・選択規則は追加しない。工数の目安は小、回帰リスクはTab退出先と空領域/狭幅の焦点復帰。本人の通常ウィンドウ設定やOSのキーボード設定を変更しない。

## 本人追加要求: 未選択一覧へのTab入場

本人e9c4ba18の追加要求と607a503cの選択に基づく新attempt。フォルダ・アルバムは、選択がない非空一覧へTabで入った場合だけ先頭を選択する。写真は先頭へフォーカスを置くだけで、Spaceを押すまで枚数を増やさない。既存の選択対象・複数選択・写真ドラフトを保持する。Step1〜39の成果を保持し、以下のみ追加する。これは本人指定の行動変更であり、自律Loop-back回数の上限変更ではない。新計画の本人承認まで実装・試験変更・実行を行わない。

- [ ] Step 40: 準備。前回の全189件成功・89.83%を基準として保持し、承認後に既存UI単位コマンドでrunnerを確認する。NSOutlineViewのresponder着地とSwiftUI Listの選択境界を調べ、実Tab/Shift+Tab起因の入場を初回表示・マウス・非同期反映から区別する。未選択/既選択、空/非空、通常/狭幅の境界を整理する。（US1.1、1.2、1.4）
- [ ] Step 41: 実入力Red。合成UIへ実Tabを送り、未選択フォルダへの入場で先頭を選び対象アルバムが現れること、未選択アルバムへの入場で先頭を選び写真が現れることを検証する。写真への入場直後は0枚のまま、Spaceで先頭の1枚だけが選ばれることを確認する。初回表示やマウスだけで自動選択しないことも区別し、実際の期待不成立を記録する。モデル呼出しや試験からの焦点強制で入力を迂回しない。（US1.1、1.2、1.4）
- [ ] Step 42: Green。Tab起因の入場と選択なしの条件が揃ったときだけ、非空フォルダ/アルバム一覧の先頭を既存Workflowの選択入口へ渡す。NSOutlineViewの標準複数選択・非同期反映を保ち、SwiftUI Listの選択と表示を一致させる。写真は実在する先頭/既存IDへのフォーカスのみとし、選択は従来のSpace/マウス入口に任せる。空一覧・凍結中は何も選ばず、マウス起動や遅延データ到着だけで勝手に選択しない。（US1.1、1.2、1.4）
- [ ] Step 43: Refactorと回帰。既存フォルダ複数選択・既存アルバム・写真ドラフトがある場合は先頭へ置き換えず、同一対象への再入場でも編集を消さない。逆Tab再入・狭幅領域切替で入場理由を正しく扱い、空一覧は無操作、非同期画像で焦点を奪わず、見出しのTab除外・VoiceOverの意味・写真の選択順と4枚上限を維持する。必要な境界試験もRed→Greenの順で追加する。既知の子折り畳み選択問題は修正しない。（US1.1〜1.8）
- [ ] Step 44: 承認済みbash scripts/verify-native.shで既存189件と新規実UI回帰、ビルド、全製品80%以上を確認する。閾値・分母・既存assertion・検証スクリプトの意味を変えない。本人の3操作成功と従来の実機未確認を保持する。（全ストーリー）
- [ ] Step 45: 今回の実変更だけを最小source-manifestへ列挙し、code-summary・traceability・TDDの実Red/Green証拠・本人による先頭選択/写真フォーカス再確認手順を更新する。既存成功と追加動作の本人未確認を分け、ソースと成果物を凍結して独立レビューへ渡す。（全ストーリー）

変更候補は `HitotsuzuriCore/NativeFolderBrowser.swift`、`HitotsuzuriCore/PickerContent.swift`、`HitotsuzuriUITests/NativeInputTests.swift` と必要な既存U3フォーカス/結合試験のみを基本とする。空一覧等の合成試験条件が必要な場合だけ既存DebugFixtureへDebug限定データ条件を最小追加し、実Photos・許可UI・本人保存領域は使用しない。新しい保存形式・選択規則の所有者・外部依存を増やさない。実装規模は小、主なリスクはマウス入場との誤判別、Tab直後の非同期選択、既存複数選択や同一アルバムの編集の上書きである。

## 本人不具合報告: アルバムの上下キー操作

本人905a320cは、アルバムが枠へfocusするだけで上下移動できないと報告した。前回197件・90.29%はTab入場時の先頭選択と退出の証拠であり、実際の上下キーによる行移動の合格証拠にはしない。Step1〜45の成果と動作規則を保持し、以下だけを追加する。List.focusableが一覧の枠へ焦点を置いて行へのキー配送を妨げる可能性は、実入力Redで確かめる仮説とし断定しない。新計画の本人承認前には製品/試験コードを変更・実行しない。

- [x] Step 46: 準備。全197件成功・90.29%を変更前基準として保持し、承認後に既存UI単位コマンドでrunnerを確認する。実際のアルバム順と行選択・写真表示の観測方法を整理する。合成アルバムごとに写真ID/枚数等を識別できる必要最小のfixture条件を用い、同じ写真が見えるだけで切替成功としない。（US1.2、1.3、1.4）
- [x] Step 47: 実入力Red。未選択アルバムへ実Tabで入り、Down/Upで少なくとも先頭・中間・末尾のアルバムへ切り替え、選択行と対応する写真表示が追随することを検証する。先頭/末尾で範囲外へ進まず、Spaceや余分なTabを押して選択を代行しない。既存選択アルバムへの再入・逆Tab・狭幅でも実上下キーを送り、枠への焦点だけで行が動かない失敗と原因を記録する。（US1.2、1.3、1.4）
- [x] Step 48: Green。実失敗に基づき、一覧のキーボード焦点と行選択を標準コントロールの単一経路へ接続する。SwiftUI Listで最小修正が成立する方式を優先し、必要な場合だけNSTableView等を薄く橋渡しする。行ごとの重複focusや手書き選択ロジックの増殖を避け、選択意図は既存Workflowへ渡す。非同期の写真応答は現在のアルバムだけへ反映し、保存形式・4枚ルールを変えない。（US1.2、1.3、1.4）
- [x] Step 49: Refactorと境界回帰。通常/狭幅、既存アルバムからの再入/逆Tab、先頭/末尾、空一覧/凍結を確認する。未選択時のTab先頭選択、マウス選択、同一アルバム再入の編集保持、実際に別アルバムへ変えた場合の既存切替規則、写真のTabはfocusのみ→Space選択を維持する。見出しTab除外、既存Folder複数選択、VoiceOverの意味、画像応答で焦点を奪わない条件も保持する。既知子折り畳み選択問題は修正しない。（US1.1〜1.8）
- [x] Step 50: 承認済みbash scripts/verify-native.shで既存197件と新規回帰、ビルド、全製品80%以上を確認する。今回の原因を通る実上下キー試験を必須とし、写真表示済みという初期状態だけで成功させない。既存assertion、分母、閾値、検証スクリプトの意味を弱めない。（全ストーリー）
- [x] Step 51: 今回の実変更だけを最小source-manifestへ列挙し、code-summary・traceability・実Red/Green証跡・本人のアルバム上下キー再確認手順を更新する。既存の本人成功と今回の不具合/修正後未確認を分け、ソースと成果物を凍結して独立レビューへ渡す。（全ストーリー）

主な変更候補は `HitotsuzuriCore/PickerContent.swift`、`HitotsuzuriUITests/NativeInputTests.swift`、必要な既存U3フォーカス/結合試験、アルバムを実表示で識別するための `Hitotsuzuri/DebugFixture.swift`。標準一覧の接続が必要な場合のみ、小さな `HitotsuzuriCore/NativeAlbumBrowser.swift` 等と必要なXcodeソース登録を追加する。実装規模は小、主なリスクは焦点と行選択の不一致・非同期切替・既存ドラフトの誤消去。新規依存、実Photos/許可UI/本人保存領域の試験、OS設定変更を追加しない。

## Testing Contract

```json
{
  "version": 1,
  "methodology": "tdd",
  "source": "team",
  "ordering": "各テスト可能な層で、先にテストを書いて意図した失敗を確認し、最小限の実装で成功させ、成功を保ちながら整理するred-green-refactorの順序で進める。",
  "scope": "mvp",
  "test_strategy": "standard",
  "project_type": "greenfield",
  "applicable_notes": [
    {
      "layer": "org",
      "text": "We treat tests as a first-class deliverable in every Bolt. The specific\nmethodology (TDD, BDD, ATDD, or classic test-after) is affirmed at\npractices-discovery and recorded in `team.md` under this heading with explicit\n`Methodology` and `Ordering` fields; Code Generation resolves those fields\nindependently from coverage, tooling, and scope notes.\n\nWhen no posture has been affirmed, our default per scope is:\n- **Methodology**: test-after\n- **Ordering**: implement each applicable testable layer, then write and run\n  that layer's tests.\n- `mvp`, `enterprise`, `feature`, `infra`, `classic` add an 80% line-coverage\n  floor and CI execution before merge.\n- `bugfix`, `security-patch` add a targeted regression for the specific\n  bug/vulnerability and require the existing suite to remain green.\n- `express` uses the Minimal strategy: requirement-driven unit tests (one per\n  requirement, with a happy-path floor per component); existing tests remain\n  green.\n- `poc`, `refactor`, `workshop` add no extra new-test floor and require the\n  existing suite to remain green.\n\nThe active `Test Strategy` still applies in every scope and determines test\nvolume/types. Scope floors are additive; they never reduce or replace the\nselected strategy.\n\nBuild and Test verifies defined coverage floors and affirmed quality targets;\nthey may not be weakened to make a step pass.\n\nAffirm a stricter posture in `team.md` if the team commits to one."
    },
    {
      "layer": "team",
      "text": "- **Methodology**: tdd\n- **Methodology evidence**: 確認回答Q3で、テストを先に書き、失敗を確認してから実装する方式を本人が選択し、要約も確認した。既存コードの慣行からの推定ではない。\n- **Ordering**: 各テスト可能な層で、先にテストを書いて意図した失敗を確認し、最小限の実装で成功させ、成功を保ちながら整理するred-green-refactorの順序で進める。\n- `mvp`に適用される既定の80%以上の行カバレッジと統合前のCI実行を維持する。計測対象・除外の根拠・CI実行環境は要件と実装計画で具体化し、通すために基準を下げない。\n- テスト用のデータで探索・選択・保存・復元・失敗条件を自動検証し、Photosの権限・実データ・100枚以上での操作等は本人による実機確認と区別する。\n- TDDの順序とカバレッジ・CIの条件は独立した品質条件として扱う。自動化できない権限や実ライブラリの操作を、自動テストで検証済みと表示しない。"
    }
  ],
  "obligations": {
    "strategy": "standard",
    "strategy_volume": [
      "Five to eight tests per component.",
      "Unit tests plus integration tests for key boundaries.",
      "Add E2E, performance, or security tests when requirements demand them."
    ],
    "scope_floor": [
      "Meet an 80% line-coverage floor.",
      "Run the selected tests in CI before merge."
    ],
    "combination_rule": "Apply every selected-strategy obligation and every scope-floor obligation; neither replaces the other, and a targeted scope regression may add the narrowest necessary test type beyond the strategy default."
  },
  "plan_profile": {
    "methodology": "tdd",
    "runner_step": "Bootstrap the minimal test runner/configuration and record the exact unit-scoped command.",
    "runner_ready_before_first_test": true,
    "testable_layers": [
      "Data model / database behavior",
      "Repository / data access",
      "Business logic",
      "API / endpoint",
      "Frontend behavior"
    ],
    "steps": [
      "Project structure and production configuration skeleton.",
      "Bootstrap the minimal test runner/configuration and record the exact unit-scoped command.",
      "Data model / database behavior - Red: write the failing tests and record the failing command output.",
      "Data model / database behavior - Green: implement only enough behavior to pass.",
      "Data model / database behavior - Refactor: improve the implementation while tests stay green.",
      "Repository / data access - Red: write the failing tests and record the failing command output.",
      "Repository / data access - Green: implement only enough behavior to pass.",
      "Repository / data access - Refactor: improve the implementation while tests stay green.",
      "Business logic - Red: write the failing tests and record the failing command output.",
      "Business logic - Green: implement only enough behavior to pass.",
      "Business logic - Refactor: improve the implementation while tests stay green.",
      "API / endpoint - Red: write the failing tests and record the failing command output.",
      "API / endpoint - Green: implement only enough behavior to pass.",
      "API / endpoint - Refactor: improve the implementation while tests stay green.",
      "Frontend behavior - Red: write the failing tests and record the failing command output.",
      "Frontend behavior - Green: implement only enough behavior to pass.",
      "Frontend behavior - Refactor: improve the implementation while tests stay green.",
      "Environment/build configuration.",
      "Documentation and traceability."
    ]
  },
  "input_sha256": "sha256:bd61b3953f7f40831b9fc47003d105855b637abc9a4961e5688ab9f880ad5c2a",
  "contract_sha256": "sha256:4ba63934ae5f6408d359e3811f73cf0232b97ecb35978a9430d5b1189d83d14f"
}
```

