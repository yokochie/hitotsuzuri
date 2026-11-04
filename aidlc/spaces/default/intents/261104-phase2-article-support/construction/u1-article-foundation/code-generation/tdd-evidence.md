# U1 実装・TDD証拠

## 変更前baseline
- `bash scripts/verify-native.sh`（sandbox内）: exit 65。testmanagerd.control接続のSandbox restrictionによりXCTest/UI runnerを起動できず、試験合格・カバレッジの証拠にはしない。
- 結果bundle: `.build/Native-20261104-141546-54683.xcresult`。
- 通常権限の再実行: 179成功、UI runner初期化1失敗でexit65。LocalAuthenticationのSystem authentication is runningによりUI試験開始不能。既存コードの失敗とせず、UI未確認として引継ぐ。
- `.build/Native-20261104-141621-54973.xcresult`、カバレッジ1340/1634=82.01%。

## データモデル
- Red: `bash scripts/verify-article-foundation.sh ArticleModelTests`、ArticleSource/Content/Fingerprint/CalendarDay未定義によるbuild失敗。`.build/Article-20261104-142951-59125.xcresult`。
- Green: 同コマンド7件成功、`.build/Article-20261104-143105-59666.xcresult`。
- runner: baselineで既存179試験が実行済み。新しいSwiftは既存filesystem synchronized groupへ自動登録され、参照の追加変更は不要。

## 永続化
- Red: ArticlePersistenceTests/ArticleRecoveryTestsを先に作成、ArticlePersistence未定義でbuild失敗。`.build/Article-20261104-143225-60352.xcresult`。
- Green途中: 不変letの分岐初期化compile失敗を修正（試験条件を変更せず）。
- Green/整理後: モデル7件+保存7件+回復6件=20件成功。`.build/Article-20261104-143428-61313.xcresult`。fsync/descriptor相対作成/rename/協調排他を実ファイルで通過。応答喪失後旧operationID再試行・確定前失敗・確定後照合・未知版原本保持・symlink拒否を確認。

## 操作調整
- Red: Workspace/Session未定義のbuild失敗。`.build/Article-20261104-143557-62131.xcresult`。
- Green: `bash scripts/verify-article-foundation.sh ArticleWorkspaceTests ArticleSessionTests` 12件成功。`.build/Article-20261104-143644-62499.xcresult`。写真取得なしに選択正本から記事を解決、候補ありの無断作成防止、手動保存/離脱3択を確認。

## 画像・検証出力
- Red: `bash scripts/verify-article-foundation.sh ArticleImageTests ArticleResourceTests ArticleProbeTests`、未実装型によるbuild失敗、`.build/Article-20261104-143827-63358.xcresult`。
- Green途中: PhotoKitの向きInt32と公開UInt32の型差を修正。`.build/Article-20261104-144208-64987.xcresult`。
- Green: 同コマンド18件成功。`.build/Article-20261104-144225-65154.xcresult`。縮小/非拡大/向き/メタデータ除去、network=false、30秒と同時競合、取消、予算拒否、別folder非上書き確定/同job照合を確認。OS内部メモリと実写真はこの結果から保証しない。
