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

## UI層
- 先にArticleFoundationUITestsを6件作成し、専用class filterで実行。`.build/Article-UI-Red-20261104-1443.xcresult`はLocalAuthentication Code=-4「System authentication is running」によりrunner初期化失敗。意図した機能Red/Greenとは記録しない。
- ArticleView/Coordinator/App/Pickerを接続、初期保存・本文全欄・保存済み再開・未保存3択・閉じる/終了・選択先grant・一枚出力を実装。配線後の50件Core試験は`.build/Article-20261104-144601-67079.xcresult`で成功。UI操作成功の代用にはしない。

## 統合と追加境界
- 統合Red: deadline引数未実装。`.build/Article-20261104-144643-67517.xcresult`。
- 統合Green8件: `.build/Article-20261104-144708-67714.xcresult`。実ファイル/実JPEG/旧成果物保護/再起動照合/100記事/1000操作。初回1000操作47.864秒を観測し、新operationファイル不在なら確定鎖にも属さないことに基づき不要な全走査を省いた。旧IDは競合判定より先に逐次照合する。
- JSON重複キーRed: `.build/Article-20261104-145130-70447.xcresult`、15件中当該1件失敗。保存中編集・二重保存2件も追加。Green15件は`.build/Article-20261104-145204-70643.xcresult`。
- 指紋の明示フィールド名/表現不能時刻Red: `.build/Article-20261104-145256-70927.xcresult`。独立Python符号化の基準848byte/SHA256を固定。後続向け`fingerprint-vectors.md`を公開。
- 回復journal/再選択照合Red: `.build/Article-20261104-145438-71426.xcresult`。途中のSwift6 actor隔離エラーを、ロック内読取のactor捕捉を外すことで修正。未検証のSendable宣言で逃がさない。
- モデル9+統合9+回復出力8=26件Green: `.build/Article-20261104-145739-72259.xcresult`。
- 取消後実変換残存/予約/ゲートRed: `.build/Article-20261104-145909-73593.xcresult`。Green7件: `.build/Article-20261104-150020-74201.xcresult`。実JPEGを保持してworkerを止め、取消論理終端500ms以内、次変換busy、worker解放後予約0を確認。
- 型付き通常診断/私的値捕捉Red: `.build/Article-20261104-150414-76508.xcresult`。Green17件: `.build/Article-20261104-150532-77017.xcresult`。通常のsinkに渡る段階/分類へ本文・人物・場所・外部IDを出さない。OSLog全期間捕捉とは区別。
- rename後同期前失敗Red: `.build/Article-20261104-150631-78069.xcresult`。同期未確認を即成功にせずuncertainResultとし、同ID再試行でcurrentを再同期して照合する。
- 同期不確定Green8件: `.build/Article-20261104-150708-78248.xcresult`。

## 計画不足の補完（最小写真表示・指定障害点）
- 4枚独立表示Red: `.build/Article-20261104-151236-80611.xcresult`、ArticlePhotoPreviews未実装。Core状態所有者とAppの最小表示/番号別状態を接続。表示用512pxを使い、出力JPEGとは分離。
- 不完全finalの実失敗Red: `.build/Article-20261104-151317-81002.xcresult`、19件中1失敗。final directory不在だけをcatchし、存在するfinal内の必須ファイル欠落はcorruptDataとしてjournalを残す修正。
- Green19件: `.build/Article-20261104-151433-81704.xcresult`。片付け権限失敗、確定後応答喪失、未知一時物の保護も確認。
- 出力書込/同期checkpoint追加Red: `.build/Article-20261104-151614-82361.xcresult`。Green34件: `.build/Article-20261104-151705-82675.xcresult`。receipt前/画像前/確定前のcapacity、rename後同期不確定、実権限喪失、表示待ち本文保存、二重要求/遅延取消を確認。
- 別storeによるOS flock競合拒否も追加し、下記の全体runで成功。

## 品質ゲートと未確認
- 最新全体run `.build/Native-20261104-151800-83081.xcresult`: **262成功（既存179+Article83）、UI runner環境障害1、exit65**。カバレッジ**2232/3006=74.25%、80%未達**。製品未計測なし、App/UIは0実行。CI未実行。
- 補完前の全体run `.build/Native-20261104-150759-78537.xcresult`: 249成功（既存179+Article70）、UI runner環境障害1、exit65。カバレッジ2155/2908=74.11%。
- 全体中間run `.build/Native-20261104-144845-69370.xcresult`: 237成功、UI環境障害1、2000/2648=75.53%。
- 全体run `.build/Native-20261104-150058-74614.xcresult`: 247成功（既存179+Article68）、UI環境障害1、2109/2860=73.74%。スクリプトexit65、80%未達。閾値/製品対象は変更していない。
- 同runの100記事/対象1000操作後の長文30回p95=0.015692416秒。独立store再開10回0.000323〜0.000610秒。アプリcold起動とは区別する。
- 同runの4000x3000合成画像30回最大0.094417417秒。5秒基線中央値35,455,816 bytes、25ms観測ピーク124,650,816、差89,195,000 bytes。OS lifetime peak131,515,280は事前fixture由来で、今回短ピークの帰属は未確認。512MiBを完全実証したとは記録しない。
- 実写真の現在編集/回転/色、元ライブラリ非変更、Sandbox実操作、UI焦点/狭幅/終了、アプリcold起動10回は本人確認が必要。
- 公開pushは自動承認レビューにより明示的送信承認不足として拒否され、CI未実行。候補commit732d203は完成/統合成功を意味しない。
