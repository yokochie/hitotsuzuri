# U1 実装・TDD証拠

## 照合の一時I/O障害を跨ぐ不確定操作の保持
- Red: `bash scripts/verify-article-foundation.sh ArticleSessionTests`、`.build/Article-20261104-170413-23954.xcresult`。15件中、追加した作成/保存の2回連続照合I/O失敗と、その後の照合中追加入力の3経路が失敗（16 assertions、予期外失敗0）。元ID/固定本文/基準版が失われ、新IDへ置換される実経路を確認。
- 最小Green: 同コマンド、`.build/Article-20261104-170652-24586.xcresult`、16件成功。不確定性をsave呼出し全体ではなくPendingSaveごとの状態として保持し、照合中の一時エラーで消さない。照合成功後に生成する別操作にはその状態を継承しない。
- 回帰には、元操作の照合成功→最新入力のcapacity確定失敗→入力縮小後の保存成功も含む。従来の容量失敗後の縮小保存、保存中編集dirty保持も成功。
- 整理後Green: 同コマンド、`.build/Article-20261104-170925-25123.xcresult`、16件成功。fixtureのID/本文/基準版記録を単一の要求配列へ整理し、同じ証拠を再確認。
- 承認済み専用全コマンド: `bash scripts/verify-article-foundation.sh`、`.build/Article-20261104-170956-25294.xcresult`。Article Core94件全成功。UI runner初期化は`com.apple.dt.XCTest.XCTFuture Code=1000: Timed out while enabling automation mode.`で失敗しexit65。以前のLocalAuthentication Code=-4とは異なる今回の環境障害として記録し、UI機能成功にはしない。
- 修正後a108134のCI実行41798035585で、Core273件・Article UI6件が全成功。製品2752/3050＝90.23%。同runの既存Native8件失敗は旧製品baselineと一致し、全体CIはfailureを維持。以前の109a21eの90.18%を今回候補の値として流用していない。詳細URL/commitと失敗名は`ci-evidence.md`。

## 保存応答喪失・容量境界・起動経路の回帰
- 既存testing contractと80%製品全体の対象を維持。
- Red: `bash scripts/verify-article-foundation.sh ArticleSessionTests ArticlePersistenceTests`、`.build/Article-20261104-154049-93960.xcresult`。18件中、新規作成/保存の確定後応答喪失→追加入力、符号化64MiB超の3回帰が失敗（11 assertion/error）。不確定後に競合し続け、容量超を成功確定する実経路を再現。
- Green20件: `.build/Article-20261104-154639-96434.xcresult`。不確定操作のID/固定本文/元基準値を保持し、元操作を先に照合。今回の入力は更新した基準版から別IDで保存。FileSystemの読込/新規書込に同じ64MiBのbyte境界を適用。
- 整理後Green22件: `.build/Article-20261104-154813-97221.xcresult`。照合中の新編集Cをdirtyで保持、容量失敗後に入力を縮めて保存可能、符号化64MiB直下の別Store再開、ファイルexact64MiB/超過1byte拒否を確認。
- CIによるUI実Red: commit `e9db8a440652fd74de813259954aa732a3d2645e`、実行`41785896792`。Article6件がarticle-open未発見、NativeInput8件も失敗。実行元/環境/URLと失敗一覧はroot所有の`ci-evidence.md`。
- UI修正候補commit `fea90ba`: NSApp.delegate直接置換を標準NSApplicationDelegateAdaptorへ変更、fixtureのfolder/album/4IDを既存階層へ整合、記事入口は確定後のみ。未確定時のTab順を維持し、Article UI試験はMainActor/activate/windowと入口の待機を追加。NativeInputTestsの期待値は変更していない。build-for-testing成功。修正後のUI機能成功はCI結果で判定する。
- 同commitのCI実行`41787840317`: Core262成功、UI32件中14件失敗は継続。Article6件はwindow待機失敗で、Application Disabled/メニューバーだけがありWindowなし。前回の待機/整合修正だけでは解消していない。
- 次候補commit `2d5f13e`（保存修正`d2b4d47`を含む）: fixture rootの値を`HZS_ARTICLE_TEST_ROOT`環境変数へ移し、非flag位置引数の差を除去。Picker中のwindow delegateはSwiftUIのままにし、記事編集中のみ元delegateを保持して調整、離脱後に復元する。OS管理のtemp baseだけ正規化し、生成job/利用者選択先のリンク拒否を維持。Debug診断はfixture有効/root指定有無/window数/modal有無のみで全引数や私的本文を出さない。build-for-testing成功、CI実行結果は確認中。
- 同commitのCI実行`41789820697`: Core269件成功。Article UI6件中5件成功し、記事開始/本文編集/保存再起動/取得不能/実合成1枚出力に到達。残る1件は「編集を続ける」のApp全体検索が複数要素に一致。既存Native8件の失敗は継続。
- 次候補commit `109a21e`: 確認sheet/dialogの確定コンテナ内へボタン検索を限定し、消滅と入力可能状態も検査。Pickerには背景のArticleWindowAttachment自体を生成せず、Article branchだけへ限定。既存Native期待値は維持。build-for-testing成功。CI`41791281896`で変更後と旧製品baselineを並列比較し、失敗時も既存製品coverageを別診断する（元試験失敗は維持）。結果は確認中。
- 同CI最終結果: **Core269件/Article UI6件が全成功**。Native26件中8件失敗は、旧製品commit`0e96d28407dc6b634ef492dcbbf7533e7c665c3a`の独立baseline26件中8件と完全一致。新規回帰と区別するが全体CI failureは保持。
- 同候補の既存製品checker: **2747/3046=90.18%**、80%以上を達成、対象除外/閾値低下なし。AppCoordinator141/206、ArticleView136/140、DebugFixture71/80、App27/37、PickerView24/28。失敗後のcoverage診断が成功したことと、試験job全体のfailureを区別する。正式なCI詳細はroot所有`ci-evidence.md`。
- 修正後の全体製品80%と同一最終commitのCI成功はまだ確認中。ローカルUI初期化エラーを機能Red/Greenへ置き換えない。
- 修正後U1専用コマンド: `bash scripts/verify-article-foundation.sh`、`.build/Article-20261104-154849-97534.xcresult`。Article Core90件成功、UI runnerは同じLocalAuthentication Code=-4で初期化失敗、exit65。
- 別途実行した全体コマンド: `bash scripts/verify-native.sh`、`.build/Native-20261104-155016-98891.xcresult`。既存179+Article90=269件成功、UI runner環境障害1、exit65。全製品2245/3026=74.19%、閾値80%未達。ローカル値であり、CI測定値とは区別する。

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

## 初期候補の品質ゲートと未確認（履歴）
- 初期全体run `.build/Native-20261104-151800-83081.xcresult`: **262成功（既存179+Article83）、UI runner環境障害1、exit65**。カバレッジ**2232/3006=74.25%、80%未達**。製品未計測なし、App/UIは0実行。当時CI未実行。
- 補完前の全体run `.build/Native-20261104-150759-78537.xcresult`: 249成功（既存179+Article70）、UI runner環境障害1、exit65。カバレッジ2155/2908=74.11%。
- 全体中間run `.build/Native-20261104-144845-69370.xcresult`: 237成功、UI環境障害1、2000/2648=75.53%。
- 全体run `.build/Native-20261104-150058-74614.xcresult`: 247成功（既存179+Article68）、UI環境障害1、2109/2860=73.74%。スクリプトexit65、80%未達。閾値/製品対象は変更していない。
- 同runの100記事/対象1000操作後の長文30回p95=0.015692416秒。独立store再開10回0.000323〜0.000610秒。アプリcold起動とは区別する。
- 同runの4000x3000合成画像30回最大0.094417417秒。5秒基線中央値35,455,816 bytes、25ms観測ピーク124,650,816、差89,195,000 bytes。OS lifetime peak131,515,280は事前fixture由来で、今回短ピークの帰属は未確認。512MiBを完全実証したとは記録しない。
- 実写真の現在編集/回転/色、元ライブラリ非変更、Sandbox実操作、UI焦点/狭幅/終了、アプリcold起動10回は本人確認が必要。
- 公開pushは自動承認レビューにより明示的送信承認不足として拒否され、CI未実行。候補commit732d203は完成/統合成功を意味しない。
