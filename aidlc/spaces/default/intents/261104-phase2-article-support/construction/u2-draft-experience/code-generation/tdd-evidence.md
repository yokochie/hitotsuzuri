# U2 TDD実行証拠

## runner準備
- 2026-11-04、変更前に `bash scripts/verify-article-foundation.sh ArticleSessionTests ArticleWorkspaceTests` を実行。
- exit 0、ArticleSessionTests 16件、ArticleWorkspaceTests 6件、計22件/失敗0。
- `.build/Article-20261104-211943-78925.xcresult`。これはU1依存境界の確認で、新規U2の合格証拠ではない。
- 専用runnerは許可された11クラスを厳密指定し、xcresult内の実行済みクラスを確認する。未作成クラス/0件を合格とは扱わない。

## 入力層 Red
- `bash scripts/verify-draft-experience.sh ArticleInitialContentTests ArticleMetadataInputTests`
- `.build/Draft-20261104-212144-79987.xcresult`、exit65。16件を実行し28アサーション失敗。
- 既存の初期値を返すAPIの準備後、末尾接尾辞が残る、日付がnil、不正rawを拒否しない、確認後の変更がconfirmedのまま、という機能上の失敗を確認した。コンパイル/runner失敗ではない。
- 例: `testInvalidDateStillRemovesSyntacticSuffix` の「記録@260231 != 記録」、`testGregorianLeapValidation` の「did not throw an error」。

## 入力層 Green
- 同じ限定コマンド、`.build/Draft-20261104-212346-81092.xcresult`、exit0、16件/失敗0。
- 絶対末尾ASCII判定、既存Gregorian暦検証を利用し、候補は新規factoryだけに限定した。
- 整理ではraw入力更新をchange操作へ閉じ、確認済み年月日の直接変更によるcandidate遷移漏れを防ぐ。
- 整理後も同じコマンドで16件/失敗0、exit0。`.build/Draft-20261104-212409-81364.xcresult`。

## 入力層 Unicode追加回帰
- 同じ限定コマンド、`.build/Draft-20261104-212603-82219.xcresult`、exit65、17件/1失敗。`testPrependScalarBeforeSuffixIsPreservedByteForByte` でU+0600がタイトルから消えることを確認。

## 関連付け層 Red
- `bash scripts/verify-draft-experience.sh ArticleAssociationTests`
- `.build/Draft-20261104-212534-81926.xcresult`、exit65、8件実行/8失敗（6件は未接続境界のinvalidInputが正常関連付けを拒否した捕捉エラー）。競合/不確定分類のアサーションも不一致。
- 既存記事を開けるrunner上で、関連付け・反復・不確定照合が未提供である機能失敗を確認。正常一覧だけの試験を部分失敗の証拠にはしないため、Green前に破損した別記事を加えて共存確認を補う。
- 最初の実装後run `.build/Draft-20261104-212659-82529.xcresult` も同8失敗/exit65。同期actor実装よりasync既定実装が選択されたため、操作のasync署名を明示して接続を修正した。成功とは扱わない。

## 関連付け層 Green・整理
- `.build/Draft-20261104-212734-82837.xcresult`、同限定コマンドで8件/失敗0、exit0。
- productionの既定失敗実装を除き、既存Fakeを明示適合した。保存/関連付けは同じupdateの排他・操作ID先行照合・確定へ整理。
- 入力も含む `bash scripts/verify-draft-experience.sh ArticleInitialContentTests ArticleMetadataInputTests ArticleAssociationTests` は25件/失敗0、exit0。`.build/Draft-20261104-212830-83204.xcresult`。Prepend追加回帰も成功。
- `bash scripts/verify-article-foundation.sh ArticleModelTests ArticlePersistenceTests ArticleRecoveryTests ArticleSessionTests ArticleWorkspaceTests`、53件/失敗0、exit0。`.build/Article-20261104-212855-83487.xcresult`。

## 関連付け取消境界 Red
- 先行run `.build/Draft-20261104-212926-83780.xcresult` はXCTest隔離のコンパイル失敗であり、機能Redと扱わない。
- 隔離を直して `bash scripts/verify-draft-experience.sh ArticleAssociationTests`、`.build/Draft-20261104-212945-83927.xcresult`。10件/2アサーション失敗、exit65。確定前cancel済みでも成功し、保存内容が旧版から変わることを検出。確定後取消は成功を保持する試験で確認。
- Green `.build/Draft-20261104-213028-84184.xcresult`、10件/失敗0、exit0。最終確定直前へ取消確認を整理後、`.build/Draft-20261104-213101-84396.xcresult` も同10件成功。
- C1読取/照合/開く/一覧/関連付けのWorkspace公開接続後、既存5クラスの同コマンドは53件/失敗0、exit0。`.build/Article-20261104-213208-84733.xcresult`。

## 業務層 Red
- `bash scripts/verify-draft-experience.sh ArticleProjectionTests ArticleEntryTests ArticleNavigationTests ArticleDraftSessionTests ArticleOutputPreparationTests ArticlePreviewRetryTests`
- 初回 `.build/Draft-20261104-213819-86565.xcresult` はObservable初期化順のコンパイル失敗。機能Redには数えない。
- 修正後 `.build/Draft-20261104-213846-86778.xcresult` は50件実行/59アサーション失敗、exit65、予期しない例外0。
- raw不正がdirtyにならず旧日付を保存、入口が記事を作らない、離脱先を保持しない、コピー/出力準備が境界を呼ばない、再試行が番号を要求しない、投影の固定4参照/本文/メモ/エスケープ不足、stale投影の開始未接続を検出。
- テスト用の待合せは2秒の上限で境界未接続をアサーション失敗にし、runnerや認証待ちではないことを分けた。

## 業務層 Green
- 同じ6クラス限定コマンド、`.build/Draft-20261104-214145-88147.xcresult`、50件/失敗0、exit0。
- pure投影・固定4参照・文字エスケープ、現在入力と保存済み出力準備、単一候補/離脱保留、raw日付を含む保存境界、番号別再試行を接続した。
- 整理: 既定投影をdetachedの不変値処理へ移し、保存中入力試験の待合せも有界に統一。
- 整理後同じ50件/失敗0、exit0。`.build/Draft-20261104-214304-88807.xcresult`。
- 既存セッション/Workspace22件も成功。`.build/Article-20261104-214421-89335.xcresult`。

## 境界統合 Red
- `bash scripts/verify-draft-experience.sh ArticleDraftIntegrationTests`
- `.build/Draft-20261104-214501-89641.xcresult`、11件/14アサーション失敗、exit65、予期しない例外0。
- 別記事同指紋の受入、一回OS応答の未接続、旧投影失敗の新記事への混入、現在選択への離脱破棄後の二重確認、新規切替先初期保存失敗で旧入力が消える境界を検出した。

## 境界統合 Green
- 同コマンド `.build/Draft-20261104-214637-90415.xcresult`、11件/失敗0、exit0。
- ArticleAppCoordinatorも同じPresentationと一回OS応答bridgeへ接続。`.build/Draft-20261104-214815-91064.xcresult`、11件/失敗0、exit0。
- 切替候補へ持ち越す明示離脱判断と、新規切替先の保留セッションを分離。初回作成失敗は未保存新規、旧編集からの切替失敗は旧作業維持として扱う。
- 整理後 `bash scripts/verify-draft-experience.sh ArticleInitialContentTests ArticleMetadataInputTests ArticleProjectionTests ArticleAssociationTests ArticleEntryTests ArticleNavigationTests ArticleDraftSessionTests ArticleOutputPreparationTests ArticlePreviewRetryTests ArticleDraftIntegrationTests`、88件/失敗0、exit0。`.build/Draft-20261104-214925-91545.xcresult`。

## Frontend runner準備
- 独立DEBUG fixtureの新規/再確定/複数候補/長名を既存合成写真fixtureへ追加。本人Photos/本人下書きは使わない。
- `bash scripts/verify-draft-experience.sh ArticleDraftUITests`、`.build/Draft-20261104-215108-92258.xcresult` はmacOS XCTestのスクロールAPIのコンパイル失敗。機能Redではない。
- 修正後同コマンド `.build/Draft-20261104-215143-92519.xcresult` はビルド成功、UITests-Runner起動後に70.656秒でexit65。
- 原文: `Failed to initialize for UI testing: Error Domain=com.apple.dt.XCTest.XCTFuture Code=1000 "Timed out while enabling automation mode."`。
- 機能テスト開始前の環境失敗であり、Frontend Red/Greenには数えない。TCC/DeveloperToolsSecurity/OS認証設定は変更していない。承認済みdispatchの環境失敗時停止条件に従い、Step14以降は未完のまま親へ報告する。

## Frontend Retry・Red
- 本人のRetry選択（3c79e56b）を記録してUnitを再開し、rootが同じ `bash scripts/verify-draft-experience.sh ArticleDraftUITests` を再実行した。
- `.build/Draft-20261104-215757-95489.xcresult`、exit65。12件実行、11失敗（予期しない例外0）、136.977秒。自動操作モードは初期化され、全12試験が実際に開始・終了した。
- `testMenuAndButtonOpenSamePersistedArticle` は成功。`article-copy`、`article-mode-preview` 等の未実装操作、撮影情報欄、候補/再確定、写真再試行、未保存Escape/閉鎖、幅変更の機能失敗を確認した。
- これはFrontendの先行Redであり、前回の自動操作モード初期化失敗と区別する。設定/TCC/認証を変更せず実行した。ここからStep15の画面実装へ続行する。

## Frontend 実装後の検証
- `.build/Draft-20261104-221000-99709.xcresult` はKeyPress overloadのコンパイル失敗。成功/機能Redとして数えない。
- 修正後 `bash scripts/verify-draft-experience.sh ArticleDraftUITests`、`.build/Draft-20261104-221104-414.xcresult`、13件実行/1失敗、exit65。追加のdirty候補→単一離脱確認とEscape、各幅の値保持は成功。
- 残る `testAllMetadataSaveAndRelaunch` は自由撮影情報の縦TextFieldが空で高さ2ptとなり、クリックでfocusを得られない実UI失敗。xcresultのfailureTextと画面要素矩形から確認した。

## 切替待ちの追加入力 Red
- `bash scripts/verify-draft-experience.sh ArticleNavigationTests`、`.build/Draft-20261104-221620-2976.xcresult`、10件/4アサーション失敗、exit65。
- 読込待ちと新規対象の初期保存待ちで、明示破棄後に生じた新入力まで切替で失う2経路を検出した。
- 同経路の採用直前に旧入力を確認し、フォームも読込中は保護。`bash scripts/verify-draft-experience.sh ArticleNavigationTests ArticleDraftIntegrationTests`、`.build/Draft-20261104-221729-3628.xcresult`、21件/失敗0、exit0。

## UI起動状態の切り分け
- `.build/Draft-20261104-221821-4092.xcresult` は14件すべて起動後のWindow待ちで失敗、exit65。新しいTab試験の機能Redとは扱わない。
- 失敗hierarchyとprocess pathから、XCTest対象はproject `.build/DerivedData` 内のfixtureアプリと確認。本人の非fixtureアプリは別PIDであり終了していない。
- fixture PID限定のAppKit記録に保存済みWindow識別子pickerの復元要求→`window=0x0 error=(null)`→`has no restoredWindow, skipping ordering` があった。同bundleIDの別アプリが直接原因とはまだ断定しない。
- UI fixtureのlaunchArgumentsにAppKit標準の `-ApplePersistenceIgnoreState YES -NSTreatUnknownArgumentsAsOpen NO` を指定し、プロセス内ArgumentDomainで保存済みWindow状態の持込みを隔離する。永続defaults/OS/TCC設定は変更しない。
- 隔離後 `.build/Draft-20261104-222313-5491.xcresult` はWindow表示が復帰、14件実行/4失敗、exit65。10件は機能成功。残りは自由情報入力、名前付きroot再使用で既に関連付いた候補fixture、Shift-Tabの本文間移動。
- fixture rootを試験ごとのUUIDへ変更し、同じ試験内の再起動だけ同じrootを使用する。自由撮影情報は空でも高さを持つ複数行TextEditorへ。追加Tab試験の本文逆順移動失敗をRedとして、0x19を含む明示焦点順へ接続する。
- `.build/Draft-20261104-222854-6744.xcresult` は14件/1失敗、exit65。Tab/Shift-Tabを含む13件が成功。残る撮影情報保存/再開は年欄がスクロール領域より上（Y300、領域Y330〜905）になってfocusを得られない失敗だった。
- マウスfocus時の自動スクロールをやめ、明示キーボード移動だけをスクロールへ接続。試験もisHittableだけに依存せず入力欄全体がviewport内にあることを確認する。

## UTF-8変更と一覧再読込 Red
- `bash scripts/verify-draft-experience.sh ArticleProjectionTests ArticleNavigationTests`、`.build/Draft-20261104-223451-8557.xcresult`、22件/4失敗、exit65。正準等価なe+結合アクセント→éの追加入力でも旧投影/離脱先を採用する不具合を再現。
- `bash scripts/verify-draft-experience.sh ArticleDraftIntegrationTests`、`.build/Draft-20261104-223536-8828.xcresult`、12件/1失敗、exit65。同様のplainText byte書換えを固定出力準備が受け入れる境界を再現。
- `bash scripts/verify-draft-experience.sh ArticleEntryTests`、`.build/Draft-20261104-223620-9055.xcresult`、9件/1失敗、exit65。部分失敗一覧の明示再読込が未接続であることを再現。
- 採用判定は共通指紋/UTF-8比較へ。読込中文字と部分失敗の再読込/不確定照合を画面へ接続する。
- 同4クラスをまとめて再確認: `bash scripts/verify-draft-experience.sh ArticleProjectionTests ArticleNavigationTests ArticleDraftIntegrationTests ArticleEntryTests`、`.build/Draft-20261104-223740-9510.xcresult`、43件/失敗0、exit0。

## 撮影情報UIの単独診断
- `.build/Draft-20261104-223846-9843.xcresult` は同UI14件/1失敗、exit65。残りは機材入力後の一時候補DialogをXCTestがscroll時の割込みと扱い、消えたDialogへの照合が失敗する箇所。
- 入力後にTabで確定して次の欄へ進む実操作をhelperへ加えた。exact methodの `xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/ArticleDraftUITests/testAllMetadataSaveAndRelaunch -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/Draft-Metadata-1793799999069.xcresult CODE_SIGN_IDENTITY=- test` は1件/失敗0、exit0、51.564秒。全群成功への代用はしない。

## raw入力/コピー境界 Red
- `bash scripts/verify-draft-experience.sh ArticleMetadataInputTests ArticleOutputPreparationTests`、`.build/Draft-20261104-225230-13497.xcresult`、18件/3アサーション失敗、exit65。
- 不正rawの異なるUTF-8表現が同一視されること、別記事IDの投影結果をcopyポートへ渡すことを検出。
- 追加 `bash scripts/verify-draft-experience.sh ArticleMetadataInputTests ArticleProjectionTests ArticleOutputPreparationTests`、`.build/Draft-20261104-225636-14977.xcresult`、32件/9アサーション失敗、exit65。編集を選び直した後の旧成功/旧失敗、copyとの二重投影、raw変更setterの正準等価判定も再現。
- 同コマンドGreen: `.build/Draft-20261104-225739-15295.xcresult`、32件/失敗0、exit0。表示意図と物理投影処理IDを分離し、単一ゲートの所有者だけが解放する。copyとpreviewは同じ文脈検証を共有する。

## 追加の品質fixtureと確認
- 新規の空本文とは別に、長名200文字・6本文各10000文字の保存済み下書きを準備。実content幅/AX要素位置/入力欄のisHittableで959/960/961を含む配置を検証する。
- 保存失敗・保存応答保留・結果不明・部分読込失敗・全写真取得不能のDEBUG注入は実記事保存境界を包む。Fakeの成功を実OS出力の証拠にしない。
- App/fixtureで表示画像アクセスを共有し、Pickerと記事へ別の表示キャッシュ/予算を新設しない。
- `bash scripts/verify-draft-experience.sh ArticleDraftUITests`、`.build/Draft-20261104-230159-16728.xcresult`、exit65。ビルド後、UITests-Runner PID16838が `The test runner failed to initialize for UI testing. (Underlying Error: Timed out while enabling automation mode.)` で停止した。
- 追加後の21件は機能実行開始前で未実行。xcresult summaryのtotalTestCount=1/failedTests=1はrunnerエラーの擬似項目で、1件のUI機能試験を実行したという意味ではない。
- Window復元隔離で実UIが復帰した記録と区別する。本人の非fixtureアプリ、永続defaults、OS/TCC/認証設定は変更していない。環境停止条件に従い、Step15〜18を未完として親へ報告。
- 全群の現在候補Green、正式全体検証/カバレッジ、性能/資源の新規計測、今回候補のCIはまだ完了していない。過去のU1/部分成功から合格値を流用しない。

## Frontend 再試行と長文幅計測の境界
- 本人のRetry選択後、renewed testing-posture briefを全文取得し契約の不変を確認。`bash scripts/verify-draft-experience.sh ArticleDraftUITests` は `.build/Draft-20261104-232659-22979.xcresult`、21件実行/1失敗、335.024秒、exit65。自動操作は初期化され、20件が実機能成功した。OS/TCC/永続defaults/本人の非fixtureアプリは変更していない。
- 未保存から別下書き選択の単一離脱確認、Escape、保存中追加入力、結果不明後の照合、全写真不能のC1入口、Tab/Shift-Tab経路も成功。
- 残る長文幅試験は6本文各10000文字の保持を確認した後、`article-layout` をStaticTextとして照会したline115で失敗。幅・配置の測定には未到達であり成功と記録しない。AX要素種別に依存しない照会で限定再検証する。
- 幅のexact methodを`xcodebuild ... -only-testing:HitotsuzuriUITests/ArticleDraftUITests/testWidthBoundariesKeepDraftAndReachMetadata ... test`で限定。`.build/Draft-Width-20261104-233400.xcresult`と`233700`は実幅644/要求640のassertion失敗。マウス取手補正後`234000`は640へ到達したが人物欄の可視領域検証失敗。`234300`は640/人物欄到達後、959へのドラッグが949で止まり失敗。閾値や測定値は変更していない。
- DEBUG fixtureだけの実NSWindow内容サイズ指定を追加。最小幅/Geometry値は上書きしない。`234600`/`234900`/`235200`は640の配置・人物欄へ到達後、959で上部写真へのスクロール失敗。最後の実AX矩形から、本文TextEditorが幅再配置時に高さ2460ptへ膨らみ、外側フォームが過大になる実装境界を確認した。本文140pt・自由情報80ptの編集領域へ固定し、内部スクロールと外側フォームの余白ホイールを分離して再検証する。
- `235500`は640/959/960/961の実幅/配置/人物欄に到達後、1200のDEBUGメニュー項目取得に失敗。fixtureを直接5ボタンへ整理した。`xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/ArticleDraftUITests/testWidthBoundariesKeepDraftAndReachMetadata -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/Draft-Width-20261104-235800.xcresult CODE_SIGN_IDENTITY=- test` は1件/失敗0、80.890秒、exit0。
- 実Geometryは640/959でnarrow、960/961/1200でwideをそれぞれ確認。各幅で写真要素とタイトルの配置、人物欄全体のviewport内frameとisHittable、Tabで本文から撮影情報まで到達を検証した。外側16pt余白への実ホイールとTextEditor内部スクロールを区別する。長名200文字・6本文各10000文字の保存/再起動後保持、プレビュー往復、締め末尾の追加入力/保存まで同じ試験で成功。全群の再確認へ進む。
- 修正後 `bash scripts/verify-draft-experience.sh ArticleDraftUITests`、`.build/Draft-20261104-234738-30953.xcresult` は21件/1失敗、387.196秒、exit65。長文5幅ケースを含む20件は成功。日付確認マウス操作が失敗した。
- exact診断 `.build/Draft-Date-20261104-235600.xcresult` は1件/1失敗、exit65。確認ボタンはenabled/hittableともtrueだが矩形Y892〜916に対しviewport下端905で半分クリップされ、確認済みへ遷移しなかった。ボタン全体を実スクロールで表示し、上下frame/enable/hittableも確認してからクリックする。
- `xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/ArticleDraftUITests/testDateConfirmationAndRemovalAreExplicit -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/Draft-Date-20261104-235900.xcresult CODE_SIGN_IDENTITY=- test` は1件/失敗0、15.495秒、exit0。20件と限定1件を合算して全群Greenとは扱わない。必要な期限/性能試験追加後、専用主コマンドで最新全群を確認する。

## 表示画像の待機時間 Red
- `bash scripts/verify-draft-experience.sh ArticlePreviewRetryTests`、`.build/Draft-20261104-235653-34873.xcresult`、9件/2アサーション失敗、exit65。fakeの各応答で単調時計を4秒進めると、後続番号の期限が受付時15秒より後ろへずれ、16秒目の結果がreadyになることを再現した。
- load受付で四番号に同じ絶対期限を固定し、期限後の待機番号はdriverへ渡さずtimedOutとする。番号別の明示再試行は再試行受付から新しい15秒とする。既存LocalImageAccessのキュー/資源予算と高解像度30秒経路は変更しない。
- 同コマンドGreen `.build/Draft-20261104-235743-35256.xcresult` は9件/失敗0、exit0。整理後に実LocalImageAccessの無応答driver/手動単調時計も使い、受付15秒で全番号が理由付き取得不能へ到達し、未開始番号はOSへ渡さず、期限後の遅い応答も不採用となることを追加検証した。

## 規定負荷・表示資源の計測
- `bash scripts/verify-draft-experience.sh ArticlePreviewRetryTests ArticleDraftIntegrationTests` の追加計測初回 `.build/Draft-20261104-235958-36201.xcresult` は画像参照の期待値を`images/`なしに書いた試験不備で失敗。製品境界のRedではない。既存C3契約の固定参照へ訂正した。
- 同コマンド `.build/Draft-20261105-000112-37103.xcresult` は22件/失敗0、18.153秒、exit0。実100記事、対象1000操作（各履歴も長文）、名称200文字/導入・4本文・締め各10000文字を準備して計測。30回保存p95=0.0174765秒/max=0.018164583秒、30回Coreセッション再開p95=0.004798542秒/max=0.004803042秒、100回純粋投影p95=0.00970775秒/max=0.010232209秒。
- 別10回のstore/session再生成p95/max=0.004194084秒。OSディスクキャッシュは消去しておらず、アプリのcold起動や実UI入力可能時刻への代用はしない。
- `bash scripts/verify-draft-experience.sh ArticlePreviewRetryTests`、`.build/Draft-20261105-000249-38152.xcresult` は11件/失敗0だが、30反復が短く25ms samplerは1点だったため、それだけで資源計測の十分な証拠とはしない。
- 表示画像所有中の観測期間（各50ms、表示完了時間へは加算しない）と無応答要求取消30回を追加。`.build/Draft-20261105-000412-38713.xcresult` は11件/失敗0、7.365秒、exit0。512px合成driver/実LocalImageAccessの30回、5秒中央値9,683,688B、57サンプル/最長間隔0.035150208秒、samplepeak17,695,464B/増分8,011,776B。OS lifetime peakは9,683,688→17,728,232B、直接保持ピーク4,194,304B。表示最大0.001966875秒、取得待ち取消30回の受理最大0.000045708秒/論理終端最大0.000368625秒。実写真/実PhotoKitの時間は別に未確認。

## native描画・入力準備の計測準備
- 既存DEBUG fixture内に100記事/対象1000長文操作の準備と、要求handler受付→native windowのdisplayIfNeeded完了の計測を追加。編集/再開/追加入力は実NSTextFieldのwindow所属、enabled/editable、currentEditorがfirstResponderで編集可能な条件も要求する。入力計測開始はBinding setterのcontent代入前。Core採用だけを終了としない。
- `.build/Draft-DisplayPerformance-20261105-000900.xcresult` は計測コードの演算子空白不備でコンパイル失敗/未実行。`001000`はfixture準備中のdisabled入口をexistsだけでクリックする試験不備、`001300`/`001600`/`001900`/`002200`はDEBUG計測値のAX取得不備で先頭計測に未到達。いずれも性能合格/製品機能Redとは扱わない。
- 計測JSONは固定分類と数値のみ。本文・写真ID・記事ID・パスを含めない。macOS StaticTextのカスタムaccessibilityValueが空となることを確認し、実Textの1行数値JSONを読む形へ訂正。現在の限定計測の完了値は別途記録する。
- `.build/Draft-DisplayPerformance-20261105-002500.xcresult` は全予定操作後、入力計測p95=3.016423958秒の未ready timeoutで失敗（472.536秒）。保存中表示31件はp95=0.010449125秒/max=0.011710208秒。入力途中の確定前NSTextField.stringValueと、現在のfield editor.stringを混同した計測境界だった。最新の入力受付/完了番号を照合し、field editor自身の文字列とUTF-8で比較する。未ready timeoutは別カウンタへ記録し常に失敗とする。
- `.build/Draft-InputMetric-20261105-002700.xcresult` はObservationマクロの複数宣言によるコンパイル失敗/未実行。訂正後 `.build/Draft-InputMetric-20261105-003000.xcresult` は実入力診断1件/失敗0、26.616秒、exit0。3入力sample最大0.02780275秒。最新要求/field editor完了の一致を確認したが、30試行の代用にはしない。
- 追加Loading/Coldの`003500`/`003700` bundleは演算子空白と非公開XCUIApplication.processID参照のコンパイル不備/未実行。fixture自身の数値PIDだけを計測JSONへ載せ、distinct processの件数だけを通常計測ログへ出す。
- `.build/Draft-LoadingCold-20261105-004000.xcresult` はcold入力準備の1件が成功（67.480秒）。準備済み100記事/1000操作を使い別10プロセスで、App.init→実enabled/editable field editorがfirstResponderとなるまでp95/max=1.130749秒。fixture準備の初回起動、App.initより前のOS bootstrap、OSディスクキャッシュcoldは含めず別未測定。Loadingの1件はprobeの更新世代にisLoadingが無く、実文字は表示されたが計測値未取得で失敗した。
- isLoadingをprobe世代へ追加し、`xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/ArticleDraftUITests/testLoadingLabelsThirtyEntryAndListRequests -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/Draft-Loading-20261105-004300.xcresult CODE_SIGN_IDENTITY=- test` は1件/失敗0、553.751秒、exit0。開始読込中文字30件p95=0.05061275秒/max=0.057774625秒、一覧読込中文字30件p95=0.068157083秒/max=0.070753542秒。実storeの応答保留Fakeを明示armし、handler受付→native window描画を測った。通常I/Oを固定sleepで引き延ばしてはいない。
- 最新候補では既に満たされたexists/非存在/計測値を即判定し、未達時だけ同じ有界XCTest waitへ進む。回数・閾値・native終点は維持して試験ツールの初回poll待ちだけを削減する。probeが観測したsessionIDも現在記事と一致させる。画像待ちの入力も30回へ含めるためperformance fixtureだけ無応答表示driverを使い、各試行で旧要求取消→新世代へ再要求する。通常表示/高解像度経路の期限や資源予算は変更しない。

## 容量枯渇による停止と承認済み再開
- `bash scripts/verify-draft-experience.sh`、`.build/Draft-20261105-004621-53146.xcresult` はCore103件成功、UI25件中16成功/9失敗。xcodebuild exit73、749.491秒。logarchive作成でCode28 `No space left on device`、結果保存でも`mkstemp: No space left on device`が発生した。結果bundleはInfo.plistがなくreaderで読み取れず、確定済みの全群成功/カバレッジとして使えない。
- UI失敗は写真取得中文字、保存成功文字、複数候補、部分一覧、プレビューdirty、再確定候補、保存中入力、不確定保存、長文本文保持の9件。容量不足を全失敗の原因とは断定せず、空き容量回復後に同じsourceで再検証する。
- 容量停止時点のconsole実行値はCore保存30回p95=0.0156405秒/max=0.016310583秒、Core再開30回p95=0.004960083秒/max=0.005010708秒、投影100回p95=0.009917542秒/max=0.011959458秒。UI cold10プロセスp95/max=1.159854875秒、開始読込文字30回p95=0.057276292秒/max=0.083340583秒、一覧読込文字30回p95=0.064868875秒/max=0.078181875秒。5種30回の新しい全測定は未完であり、部分値を合格へ流用しない。
- 本人が整理+Retryを選択し、rootが承認されたU2専用ArticleFixture-draft-*115 rootと旧Draft-*.xcresult72個だけを削除した。最新の不完全bundle・source・文字記録は保持。空き容量は22GiBへ回復。削除された過去の詳細bundleは現存すると扱わず、上の文字記録を保持する。追加削除は行わない。
- renewed briefを全文取得し、同じ契約/計画の14段階完了・Step15継続を確認。新UI末尾の自分が加えた空行だけを除去し、動作sourceを変えず専用主コマンドを再実行する。OS認証/TCC/本人の非fixtureアプリは変更しない。

## 容量回復後の最新専用主run Green
- `bash scripts/verify-draft-experience.sh`、`.build/Draft-20261105-054710-2230.xcresult`、exit0。Core103件/失敗0（25.524秒）、UI25件/失敗0（1046.958秒）、合計128件成功。xcodebuild test elapsed1139.769秒。確定bundleのsummaryもPassed/128成功/0失敗/0skipを確認。前回9失敗は今回すべて通過したが、個々の前回失敗原因を容量だけと断定はしない。
- 開始時空き22GiB、Core終了後22GiB、loading終了後21GiB、全run終了後21GiB。追加削除/OS認証/TCC/永続設定変更は行っていない。macOS27.2(26B123)、Xcode27.2(27B52)、arm64 MacBook Pro。終盤の電源読取はAC Power（全期間の電源状態固定までは保証しない）。
- 実100記事/対象1000操作・名称200文字/6本文各10000文字: 保存30件p95=0.0153625秒/max=0.015383125秒、Core再開30件p95=0.004815292秒/max=0.004845583秒、純粋投影100件p95=0.00949625秒/max=0.009798375秒。別10回store/session再生成p95/max=0.004397958秒。action logから数値を回収した。Core採用とUI入力可能を混同しない。
- 同じ規定負荷の実UI: 保存中文字31件p95=0.01702975秒/max=0.022092584秒。保存保留と画像取得中を同時に維持した30入力試行（60変更sample）p95=0.015736042秒/max=0.017501792秒。preview描画30件p95=0.172770917秒/max=0.174691958秒、編集入力準備30件p95=0.150008041秒/max=0.153564792秒、再開入力準備30件p95=0.159037917秒/max=0.161352958秒。全kindの未ready timeout=0、保存/入力は最大値も0.5秒以内。性能UIケース268.197秒で成功。
- 応答保留Fakeの開始読込文字30件p95=0.085902084秒/max=0.112881375秒、一覧読込文字30件p95=0.067085792秒/max=0.0707185秒、timeout=0。ケース358.210秒。別10プロセスのApp.init→実field editor入力準備p95/max=1.17845秒、coldケース55.116秒。App.init前のOS bootstrap/OSディスクキャッシュcoldは未測定。
- 表示資源30回は合成512px/実LocalImageAccessをCoreテストプロセスで測定。5秒中央値30,425,880B、samplepeak30,425,880B/差分0、60サンプル/最長30.1385ms、直接保持ピーク4,194,304B。OS lifetime peakは46,121,728Bで前後同値（過去ピークのため今回区間への帰属はできない。保守的なlifetime上界でも基準との差は512MiB未満）。表示完了最大0.002026458秒、取得待ち取消30件の受理最大0.000060875秒/論理終端最大0.000437209秒。実写真/Photosとアプリ全体の実機資源条件は本人確認と区別する。
- 640/959はnarrow、960/961/1200はwideの実Geometry/配置/metadata全体のviewportとisHittable、長文保存再起動/プレビュー/締め末尾編集が最新全群で成功（幅ケース94.824秒）。全入力Tab/Shift-Tab、Command-S、本文Return、単一離脱シートとEscape、候補/再確定/部分失敗/写真不能も成功。XCTest内部QoS警告は残るため警告なしとは記録しない。
- source33パスは同じmanifestのまま。新UI EOFだけを整理し、本人の既存EOF/共有scheme等は保持。Step15/16を完了とし、正式な全体検証・全製品80%以上・同候補CI・独立レビューはroot担当の後続確認としてStep17/18を未完のまま返す。専用runの部分カバレッジを全体値へ流用しない。

## 全体回帰の起動障害による停止
- rootの`bash scripts/verify-native.sh`先行実行`.build/Native-20261105-060716-8008.xcresult`は制限付き実行環境で`com.apple.testmanagerd.control` error159 `Sandbox restriction`となり、試験開始前にexit65。製品機能Redではない。同じ承認済みコマンドを通常のUI実行権限へ是正し、OS/TCC/認証設定は変更しなかった。
- 通常権限の`.build/Native-20261105-060746-8142.xcresult`ではCore376件（U1 target154、U2 target151、U3 target71）とArticleDraftUITests25件が全成功。追加UIの読込文字30+30は開始p95 45.19ms/最大95.55ms、一覧p95 64.41ms/最大65.80ms。5種性能も成功し、プレビューp95 174.04ms、編集復帰153.27ms、再開142.77msとなった。
- 続くArticleFoundationUITests6件とNativeInputTests7件は、共通launch helperの最初のWindow存在確認で失敗。AXはApplication Disabled・Windowなしだった。残りも同じ起動失敗を繰り返していたため、今回のscript PID8142の子であるxcodebuild PID8144を確認してSIGINTを送り、停止した。本人の非fixtureアプリは停止していない。
- 確定bundle summaryは401成功/14失敗/0skip/total415、result Failed。14件の内訳は起動確認13件と、停止時のNativeInputTests1件のTesting was canceled。NativeInputTestsの残り18件は未実行。xcodebuildは停止処理でexit75。全体合格・全既存機能の成功とは扱わない。
- 失敗したfixture PID14638のAppKitログで`shouldRestoreState=1 hasPersistentStateToRestore=1`を読取確認。既存2 helperは`--article-test-fixture`/`--ui-test-fixture`だけで起動し、成功済みArticleDraftUITestsが使う`-ApplePersistenceIgnoreState YES -NSTreatUnknownArgumentsAsOpen NO`は付いていない。復元が唯一の原因と断定せず、試験プロセスだけへ同じ起動隔離を適用して再検証する案とした。未適用。
- scriptの後段カバレッジ検査はxcodebuild非0で未実行。全製品80%以上、CI、独立レビューは未完。通常権限の検証中に容量不足は再発せず、途中境界の空きは20GiBだった。
# 検証区分の改訂（2026-11-05）

`python3 scripts/test-native-runner.py` を旧runnerへ実行。8件中6件が意図したassertion失敗、exit1、0.656秒。旧専用runnerは--smoke/--functional/--performanceをexit2で拒否し、無引数はsmokeを先行せずxcodebuild1回だった。未知引数拒否と0件拒否は成功。隔離したPATHの代替xcodebuild/xcrun/swiftのみ実行し、実Xcode/UIは起動していない。これはrunner契約のRedであり、製品機能のRedではない。

## 改訂実装と短いGreen

- `python3 scripts/test-native-runner.py`: 同じ8契約すべて成功、exit0、1.395秒。実Xcodeを使わず、プロジェクト内の隔離PATHに置く代替xcodebuild/xcrun/swiftで、smokeのみ、通常、性能、無引数all、厳密クラス指定、未知引数拒否、0実行拒否、smoke失敗後の後続停止を実行した。smokeの代替結果も両方式のtest methodを含める。
- `bash -n scripts/verify-draft-experience.sh scripts/verify-native.sh`: exit0。Pythonは上の実実行で構文も確認した。
- 新しい共通runnerは実xcresultの各指定クラスに成功したtest caseがあることを検査する。smokeは2方式それぞれのmethod名も要求。xcodebuild失敗時は後続を起動しない。
- 無引数正式runnerはsmoke後に全4試験target（通常/性能を含む）を一つのbundleへ実行し、既存check-coverage.swiftの加重80%をそのbundleへ適用する。部分実行では全体coverage/全体成功を判定しない。分割率を平均しない。
- ArticleDraftUITestsは23件。元25件から重い3件をArticleDraftPerformanceUITestsへ本文のassertion・回数・閾値・timeout判定ごと移動し、入口/一覧loading各1回の通常ケースを追加した。FixtureSmokeUITestsは別の2件。通常の入力計測1件と保存待機/画像不能・再試行/キー/日付/幅/閉鎖の既存ケースは保持。
- 旧ArticleFoundation/NativeInputの起動もFixtureLaunchへ寄せ、成功したU2と同じプロセス限定復元隔離引数を使用。OS/TCC/永続defaults・本人非fixtureアプリPID80796へ操作していない。製品Tab不具合は今回の変更範囲へ入れていない。
- CIは通常/詳細性能jobを分離、30分制限を維持。workflow_dispatchのverify_allで全対象と単一bundleの全体coverageを明示実行する。旧baseline-native jobは保持。改訂後CIは未実行。

## 改訂後smoke一度の実行と環境停止

- `bash scripts/verify-draft-experience.sh --smoke` をrequire_escalatedで一度実行。
- `.build/Smoke-20261105-071544-808ae00f556e4ce7ab401a57ce363048.xcresult`
- App/Core/全試験targetのビルド・署名は完了し、新規Swift/helper/性能クラスもコンパイルされた。
- 2026-11-05 07:16:51 JST、UI automation初期化で `XCTFuture Code=1000: Timed out while enabling automation mode.`。xcodebuildはexit65、testing elapsed72.717秒。
- xcresult summaryはpassed0/failed1/total1だが、その1件はrunner初期化エラー。**smokeの2機能ケースは未実行**で、機能アサーション失敗やGreenではない。通常/性能UIは起動していない。
- restrictedでの最初のsummary読取はTestReport cache保存権限によりexit64。読取のみrequire_escalatedで是正すると上記summaryを取得できた。OS設定変更はない。
- 許可どおり即停止し、再試験・追加build・OS操作なし。空き容量は終了後23GiB。過去128成功/正式401成功14失敗と18未実行の証拠は改訂後成功へ流用しない。全体coverage/改訂後CIは未確認。

## 所有fixtureと回収の境界

- UI共通helperが各ケースで発行する `uitest-<uppercase UUID>` だけを起動envへ設定。同一ケースの再起動中は同じrootを保持する。
- 最後のteardown（正常・assertion失敗共通）で当該fixtureアプリを止め、DEBUG cleanup専用envで一度起動。アプリ自身の正規化済みOS temp直下 `ArticleFixture-uitest-<UUID>` のみを対象に、厳密UUID、直接の親、symlink非経由を照合して回収し、不在確認後の固定メッセージを試験する。任意パス・過去bundle・本人データは対象外。
- 今回はsmoke本体未実行のため、UI teardownの実回収も未実証。失敗ケースの回収、同一ケース再起動保持は実装済み・コンパイル済みだが、改訂後実UIによる確認は残る。
- Core helperはこのプロセスが新規発行した `.build/article-tests/<UUID>` のみをregistryへ登録し、normal process exit時に親/UUID/リンクを照合して回収する。既存rootを列挙・削除しない。Core実行は今回行っていないため実回収未確認。強制終了/クラッシュではteardown/atexitが走らず未回収になりうる。
- runner契約自身の隔離rootはTemporaryDirectoryでケース終了時に回収。旧runnerへのRed時だけ旧scriptがresult-root指定を解釈しないため、代替結果 `.build/Draft-20261105-071138-34072.xcresult` (selection.json935B) と `.build/Native-20261105-071138-34085.xcresult` (414B) が残った。これらはfake selection記録で実XCTest/coverageの証拠ではなく、結果bundle削除はしていない。
- manifestは既存33パスを保持し追加10パスを含む43パス。改訂対象14ファイルの `git diff --check` はexit0。Step1–14は既存実装/過去TDD証拠とファイル存在を照合して復元。15–18は改訂後UI/全体/CI/最終確認が未実施のため未チェックのままとする。

## 本人によるautomation承認後のsmoke（2026-11-05）

- 本人64726db0の再実行指示により、同じソースの `bash scripts/verify-draft-experience.sh --smoke` をrequire_escalatedで一度実行。
- `.build/Smoke-20261105-072204-0250699504d847fcafcc0dad607d5ddd.xcresult`、exit65、testing elapsed45.911秒。UI suiteは2件実行/0成功/2失敗/0skip、34.561秒。
- automation初期化は成功。記事fixtureはWindowと有効・hittableなarticle-open、Picker fixtureはWindowと有効・hittableな「テスト親A」のアサーションを通過した。
- 両ケースのteardownでFixtureLaunch.swift:26の「当該ケース所有rootの回収を確認」が失敗。cleanup起動後に「試験データを回収しました。」という固定メッセージを10秒以内に観測できなかった。実削除の成功/不成功はこの結果だけでは断定しない。
- 最初の失敗をrootへ即報告し、同一smoke呼出しの確定終了後に停止。指定された関連4ケース（代表loading・metadata保存/再起動・Foundation入口・Native入口）はsmoke未成功のため未実行。追加build・反復・source修正・OS/TCC/本人非fixtureアプリへの操作は行っていない。
- 前回のautomation初期化エラーとは別の、実行済みcleanup確認アサーション失敗である。全体/性能/coverage/CI成功とは扱わない。ソース凍結は継続し、この追記のみを行った。

## 所有rootのURL表現差修正と限定再検証（2026-11-05）

- 本人bf4f9b59の指示でDebugFixture.cleanOwnedRoot / DraftOwnedRoots.cleanUpの2箇所だけを修正。directory URLの等価比較を正規化済みpath比較へ替え、isSymbolicLinkを明示拒否。UUID・直接の親・名前空間条件は保持。manifestは43パスのまま。
- 先行Redは前節のsmoke2件cleanup失敗と、rootが読み取りSwiftで観測した不存在rootのexists=false / parentMatches=true / resolvedMatches=false。修正前の機能失敗は成功へ書き換えない。
- 短い隔離確認はPython inlineが実DebugFixture関数をソースから読み出し、baseだけをproject内の固有.build/cleanup-contract-UUIDへ注入してSwiftで実行。exit0、0.867秒。不在rootとmarker入り所有rootの回収、通常/dangling symlinkと異なるnamespaceの拒否、リンク先canary保持を確認し、この確認で生成した固有rootだけをdefer回収した。このproject内baseでは旧URL比較はtrueだったため、root観測のOS temp条件と同じ再現とは主張しない。Core側は同じguard修正をコンパイルしたが、normal process exitの回収は今回実行していない。
- sourceを凍結後 `bash scripts/verify-draft-experience.sh --smoke` を一度実行。`.build/Smoke-20261105-072933-ac2ed8edcd774c6db450fd1d5ae6d5ff.xcresult`、exit0、2成功/0失敗/0skip、UI16.148秒、testing16.923秒。記事とPickerの各Window/入口、両teardownの回収成功メッセージまで確認した。
- 続いて許可された4メソッドだけを以下の単独コマンドで実行（require_escalated）。

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/ArticleDraftUITests/testEntryAndListLoadingCanComplete -only-testing:HitotsuzuriUITests/ArticleDraftUITests/testAllMetadataSaveAndRelaunch -only-testing:HitotsuzuriUITests/ArticleFoundationUITests/testStartShowsFourBodyFields -only-testing:HitotsuzuriUITests/NativeInputTests/testRunnerLaunchesSyntheticFoldersOnly -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/U2-Related-20261105-073010.xcresult CODE_SIGN_IDENTITY=- test
```

- 確定summaryは4実行/3成功/1失敗/0skip、exit65、UI91.659秒、testing103.223秒。代表loading・Foundationの本文4欄・Nativeの合成フォルダ入口は成功。4ケースすべてのteardown回収確認も通過した。既存QoS priority inversionのruntime warningが3件ある。
- testAllMetadataSaveAndRelaunchはArticleDraftUITests.swift:54で失敗。再起動後の場所欄actualは `58£¢§2¢º∂8£∂∂ç§ª2ºº∂∂8£∂∂ç§¶`、expectedは `場所👩‍👧`（どちらも試験用入力）。typeText(expected)とTab操作のログはあるが、保存前の場所欄実値を読むassertion/logはなく、入力注入時点か保存/復元時点かは未切分け。保存の破損と断定しない。
- 当該失敗を即rootへ報告し、同一4件runの確定終了後に停止。アサーション・source・試験条件は変えず追加反復なし。全体/性能/CI・製品Tab不具合・OS/TCC/本人アプリ操作は行っていない。過去/今回の部分成功を全体成功やcoverage達成としない。TDD追記後、全writeを再凍結する。

## 保存前の実入力値を観測する限定診断（2026-11-05）

- 本人197d1b57のRetryにより、ArticleDraftUITests.testAllMetadataSaveAndRelaunchだけを最小変更。replace直後に場所/機材/フィルム/人物/年/月/日の実valueを期待値と照合するXCTAssertEqualを追加し、固定fixture ID付き「保存前のfixture入力確認」メッセージを付けた。continueAfterFailure=falseと既存の保存後再起動assertionは保持。App/shared helper/入力方式/閾値は変更しない。manifest43パスのまま。
- 前回の場所不一致を先行失敗証拠として保持し、同じRedだけの再実行はしない。ソース凍結後、次の1メソッドだけをrequire_escalatedで実行した。直前に成功済みのsmoke・他UI・性能・全体は実行しない。

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/ArticleDraftUITests/testAllMetadataSaveAndRelaunch -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/U2-Metadata-Input-20261105-073700.xcresult CODE_SIGN_IDENTITY=- test
```

- 確定summary: 1実行/1成功/0失敗/0skip、exit0、UI38.688秒/testing49.882秒。保存前の7欄の実値がそれぞれfixture期待値と一致し、元の保存後再起動の場所「場所👩‍👧」と年「2024」の照合、最後の回収確認も通過した。QoS priority inversionのruntime warningは1件。
- 今回は最初の入力不一致も保存/復元後不一致も発生しなかった。前回の不一致は再現せず、原因が入力注入/保存/復元のどれかは未確定。追加のAX実値読取が入った一回の成功を根本原因修正や安定性実証とは扱わない。OS入力source/clipboard/TCC/認証/本人アプリは操作せず、追加反復なし。TDD追記後、全writeを再凍結した。

## 写真再試行のキー到達回帰・計測準備（2026-11-05）

- 最新正式briefのcontractを照合。DEBUG fixture driverの実request数を番号順の読取専用AX値として観測する最小配線と、新しいTab/ShiftTab/Space回帰を先に追加。まだ製品のfocus経路は変更していない。
- 最初の限定run `.build/U2-Retry-Keyboard-Red-20261105-074600.xcresult` は1件実行/失敗1/exit65、UI11.234秒/testing22.842秒。初期要求を1回固定とした計測前提が実測[2,2,2,2]に合わず、キー操作前に失敗した。共有driverへPicker復元要求も届くので、この失敗は機能Redとはしない。
- 初期値は実測baselineへ変更し、以後の各Spaceで当該番号だけが厳密に+1、他番号不変、逆順/順方向各1回の終了時は全番号baseline+2を要求する。アクションの実証条件は弱めない。

### キー到達の意図したRed

- 初期要求を実測baselineへ直した同じ限定1件を、製品focus未変更で実行。`.build/U2-Retry-Keyboard-Red-20261105-074550.xcresult`、exit65、1件/失敗1、UI14.554秒/testing26.059秒。
- baselineと非空タイトルの確認は通過。titleからShiftTab→Space後、写真4のrequest数が+1にならず `キーで写真4の実要求が増える` のアサーションが3秒timeoutで失敗した。旧fixed順序はこの位置から保存へ戻り、再試行ボタンに到達できない。この失敗を機能Redとして、以下の最小focus接続へ進む。

### 写真再試行のキー到達 Green・整理確認

- retry1〜4を既存FocusStateへ接続し、editing時の既存入力→probe/back/edit/preview/save順を維持した末尾へ追加。取得中は順序に入れず、各ボタンのscroll IDでキー移動時の可視化へ接続した。マウスとSpaceは同じretryPhoto関数を呼び、同じ実previews.retryへ渡す。プレビュー画面には存在しないボタンを順序へ加えない。
- DEBUG計測は共有fixture driverの本物のrequest受付数だけを観測する。私的本文・ID・パスを追加AX値へ出さず、固定番号順の数値だけを公開。製品の成功表示や新たな利用者向けフィードバックを作っていない。
- 新規回帰は利用不能写真fixtureでShiftTab逆順4→1とTab順方向1→4により各番号をSpace実行。各回で対象番号の要求だけが厳密に+1、他番号不変、合計baseline+2、非空ASCII導入文とタイトル不変、対象ボタンがviewport内でhittableであることを確認する。本文canaryは入力注入の別問題を混ぜないためASCIIとし、既存Unicode試験は保持した。
- 次の限定2件をrequire_escalatedで実行した。

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/ArticleDraftUITests/testTabAndShiftTabCanRetryEveryUnavailablePhotoWithoutLosingText -only-testing:HitotsuzuriUITests/ArticleDraftUITests/testTabAndShiftTabReachMetadataAndPreviewWithoutSystemSetting -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/U2-Retry-Keyboard-Green-20261105-074700.xcresult CODE_SIGN_IDENTITY=- test
```

- 確定summary: 2実行/2成功/0失敗/0skip、exit0、UI46.379秒/testing57.050秒。新規回帰26.701秒、既存の本文・日付・自由情報からプレビューへのTab/ShiftTab代表19.677秒。各teardownの所有root回収も成功。QoS priority inversionのruntime warningは2件。
- 整理確認ではクリック/キーの実処理重複をretryPhotoへ集約済み、既存入力順・本文所有・画像処理期限/予算を変えていないことを確認。Green後に追加の製品変更は不要で、無変更の同一2件を重複実行しない。
- 変更はArticleView/ArticleAppCoordinator/DebugFixture/ArticleDraftUITestsと本TDD記録のみ。既存manifest43パス内で新規pathなし。4ソースのdiff-checkはexit0。通常Article UIは追加回帰を含む24件になった。全体/性能/coverage/CIは今回実施しておらず、部分2件の成功から推定しない。source/記録を凍結してrootへ返却した。
## CI失敗後の計測/キー前提の限定調査（2026-11-05）

### 観測間隔の修正

- 本人38d447b5のRetryと最新正式briefに基づく限定対応。先行失敗はCI41928800409/commit771d101fbb6be38a76b84d1a422bf5a1b29598b2のtestDisplayMemoryAndCancellationThirtyTrials。longestInterval=0.107867292sが0.05sを超過し、メモリ量自体は予算内だった。この失敗を保持し、同じ全体Redは繰り返さない。
- 旧samplerはTask.detached(.high)の25ms sleep後にSwift共有executorへ再開する方式だった。新しいDraftMemorySamplerは試験プロセス内だけの専用Thread/userInteractive QoSで10ms間隔を要求し、実時間を記録する。SwiftUI/MainActor/Swift taskの再開待ちとは独立させるが、OSによる停止を保証で隠さず、実間隔が50msを超えれば引き続き失敗する。
- 同じsamplerで実5秒以上のbaseline中央値を取り、baselineと本処理を含む実最大観測間隔も判定。OS lifetime peakの前後値、直接保持256MiB/プロセス増分512MiB、30回表示/取消の元基準は維持。samplerの終了と最終観測を待ち、throw時もdeferで停止する。

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriU2Tests/ArticlePreviewRetryTests/testDisplayMemoryAndCancellationThirtyTrials -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/U2-Memory-Sampler-20261105-142300.xcresult CODE_SIGN_IDENTITY=- test
```

- require_escalated実行、確定1成功/0失敗/0skip、exit0。test6.678秒/testing7.353秒。実行ログ時刻08:35JST（bundleの任意名を時刻証拠とはしない）。baseline実5.005715375秒/418sample、measurement138sample、全phaseの最大間隔0.014917958s。baselineMedian9,192,192B、samplePeak15,647,488B、delta6,455,296B、OSpeak9,569,024→15,647,488B、directPeak4,194,304B。
- 表示30回loadMax0.00208325s、取消受理max0.000173125s/論理終端max0.000431292s。未応答取消30回は受理max0.000077208s/論理終端max0.000350583s。合成512px/本人MacのCoreプロセスでの限定値で、実Photos・製品UI全体・CIの観測成立とは別。CI修正後の実測は未確認。

### Native共通前提の段階診断

- CIで失敗した5件はWindow不在ではなく、4件が共通helperの4枚選択前提、1件がcompactアルバム矢印の写真追随。既知旧CI失敗と同原因とは断定しない。
- compactWithFourSelectedにTab/Right後の論理FocusState、各Space後の実選択数と写真slot、compact復帰後のphoto4焦点を検査する段階観測を追加。元のキー順・4枚条件・保存/逆Tabのアサーションは保持。compactアルバム矢印にも切替前後の焦点/段階出力を追加した。
- DEBUGの--ui-test-fixture限定で、SwiftUI TextのAX値へ固定分類（focus、アルバム行番号、選択数、画像ready数、compact）だけを表示する。本文/写真ID/パスは出さない。nativeAtViewUpdateはそのview更新時のfirstResponder class参考値であり、原子的な現在focus判定には使わない。診断のためにfocusを変更しない。
- 初めに追加したNSTextField診断overrideはSDKの基底宣言に一致せず、`.build/U2-Native-Selection-Diagnostic-20261105-083900.xcresult` と `...-084000.xcresult` はコンパイルでexit65/機能未実行。これらを機能Redとはしない。推測したnative overrideを撤去して既存SwiftUI Textへ縮小後、代表1件のみを実行した。

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/NativeInputTests/testCompactPhotoTabCanActivateEnabledConfirm -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/U2-Native-Selection-Diagnostic-20261105-084200.xcresult CODE_SIGN_IDENTITY=- test
```

- 確定1成功/0失敗/0skip、exit0、test26.912秒/testing52.374秒。album-open=albums/selected0/ready12、Tab=photo1、Space=selected1、各Right=photo2/3/4、各Space=selected2/3/4、slot2〜4の番号一致、compact後photo4/selected4を実観測。元のTab→Spaceによる保存と最後の所有root回収も成功。
- 本番のPicker focus動作は変更していない。条件待ちを含む診断強化後のローカル1回では非再現であり、元CIの原因や5件の解消を証明しない。rootの「非再現なら診断改善と未確認を返す」指示により、残4件は追加実行せずCIで確認する。全体/詳細性能UI3件/他UIは未実行。
- 変更はArticlePreviewRetryTests/ArticleDraftTestDoubles/NativeInputTests/PickerContentおよび本TDD。すべて既存manifest43パス内で新規pathなし、4ソースdiff-checkはexit0。root所有のrunner/CI/計画/最終記録は編集していない。検証後に全writeを凍結し、CI再確認へ返却する。

- 最終静的確認でDEBUG診断TextがVStackの高さを占有していたため、同じAX値を既存領域のoverlayへ移しallowsHitTesting(false)を付けた。レイアウト必要寸法/クリック領域/Tab停止点を増やさない構造とする。上記のローカル代表1件成功はこの表示位置移動前の候補であり、overlay後の候補でUIを再実行したとは扱わない。rootの指示に従い追加試験なしで最終候補のCI確認へ渡す。
- 段階確認helperも現在値のfast pathを追加。焦点のAX値が既に一致すれば即return、選択数が既に存在すればwaitForExistenceを呼ばず通す。不成立時のみ従来の同じ3秒条件待ちを使い、固定sleep/無条件poll遅延を増やさない。この検査方式の整理後も追加UIは起動せず、最終候補の確認はCIへ渡す。
# CI早期停止と区分の改訂（root、Retry38d447b5）

- 追加した短いrunner契約4件を旧実装へ実行し、4失敗/0成功（0.978秒）を確認。Core失敗後もUIが動く、--coreがない、通常区分で全製品coverageを判定しない、CI依存時のcoverage不足を示した。
- native-test-runnerへ--coreとCore先行停止を追加。無引数/通常はCoreに失敗するとsmoke/UIへ進まない。性能専用はU2 Core性能2件を先に実行する。CIだけは同一commitのnative-core成功依存を明示し重複した先行だけを省き、通常主bundleからCore機能を除かない。
- 全体/通常の主bundleでは先行済みCore性能2件を重複しない。性能ケースを除いたことを製品ソースの除外へ転用せず、既存checkerで全製品加重80%を判定。UI性能3件は別の必須jobで成功が必要。
- 14件の隔離契約が成功（2.558秒/exit0）。Core失敗・Core0件でUI未起動、Core専用でUIなし、未知引数拒否、smoke停止、通常全source coverage、性能分離、非CI環境で依存フラグだけ設定しても先行を省けないことを確認。実Xcodeや本人データへは接続していない。
- 新workflowはnative-core成功後にnative/native-performanceを実行するneedsを持つ。単一native-allの30分実行は廃止し、旧U1専用baselineは保持。Ruby標準YAMLで構文/依存関係を読取確認した。新CI成功の証拠はまだない。
## 性能合否を本人Macへ分離・通常loadingの軽量化（2026-11-05）

- 本人ed903fa6と最新正式briefに従う。問題根拠はCI commit2bd2a1aでの約100msのsample間隔失敗（Core375成功/1失敗、UI両job未起動、約1分54秒停止）。これはCIで性能合否を判定していた実行設計の訂正であり、本人Macの5秒baseline/50ms/256MiB/512MiB/期限/取消の基準は緩めない。専用Thread samplerやOS/hardware対策は今回変更しない。
- testNativeInputMeasurementUsesCurrentFieldEditorを通常から既存ArticleDraftPerformanceUITestsへメソッド本文そのまま移動。field editor実値、保存/入力描画0.5秒、timeout検知、performance fixture条件は保持した。実ファイルの件数は通常ArticleDraftUITests23件、性能ArticleDraftPerformanceUITests4件。
- 通常testEntryAndListLoadingCanCompleteはread-delay fixtureを用いる。既存の読込arm/release hooksだけを同fixtureにも注入し、100記事/1000操作や長文の一括準備を行わない。実保存した1記事について入口/一覧各1回のloading表示、明示応答解放、一覧取消、編集復帰、同じ非空ASCII本文/タイトル保持を検査する。awaitMetricと実測timeout/時間性能の判定はこの通常ケースから外し、機能待機の5秒timeoutは維持する。実測loading30回の元条件/閾値はMac性能クラスに保持。
- CIの機能とMac性能の選択/停止/coverageはroot所有のrunner/workflowで管理する。この変更で架空の計測成功を返したり、製品ソースのcoverage除外を追加していない。新規source pathはなくmanifest43パス内。
- sourceを凍結し、許可された通常loading1件だけをrequire_escalatedでbuild/testした。

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/ArticleDraftUITests/testEntryAndListLoadingCanComplete -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/U2-Lightweight-Loading-20261105-085500.xcresult CODE_SIGN_IDENTITY=- test
```

- App/Core/全試験targetのビルドは成功。09:03:54JSTにrunner起動後、09:04:54にXCTFuture Code1000「Timed out while enabling automation mode.」で初期化失敗。exit65、testing71.572秒。summaryはpassed0/failed1/total1/skip0だが、その1件はrunner初期化エラーで、**指定loadingの機能ケースは未実行**。この失敗を機能Redや性能未達とは扱わない。
- 即rootへ報告し、再試験・長時間性能・全体・他UI・CI・OS/TCC/承認/本人アプリ操作をせず停止。本人Macの新しい性能4件suiteも今回は実行していない。先行の機能/実測成功を今回の新候補の成功へ流用しない。
- 変更4ソース: ArticleDraftUITests/ArticleDraftPerformanceUITests/DebugFixture/ArticleView。diff-checkはexit0。TDD追記後、全writeを凍結してrootへ返却した。
### 本人のautomation承認後・軽量loading1件の再実行

- 本人21a596a1の承認回答後、同一ソースのtestEntryAndListLoadingCanCompleteだけをrequire_escalatedで一度再実行した。bundleは `.build/U2-Lightweight-Loading-Approved-20261105-091000.xcresult`。性能/他UI/全体は実行しない。
- automation初期化は成功し、実ケース1件が開始。導入文のreplace（ArticleDraftUITestCase.swift:33のelement.click）で `Unable to find hit point for ScrollView, {{276.0, 1017.5}, {733.0, 140.0}}` が発生した。ケースはbodyのexistsだけを確認して直接クリックしており、本文入力・保存・読込armの前で停止。viewport外かどうかはこの失敗だけで断定しないが、テストの入力到達準備を確認する必要が残る。
- 確定summaryは1実行/0成功/1失敗/0skip、exit65。UI9.992秒/testing20.866秒、QoS priority inversion warning1件。teardownの所有root回収は成功した。前回のrunner初期化失敗と異なる実ケースの操作失敗である。
- 即rootへ報告し、反復・source変更・OS/認証操作をせず停止。この追記以外のwriteなし。軽量loadingの機能Greenや新しいMac性能/CI成功とは扱わず、source/記録の凍結を維持して返却する。
### 軽量loadingの入力到達修正とGreen

- 本人45362ce6により、導入文click不可への最小修正を実施。先行の実ケース失敗は上節の `U2-Lightweight-Loading-Approved-20261105-091000.xcresult` として保持し、同じRedだけは繰り返さない。
- 原因となるテスト前提は、existsだけではスクロール外のTextEditorも対象になるのに、導入文を直接replaceしていたこと。狭幅では写真がフォームより上に積まれるため、常に本文がviewport内にあるとは限らない。既存field helperを本文TextViewにも対応させ、同じ外側gutterスクロール、入力欄全体がviewport上下3pt内、isHittableの検査を導入文にも適用した。固定sleepやクリック座標の強制、要件/待機timeoutの緩和はしない。
- 軽量caseはfield("article-introduction",app)を通してから入力し、保存前のASCII本文実値assertionも追加。製品source/fixture/他試験の期待は変更しない。既存helperのタイトル/日付/自由情報の対象分類は保持。

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/ArticleDraftUITests/testEntryAndListLoadingCanComplete -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/U2-Lightweight-Loading-Reveal-20261105-091200.xcresult CODE_SIGN_IDENTITY=- test
```

- require_escalatedの限定1件のみ。確定summaryは1実行/1成功/0失敗/0skip、exit0。UI25.109秒/testing36.087秒。入力欄の表示/操作可能性、保存前本文実値、実保存、入口/一覧各1回のloading表示→response解放→一覧取消/編集復帰、同じ本文/タイトル保持、最後の所有root回収まで通過した。QoS priority inversion warningは1件。
- 変更はArticleDraftUITestsとArticleDraftUITestCase、および本TDDのみ。既存manifest43パス内、新規pathなし、2ソースdiff-checkはexit0。長い全体/性能/他UI/CIは実行していない。ソースと記録を凍結し、rootの本人Mac性能・CI機能確認へ返却する。
## 本人Mac専用性能の最終候補・一度の実行（2026-11-05）

- ソース凍結のまま `bash scripts/verify-native.sh --performance` をrequire_escalatedで一度実行。選択はU1実測3件+U2実測2件→smoke2方式→UI性能4件。Core後のsmokeで失敗し、runnerが非0終了してUI性能を起動しなかった。再試験/全体/ソース修正なし。
- 環境: macOS27.2 build26B123、Xcode27.2 build27B52、MacBook Pro/Mac15,3/Apple M3（8core=performance4+efficiency4）/16GB。開始前と終了後のpmsetはともにAC Power/AC attached/79%/not charging。全期間の電源状態監視ではなく2時点の観測である。system_profilerはActivation Lock checkのtimeout警告を出したが機種情報を返し、同コマンドの終了後に試験を開始した。OS設定/電源設定/本人アプリは変更していない。

### Core性能5件: 成功

- `.build/Native-core-20261105-091508-6e699b0c5e61487dbe663ccdb42e3ba7.xcresult`
- 確定summary5実行/5成功/0失敗/0skip。U1の3件19.729秒、U2の2件24.134秒、xcodebuild testing elapsed45.003秒。Core段階はexit0、選択した5methodの実行をrunnerも検証した。runtime warningはsummaryにない。
- U1保存30回p95=0.014366292s。cold-store再開10回は[0.000842625,0.00043575,0.000376583,0.000358375,0.000418083,0.000366625,0.000360375,0.000367542,0.00035375,0.000357208]s。別プロセスのcold起動やOSディスクキャッシュcoldはこの値ではない。
- U1実画像変換30回max=0.166400458s、baseline中央値11,485,952B、samplePeak103,908,624B、delta92,422,672B、OS lifetime peakは107,529,008B→107,529,008B。OSピークは試験以前で、当該変換への短いピークの帰属は未確認という元の出力を維持する。
- U2は100記事/対象1000操作/タイトル200文字/6本文各10000文字。保存30回p95=0.015248917s/max=0.015298958s、Core再開30回p95=0.004813542s/max=0.004975958s、純粋投影100回p95=0.009454041s/max=0.009721041s。別集計cold-store/session10回はp95/max=0.00412025sで、実アプリcold起動やOSキャッシュflushは未計測。
- U2表示メモリ30回: baseline実5.000899084s/418sample、中央値41,632,512B、本処理139sample、samplePeak29,590,272B、delta0、directPeak4,194,304B。要求周期10msの専用Threadで全観測最大間隔0.012970666s（baseline最大も同値）、元50ms条件を満たした。OS lifetime peakは45,794,048B→45,794,048Bで当該表示への厳密な帰属は未確認。sample増分0を割当ゼロとは解釈しない。
- U2合成512px表示30回はloadMax0.001603s、取消受理max0.000417167s/論理終端max0.000484917s。未応答表示の取消30回は受理max0.000054625s/論理終端max0.000336709s。実Photosの取得時間/製品UI全体のメモリとは別のCoreプロセス試験である。

### smoke: 記事成功・Picker入口失敗、以降停止

- `.build/Smoke-20261105-091556-f892a664723b4bad84ebee8ddeb90e41.xcresult`
- 確定summary2実行/1成功/1失敗/0skip、UI25.035秒、xcodebuild testing elapsed34.912秒。記事方式は8.782秒で成功。Picker方式は16.253秒でFixtureSmokeUITests.swift:17の「テスト親A」入口待機に失敗した。全コマンドの最終exit65。
- 最初の短いログからWindow不在とrootへ伝えたが、確定summaryを読んで訂正済み。実際はWindowが存在しWindow確認は通過、幅765ptのcompact表示で領域が「写真」、photo-grid0枚、期待したフォルダ行がなかった。AXにはApplication/WindowのDisabledもあるが、この値だけで認証/製品/環境の原因を断定しない。無関係なメニューバー等の全文は記録へ複製しない。
- UI性能4件は**未実行**で対応bundleも作成していない。cold10起動/loading30回/長文描画各30回/field-editor実測を今回成功したとは扱わない。Core5件の成功や過去UI性能値で補完しない。
- 失敗を直ちにrootへ報告し、OS/認証操作・再実行・ソース変更をせず停止。rootのリモートCI機能確認とは別の本人Macでの部分結果であり、性能全体合格/全体coverage/CI成功を意味しない。このTDD追記後に全writeを再凍結した。
## Picker smokeの表示領域前提修正・残るMac UI性能のみの確認

- 本人9f7ab16dに従い、成功済みCore性能5件を再実行せず、Pickerの起動確認が正当にフォルダ入口へ到達できるようテスト前提だけを修正した。先行失敗の狭幅765pt/写真領域ではフォルダ行が表示されない。既存Native操作と同じregion-pickerの「フォルダ」を、実enabled/hittable確認後に選ぶ。広幅のフォルダ入口または狭幅switcherが準備済みならすぐ進み、未準備時だけ同じ10秒条件待ち。Window/フォルダ入口のenabled/hittableという元の期待を維持した。製品source/保存領域/OS設定には変更なし。
- sourceを凍結して次をrequire_escalatedで一度実行。選択はsmoke2件→UI性能4件だけで、Coreの実行コマンドは発行されていない。

```bash
bash scripts/verify-native.sh ArticleDraftPerformanceUITests
```

- smoke bundle: `.build/Smoke-20261105-092133-91779c7589e54b46bae798ee745f0a6c.xcresult`。確定2実行/2成功/0失敗/0skip、UI17.027秒/testing17.822秒。記事9.076秒、Picker7.951秒で、双方の最後の所有root回収も成功した。runtime warningはsummaryにない。
- Mac UI性能bundle: `.build/Native-selected-20261105-092155-1201c1732b2241db8136be0f5bb8aa36.xcresult`。確定4実行/4成功/0失敗/0skip、UI712.291秒/testing723.052秒、最終exit0。各caseの所有root回収も成功。QoS priority inversion warningは4件ある。実行後のpmsetはAC Power/AC attached/79%/not chargingで、先行記録と同じ本人Mac環境（Mac15,3/M3/16GB/macOS27.2/Xcode27.2）。全期間の電源監視ではない。

| 実測対象 | 件数 | p95秒 | 最大秒 |
|---|---:|---:|---:|
| App.init→入力可能/firstResponder（cold） | 異なる10プロセス | 1.216727792 | 1.216727792 |
| 入口loading描画 | 30 | 0.043553209 | 0.044339375 |
| 一覧loading描画 | 30 | 0.059137 | 0.104686542 |
| 保存中文字描画 | 31 | 0.019604792 | 0.0216415 |
| 無応答画像/保存中の実入力描画 | 30試行/60sample | 0.01142475 | 0.014688708 |
| preview描画 | 30 | 0.172049416 | 0.192501166 |
| editor入力可能 | 30 | 0.147706125 | 0.152690583 |
| 下書きreopen入力可能 | 30 | 0.136201792 | 0.147389792 |
| 実field-editor追加診断 | 2sample | 別p95なし | 0.010409917 |

- cold case58.170秒、loading case355.958秒、長文case271.566秒、field-editor case26.597秒。元の各not-ready timeout=0アサーションをすべて通過した。保存/入力/loadingは元max0.5秒、preview/editorは元p95条件、再開は元2秒条件を維持して成功。
- loading/長文/再開は100記事/対象初期1000操作、タイトル200文字/6本文各10000文字の準備条件を維持。描画計測はhandler受付からnative draw、入力可能は実TextField/field editorのwindow所属・enabled/editable・firstResponder・UTF8実値を照合した元方式のまま。coldはApp.init以降であり、起動前OS bootstrap/OSディスクcache coldは測定していない。実Photos性能や製品UIメモリ測定へ拡張解釈しない。
- 先行のCore性能5件は `Native-core-20261105-091508-6e699b0c5e61487dbe663ccdb42e3ba7.xcresult` の成功証拠を保持。今回の差分はsmokeテストの表示前提のみでapp/計測sourceは不変。Coreを重複実行した値として合算せず、先行5件と今回UI4件が別bundleで確認できたことを記録する。OS lifetime peak帰属の既存未確認も消さない。
- traceabilityは許可されたNFR3.20/21/22のtargetだけを実担当ArticleDraftPerformanceUITests.swiftへ修正し、今回のMac実測成功を根拠にOKを維持した。NFR3.20は入口/一覧/保存/入力の各最大値、NFR3.21はpreview/editor各30回p95、NFR3.22はUI再開30回p95と先行Core保存/再開30回が現在証拠。NFR5.20/21のGAP、plan15–18の未完は変更せず、CI/全体機能/全製品80%の成功をこの性能結果から推定しない。
- 今回のsource変更はFixtureSmokeUITests.swiftだけ（既存manifest43内）。TDDと指定3IDの対応表を更新後、全writeを凍結しrootの最終CI/独立レビューへ返却した。追加ローカル機能・全体・再試験は実行しない。
## Native Tab遷移・CIだけの失敗を切り分ける限定診断

- 本人8f182267の承認に基づき、CI41939982311のNative8失敗と現行focus経路を静的確認。wide側の4例は写真12枚readyでもTab後focus=albums/selected0、compactアルバム復元はfocus=none/ready0だった。これだけではListのTab handlerが呼ばれていないのか、restoreConnectedFocusのnil化→Task.yield後guardで棄却されたのかを区別できない。根拠なくOS環境や製品の一方を原因と決めない。
- 製品の焦点遷移条件/キー順/timeoutは変えず、--ui-test-fixtureかつDEBUGに限り、album Tab/backtab受信、接続要求番号、FocusState観測、適用/棄却理由（世代・領域・選択/記事変更等）の最大12件履歴を既存overlayのAX値へ追加。写真は表示位置番号だけで、私的写真ID/本文/パスは含めない。既存のwide代表にもTab直後のphoto1焦点assertionを追加し、Space選択と逆Tab往復の元assertionは保持。余分なTabや待機延長による回避はしていない。
- @Stateの診断履歴は再描画/スケジューリングへ観測影響を与えうる。この版の一度の成功だけを既存CI8失敗の根本解消とはしない。nativeAtViewUpdateの参考値も原子的な現在firstResponderとして厳密判定しない。

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/NativeInputTests/testSingleTabFromAlbumOperatesPhotoAndShiftTabReturns -only-testing:HitotsuzuriUITests/NativeInputTests/testAlbumArrowsInCompactAfterMouseSelectionFollowPhotos -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/U2-Input-Focus-Trace-20261105-094600.xcresult CODE_SIGN_IDENTITY=- test
```

- require_escalatedで代表2件だけを一度実行。確定summary2実行/2成功/0失敗/0skip、exit0、testing33.852秒、runtime warningなし。compact代表19.168秒、wide代表13.860秒。所有root回収も双方成功。
- ローカルcompactではconnect-albums#3がsupersededで棄却され、最新#4がapplied-albumsになりfocus=albumsへ復帰した。DownでalbumRow3、Upで2、その後1に戻り、元の写真枚数4→8→12追随が成功。ready0は写真領域を隠した当時の状態でもあり、これだけで接続失敗の原因とはしない。
- ローカルwideでは `album-key-tab→connect-photo:1#3 requested→observed-none→connect#3 applied-photo:1→observed-photo:1` を観測し、元のSpace選択/ShiftTab往復を通過。CIと同じ失敗は今回の本人Macでは非再現だった。
- 原因確定前の推測修正を避け、rootが用意する `bash scripts/verify-native.sh --input-focus` のsmoke2→同じ代表2件だけのCIへ診断を渡す。CIでhandler未受信なのかguard棄却なのかを判別できてから必要最小の修正と残8ケースの検証を進める。今回の限定成功を8件全体の成功や加重coverage成功へ置き換えない。
- 成功済みCore/UI性能、長い全体suite、残6ケースは実行していない。今回sourceはPickerContent/NativeInputTestsの2既存パスのみでmanifest43内、新規pathなし。2ソースdiff-checkはexit0。TDD確定後に全writeを凍結してrootへ返却した。
### 限定CIで確認したマウス選択直後のfocus不足（先行Red）

- 限定CI41943778942/job126970796900はsmoke2成功、代表2失敗。compactのmouse-album-CはalbumRow2/ready8だがfocus=none、view更新時firstResponderはFolderOutlineView、traceに接続要求なし。resize後もfocusなし。wideのmouse選択直後もfocus=none/ready12/FolderOutlineViewで、初回Tab後にobserved-albumsだけが追加され、album-key-tab/connectの履歴はなかった。
- この証拠から初回Tabはアルバムから写真への遷移処理で棄却されたのではなく、フォルダからアルバムへ初めて入っていたと分かる。マウス選択はListのBindingから記事選択を変える一方、当該Listへのfocus/最終操作領域の更新をプラットフォームの暗黙の動作に任せていた。Macでの非再現をCIの成功とせず、この実失敗を先行Redとして最小修正する。
### マウスのアルバム選択とfocus所有を揃える最小修正・ローカルGreen

- List行の全幅に同時Tap gestureを付け、明示的なマウス選択の責務をselectAlbumFromMouseへ集約した。選択と同じ入力でlastInteractionRegion=albums、記憶するアルバム位置、focus=albumsを設定し、旧保留focusの世代を無効化して既存WorkflowへselectAlbumを返す。キーボードによるList selection Bindingは維持。同じアルバムへの重複選択は既存Workflowのguardが早期returnする。
- focusを変更する前にisEditingFrozen/現在のアルバム存在を検査し、List自体はauthorized時だけ描画される。実選択の権限/選択変更/世代処理は既存Workflowへ返し、画像応答からのfocus移動は追加しない。空アルバムへ写真focusを強制せず、保存中等の無効操作も既存guardを通す。追加Tab・timeout延長・4枚選択の弱化はしない。
- 代表2件にクリック直後のalbums焦点確認を追加し、次の1Tabで写真へ入ることとcompact復帰を、同じ元の操作/期待で検証した。

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriUITests/NativeInputTests/testSingleTabFromAlbumOperatesPhotoAndShiftTabReturns -only-testing:HitotsuzuriUITests/NativeInputTests/testAlbumArrowsInCompactAfterMouseSelectionFollowPhotos -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/U2-Input-Focus-Mouse-Green-20261105-095500.xcresult CODE_SIGN_IDENTITY=- test
```

- require_escalatedで同じ代表2件のみ。確定summary2実行/2成功/0失敗/0skip、exit0、testing32.706秒。compact18.208秒、wide13.732秒、summaryのruntime warningなし。所有root回収も双方成功。
- 両例でクリック直後にmouse-album-focus→observed-albumsを確認。wideは1Tabでalbum-key-tab→photo1接続/適用となり、Space選択/逆Tab往復も成功。compactも最新のalbums接続要求が適用され、元の写真4→8→12枚追随が成功した。
- ローカルは先行版でも非再現だったため、根本解消の最終判断はCIの再現環境で行う。rootは代表2件を重複して別実行せず、それらを含む失敗8件だけの `--input-regression` / [input-regression]限定CIへ進める。現時点で修正後CI8件は未確認。成功済みCore/UI性能と長い全体suiteは再実行していない。
- 変更sourceはPickerContent/NativeInputTestsのみで既存manifest43内、新規pathなし。2ソースdiff-checkはexit0。TDD追記後に全writeを凍結してrootへ返却し、CI/git/最終記録はrootが担当する。
