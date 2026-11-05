# U2 専用試験の実行手順

## 2026-11-05 改訂仕様

本人承認dac2b934、Retry38d447b5と、本人指定ed903fa6（性能の合否は本人Macのみ）に基づく。隔離したrunner契約は最新17件が3.184秒で成功。各区分の実測結果はtdd-evidence.mdとci-evidence.mdを参照し、改訂と全体検証成功を区別する。

| 実行区分 | 専用コマンドの引数 | 対象・終了条件 |
|---|---|---|
| Core先行 | --core | 専用はU2の10群、正式は全3Core target。UIなし。失敗/未実行なら非0。Coreだけで製品全体coverageを判定しない |
| 起動確認 | --smoke | FixtureSmokeUITestsの2件。記事fixtureとPicker fixtureのWindowと操作入口が利用可能になること。両メソッドの成功を結果で検査。失敗時は後続UIへ進まない |
| 通常回帰 | --functional | Core機能先行→smoke→Core機能と通常UI。U2通常UIは23件。実時間/実メモリのCore性能5件とUI性能4件は別実行 |
| 詳細性能（本人Macのみ） | --performance | nativeはCore性能5件、draftはU2性能2件→smoke→UI性能4件。回数・閾値・timeout判定は維持 |
| 全体（本人Macのみ） | 引数なし | Core機能先行→Core性能→smoke→全機能/性能UI。Core性能は重複させない。正式コマンドは製品全ソースの加重80%以上も判定 |

正式verify-native.shも同じ区分を持つ。無引数と--functionalは主bundleへ既存加重checkerを適用し、製品ソース全体の80%以上を判定する。製品ソースを除外せず、別bundleの率を平均しない。--functionalの成功だけでは本人Mac性能の成功を意味しない。Core性能はU2のtestLongDraftPersistenceAndProjectionPerformance、testDisplayMemoryAndCancellationThirtyTrialsと、U1 ArticleIntegrationTestsのtestLongTextSaveThirtySamples、testColdOpenTenSamples、testImageMemoryAndThirtyConversions。--core/--functionalから5件を除き、本人Macの--performanceで各メソッドの実行成功を必須検査する。smokeは先行bundleで両メソッドを検査する。

クラス名指定を維持し、未知引数・混在区分・実行0件・指定クラス未実行は非0で終了する。選択クラスだけの部分実行と--core/--smoke/--performanceでは全体coverageを判定しない。CIだけは同一commitのnative-core成功をneedsで確認し、HZS_CORE_PREFLIGHT_DONE=1により重複した先行Coreだけを省く。主bundleのCore機能は省かず、手元の無引数全体ではこの省略を使わない。

### 改訂するUIケース

- `ArticleDraftPerformanceUITests/testLoadingLabelsThirtyEntryAndListRequests`：既存の各30回をそのまま移動する。
- `ArticleDraftPerformanceUITests/testLongDraftNativeDisplayPerformance`：保存/入力/preview/編集/再開の反復と合否をそのまま移動する。
- `ArticleDraftPerformanceUITests/testApplicationColdInputReadyTenLaunches`：異なる10プロセスの確認と計測の限界を維持して移動する。
- `ArticleDraftUITests/testEntryAndListLoadingCanComplete`：入口と一覧について各1回、読み込み表示→応答解放→完了、一覧取消後の編集復帰を確認する。
- `ArticleDraftPerformanceUITests/testNativeInputMeasurementUsesCurrentFieldEditor`：本人Mac性能群へ移し、保存応答待機中の実field editor入力反映を従来条件のまま確認する。
- 起動smokeは機能操作を詰め込まず、方式別のWindowと有効な入口だけを確認する。専用の起動失敗を機能Redと記録しない。

UI fixtureはFixtureLaunchで生成したuitest-UUID rootを追跡し、同一ケース内の再起動中は保持する。teardownではDEBUG cleanup起動によりアプリ自身が当該rootだけを回収し、成功文字を検査する。UUID形式・一時base直下・symlink非使用を検査し、過去bundleや本人データは回収対象外。Coreはプロセス内registryが発行したUUID rootだけを正常プロセス終了時に回収する。強制終了時にはteardown/終了処理を保証できず、残存の可能性を明記する。

### 改訂自体の短い検証

スクリプトの構文、未知区分の拒否、全体/通常/性能の選択、smoke失敗時に後続を実行しないこと、実行件数0の拒否を、プロジェクト内の隔離した代替コマンドで確認する。改訂前の長時間全体実行を繰り返さない。その後に起動smoke、変更した通常ケースを確認し、CIの通常回帰へ進む。必要な詳細性能と最終全体の証拠が揃うまで完了扱いにしない。

### CI

Native入力の原因切り分け専用に、`bash scripts/verify-native.sh --input-focus` を追加した。smoke2件の後、testSingleTabFromAlbumOperatesPhotoAndShiftTabReturnsとtestAlbumArrowsInCompactAfterMouseSelectionFollowPhotosの両メソッドを要求し、成功以外/片方未実行を失敗にする。全体coverageや全体成功は判定しない。専用draftコマンドにはこの区分を追加しない。隔離runner契約は追加前19件中1失敗（3.181秒）、実装後20件成功（3.364秒）。

このU2ブランチのpushに`[input-focus]`印がある場合だけ、限定診断jobが起動し、全体jobを診断目的で重複実行しない。PRと通常pushは従来どおり全体機能検証を実行する。限定jobの成功を統合条件の達成には使わず、根本原因の確認後に全体検証とcoverageを別途満たす。

push/PRではnative-coreが全Core機能（実測5件を除く）を実行し、その成功後にnative（--functional・全製品加重80%）が動く。性能jobは削除。GITHUB_ACTIONS=trueでは無引数全体、--performance、性能UIクラス指定を起動前に拒否し、その他のクラス指定でもCore実測5件を除く。決定論的な予算/期限/取消の機能検査は残す。U1ブランチの旧版比較baseline-nativeは保持するが現ブランチでは起動しない。新構成のCI実行はまだ成功確認していない。

## 設定と最初の実行

既存Xcode projectのHitotsuzuri scheme、macOS宛先、XCTest、同期フォルダのHitotsuzuriU2TestsとHitotsuzuriUITestsを使う。macOS 27対応SDKのある既存Xcode、ローカルUI操作可能なログイン環境、ad-hoc署名で実行する。追加パッケージ/有料サービスなし。新規ソースのtarget所属は同期グループで確認し、本人のshared scheme変更は保持する。

最初のRedの前に、U2が引き継ぐセッション/Workspace境界について既存runnerを限定実行する（この時点で実行可能）:

```bash
bash scripts/verify-article-foundation.sh ArticleSessionTests ArticleWorkspaceTests
```

これらはU1依存境界の準備/回帰確認であり、新規U2試験の成功とは記録しない。次に計画Step 1で専用スクリプトを用意する。未存在クラスを選んで0件成功として準備済みにしない。

## 通常のU2確認

```bash
bash scripts/verify-draft-experience.sh --functional
```

通常確認はCore先行とsmoke成功後、以下10Coreクラスの機能ケースとArticleDraftUITestsを選び、各クラスの実行/結果をxcresultで確認する。性能だけを確認するときは--performance、すべて再現するときだけ無引数を使う。既存Phase1の全U2 targetを無条件にまとめて再実行するものにはしない。結果bundleは.build内の固有名、コードカバレッジ有効、CODE_SIGN_IDENTITY=-。xcodebuild失敗と未実行を検出して非0とする。

| クラス | 主な条件・目安 |
|---|---|
| ArticleInitialContentTests | 絶対末尾・末尾改行・ASCII/全角・閏日・不正日・空タイトル・新規のみ、8件 |
| ArticleMetadataInputTests | 年境界・不正/部分raw・候補/確認/変更/削除・dirty・値保持、8件 |
| ArticleProjectionTests | 順序/空欄/Unicode/記号/改行、空白メモ省略、固定4参照、記事ID/指紋、8件 |
| ArticleAssociationTests | 同組新選択・順序違い・競合・操作反復/再利用拒否・不確定・旧値保持、8件 |
| ArticleEntryTests | 入口同一・exact/複数候補・new/resume/cancel・正常/部分/全体失敗・連打、8件 |
| ArticleNavigationTests | 全離脱先・保存/破棄/継続・不正/保存中/不確定・対象準備失敗、8件 |
| ArticleDraftSessionTests | 全欄保存復元・追加入力・rawdirty・結果不明/連続照合I/O失敗・競合、8件 |
| ArticleOutputPreparationTests | 現在入力コピー/保存済み出力準備・保存取消/失敗・後続入力・能力/未接続、8件 |
| ArticlePreviewRetryTests | 写真不能・通信禁止・期限/取消・番号別再試行・旧世代・資源解放、8件 |
| ArticleDraftIntegrationTests | 実保存境界・候補/関連付け・固定投影/別記事・再起動・ログcanary、8件 |
| ArticleDraftUITests | 全欄/候補/再開/離脱、長文/幅/キー、写真不能、日付/プレビュー、軽量read-delayの代表loading、番号別再試行キー、23件 |
| ArticleDraftPerformanceUITests | loading各30回・長文表示各30回・cold10プロセス・実field editor計測の4件。本人Macで検査 |
| FixtureSmokeUITests | 記事/Picker方式の起動と入口の2件。後続UIの前提として先行 |

件数は目安で、要件上の必要な境界を省く上限ではない。各部品の正常と少なくとも二つの異常/境界を含め、キー境界の統合は実行可能な試験にする。

## Red/Green/整理用の限定コマンド

主スクリプトは許可リスト内のクラス名または上記の実行区分を引数で受け、指定を厳密に実行する。Coreクラスだけを指定した場合はUI起動を挟まない。UIクラス指定はsmokeを先行させる。引数の異常・存在しない/未実行クラスは失敗。

```bash
bash scripts/verify-draft-experience.sh ArticleInitialContentTests ArticleMetadataInputTests
```

```bash
bash scripts/verify-draft-experience.sh ArticleAssociationTests
```

```bash
bash scripts/verify-draft-experience.sh ArticleProjectionTests ArticleEntryTests ArticleNavigationTests ArticleDraftSessionTests ArticleOutputPreparationTests ArticlePreviewRetryTests
```

```bash
bash scripts/verify-draft-experience.sh ArticleDraftIntegrationTests
```

```bash
bash scripts/verify-draft-experience.sh ArticleDraftUITests
```

同じ限定コマンドでRedの失敗内容→最小実装のGreen→整理後のGreenを記録する。runner不備/認証/クラス0件を機能Redと呼ばない。異常終了で後続試験が走らなければ未実行を記録する。

## Fakeとfixture

毎回独立した一時root/固定IDを用い、別試験の成果物に依存しない。実ファイルを使う保存/関連付け試験はテスト所有rootだけを書き、本人のPhotos/選択/下書きへ接続しない。DEBUG専用起動環境の名前付きrootはOS tempの正規化済み安全範囲だけ、任意パスを受け入れない。

C1は保存ゲート・容量・権限・競合・未知版・部分読込・結果不明と後続I/O失敗を注入する。画像は非通信の要求記録、単調時計、無応答/遅延/旧世代を注入する。C3は固定値を記録するFakeで、OSコピー/四枚成果物の成功を証明しない。ログsinkで私的canary非出現を確認する。AppKitの閉鎖/終了接続はUI fixtureとCoreの判断試験を分ける。

## カバレッジ・性能・完了の限界

全製品80%以上の行カバレッジは、正式検証の全Core機能+全機能UIの主bundleから判定する。Core性能とUI性能も別の必須段階として成功が必要。上記U2限定実行の部分カバレッジだけで全体を合否判定せず、閾値/製品ソース計測範囲を変更しない。通常確認と性能確認の率を平均せず、試験ケースを別段階へ移したことを製品ソースの計測除外へ転用しない。

performance-requirementsの100記事/1000操作・各本文10000文字で、保存/再開30回p95≤2秒、純粋投影100回p95≤100ms、文字切替30回p95≤0.5秒、表示15秒/取消2秒、256MiB/512MiBを本人Mac計測で確認する。cold10回も本人Macで確認し、CI参考計測は要求しない。未計測/未達は明示し合格扱いにしない。

640/959/960/961/1200ptで全入力・主要操作・焦点を確認。VoiceOver追加試験は要求しない。実写真の編集/色/位置情報除去・Sandbox一式出力・note手動受渡しはU1/U3と本人の確認で、Fake/UIだけで完了にしない。CIの既知Native UI失敗を試験除外・統合免除にしない。
