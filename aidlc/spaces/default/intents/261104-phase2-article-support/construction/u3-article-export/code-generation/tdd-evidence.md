# U3 TDD実行記録

## Runner readiness
- `python3 scripts/test-native-runner.py` : 既存21件＋U3選択/性能分離4件、25件成功。先行Redではラッパー未存在により成功期待3件が失敗した。これはrunner準備であり機能Redではない。
- `bash scripts/verify-article-export.sh ArticleExportContractTests` : 最初はfixtureの引数を修正。次にsandboxによるtestmanagerd接続拒否で未実行。同じコマンドを権限付き実行し、3件成功・0skipを確認。
- 成功bundle: `.build/Draft-selected-20261105-131614-cc437541ac73481f9f17f45c26f4587d.xcresult`。
- 基準は既存2337dd6のCI41945323042およびMac全機能426件＋smoke2件、4207/4673=90.03%。U3機能の成功とは扱わず、無変更の基準全体は再実行していない。

## Model layer
- Red: `bash scripts/verify-article-export.sh ArticleExportModelTests`、8件実行、7ケースの8アサーション失敗。最小宣言はコンパイル済みで、版・不足/順序・指紋・設定・相対参照・回復版が拒否されない実アサーションを確認。
- Red bundle: `.build/Draft-selected-20261105-131816-f32b34aef1114112958004fd1c66be11.xcresult`。
- Green: 同コマンド8件成功、`.build/Draft-selected-20261105-131906-3e3fa81c41b146a2963a75cadbce26fc.xcresult`。
- Refactor: 固定相対パスをArticleExportLayoutへ集約し、モデル8＋契約3件=11件成功、`.build/Draft-selected-20261105-131930-2787879c146545efa9e7a3605767a6f0.xcresult`。

## Journal / Writer
- Red: 保存境界20件を実行。試験用一時パスのmacOS別名がnofollow境界に拒否された初回2runはWriter機能Redとせず、既存と同じプロジェクト内UUID rootに修正した。
- Red bundle: `.build/Draft-selected-20261105-132329-8fe3ca5b54a045fdac71ef6cd202a021.xcresult`。20件実行、記録不在/危険な成功/ファイル未生成を示す39失敗を確認。未実装hookに由来するファイル不在も含む。
- Green: Journal8＋Writer12件=20件成功、`.build/Draft-selected-20261105-132708-9cf0ab6a58b34abd9fffa62222f9c55d.xcresult`。Swift6の隔離境界コンパイル修正は機能Redと数えない。
- Refactor: Journalの排他I/Oを同期helperに分離、画像ディレクトリの実体識別を保持、bytes読取の重複を整理。公開応答不明の再照合・片付け失敗2件を追加。モデル込み30件成功、`.build/Draft-selected-20261105-132754-986cdc3940c6439c9699ed648af66279.xcresult`。

## Delivery / Session / Integration
- Red: コンパイル済みの最小宣言に対し28件実行、25ケースの期待動作/分類/記録/制御保護が失敗。`.build/Draft-selected-20261105-133230-3d7cc149cc4b4a3ebd4d549d93d8e6ea.xcresult`。
- Green: 取消試験の待機を固定yield回数から実際の画像要求待機の観測へ直した後、28件全成功。`.build/Draft-selected-20261105-133440-5254d3e322664c3db5dd4589e6f031d1.xcresult`。
- Refactor: seal済み回復記録の保存前に内部receiptを消さない順序へ整理。確定許可と取消の境界、遅い進捗と取消表示、旧画面読込からの差替え保護を整理。途中の`--core`で既存U3 Core61件は全成功したが、この時点では次の未作成OSActionクラスも要求するため、runnerの未実行チェックが非0を返した。全Core完成と扱わず、後述の69件成功を最新の限定結果とする。

## OS boundary
- Red: 専用pasteboard・注入Finder・登録grantの8件を実行、7ケース失敗。`.build/Draft-selected-20261105-133717-77eb9062d8a04373948ff4b7b0ab33fe.xcresult`。
- Green: 本文コピー・固定完了本文・クリップボード失敗・Finder不在/失敗・未登録grant・scope解放を実装。macOSはplain stringを旧`NSStringPboardType`でも公開するため、両方の文字列型だけを認める検査に修正。general pasteboardは試験で読み書きしていない。
- Refactor: MainActor進捗bridge、成功/失敗時grantの一回解放、OSファイル確認をMainActorから分離。U3全Core69件成功、`.build/Draft-core-20261105-133932-fa545b53fa8f42879d9e01fa174bd1b7.xcresult`。全製品coverageはこの限定runで判定しない。

## Frontend preflight — 環境障害で停止
- `bash scripts/verify-article-export.sh --smoke` はexit65。UI runnerの初期化で `Timed out while enabling automation mode`、約71秒。
- bundle: `.build/Smoke-20261105-133957-158bf6cab27b46e181874cd97e25f62a.xcresult`。
- 起動smokeが成功していないためFrontend機能Redに数えず、8件の先行UI試験ファイル作成までで停止。ArticleExportUITestsは未実行・追加後のコンパイルも未確認。
- Frontend実装、性能2件、全機能/全製品80%検証、CI、本人の実写真/Sandbox/note、独立レビューは未完了。

## Frontend retry / Red
- 本人のRetry後、同じ`bash scripts/verify-article-export.sh --smoke`が2件成功・0skip。設定変更なし。`.build/Smoke-20261105-134755-f59a46707c7c4fc3a04e1cc6d4abc79a.xcresult`。
- Red: `bash scripts/verify-article-export.sh ArticleExportUITests`は前提smoke2件成功後、未配線の出力操作を期待する8件の実アサーションが失敗。`.build/Draft-selected-20261105-134855-4b4b8d79d4194db1a80f64a8f24f746f.xcresult`。コンパイル/起動障害ではない。
- Green: 画面配線後、XCTestのisHittableだけではviewport外クリックが起きたため、既存フォームと同じ実座標内の可視検査に修正。`.build/Draft-selected-20261105-135832-0fdce4c9fba04c3295ac2e50520c436c.xcresult`で5件成功、残る3件はSwiftUIの選択可能Textをlabelだけから読む検査が失敗した。
- 表示のlabel/valueを両方検査するよう揃え、失敗した3メソッドだけを限定実行。3件成功・0skip、`.build/U3-export-ui-messages-1793854911081.xcresult`。固定完了本文と後続の未保存入力は異なるASCII値を実入力し、入力値の一致も確認。Unicode/改行はCoreと既存UI回帰を維持。

## Final specification checks
- 親パスそのものの公開後差替え、およびmanifest日時/画像設定の外部表現を先行試験へ追加。両方の実アサーションが失敗、`.build/Draft-selected-20261105-140421-39f2aeaa1ddc430985b86fc2b01ddaf6.xcresult`。
- 公開結果の親実体を再照合し、manifestはISO8601日時・sRGB/JPEG/非拡大を明示。新規2件を含めU3 Core71件成功、`.build/Draft-core-20261105-140533-c96ac213b0fd48a49b2b03b952bfe72f.xcresult`。
- Frontend Refactor: 薄いArticleExportViewとcoordinatorを分離し、他の記事へ切替時の完了操作、共有予算、検証出力との取消表示を整理。同じUI8件を一式で実行し8件成功・0skip（157秒）、`.build/Draft-selected-20261105-140651-fba2c08f22e5414699cef52aa8c5586c.xcresult`。

## U3 performance
- `bash scripts/verify-article-export.sh --performance`で新規2メソッドのみを実行し、2件成功・0skip。既存U1/U2性能は反復していない。
- bundle: `.build/Draft-core-20261105-141100-42f2c99657db4a6dbbe4663d5b59f48d.xcresult`。
- 正常四枚30試行p95=1.001353625秒、最大1.051631083秒。4096×3072の合成JPEG4枚、各本文10000文字を実出力。
- 実メモリbaseline436標本（5秒以上）、全3529標本、最大実観測間隔0.037065709秒。baseline中央値11338496 bytes、観測peak163939888 bytes、増分152601392 bytes、直接画像peak112197632 bytes。512MiB/256MiBおよび50ms条件を満たした。
- 取消30試行：受付最大0.000182875秒、画像論理終端最大0.000108875秒、片付けp95=0.154551125秒・最大0.157509917秒。論理終端と変換収束/片付けを分けて実測。
- 詳細はperformance-evidence.md。実写真・Sandbox・noteの本人成功を意味しない。

## Candidate regression verification
- 初回の正式全機能前提Coreで、入力不変試験が同じ831bytesのJSONキー順の相違により失敗した。製品による入力変更ではなく試験の非決定性だったため、試験のJSONEncoderをsortedKeysにし、入力全体の一致という期待を保った。Integration13件を限定再実行し成功：`.build/Draft-selected-20261105-141531-c5a02e53460b477298d02a33fdabcc82.xcresult`。
- 完了コンテキストを直近一件に限定した整理後もOSAction8件を限定再実行して成功。
- 限定診断へ既存性能が混じらない契約を先に失敗させ、runnerを修正。`python3 scripts/test-native-runner.py`は26件成功。明示的U3性能runは維持し、成功済み性能を再実行していない。
- 正式`bash scripts/verify-native.sh --functional`再実行の前提Core442件成功・skip0：`.build/Native-core-20261105-141659-37d18b3ffb5a444e8a344c846c15fc04.xcresult`。主bundleの結果は完了後に追記する。
- 主bundle `.build/Native-functional-20261105-141744-124dbfceebee4de0a15d340729e3a3fd.xcresult` は505件中504成功・1失敗・skip0、exit65。唯一の失敗は既存ArticleDraftUITests.testTabAndShiftTabReachMetadataAndPreviewWithoutSystemSettingの日本語「場所」が「境䘤」になった値不一致。起動障害ではなく実アサーション。U3 UI8件、NativeInput26件は全成功。全製品coverage検査は未到達。
- 失敗一件を無変更で直接限定診断：`xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination platform=macOS -only-testing:HitotsuzuriUITests/ArticleDraftUITests/testTabAndShiftTabReachMetadataAndPreviewWithoutSystemSetting -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/U3-existing-keyboard-diagnostic-20261105-1436.xcresult CODE_SIGN_IDENTITY=- test`。1件成功・exit0。日本語/Unicodeの期待は維持し、general clipboardや入力設定を変更していない。metadata入力順は変更されておらず、U3出力のbusy/terminal焦点処理はこのケースでは起動しない。間欠的なXCTest入力の可能性があるが、正式全機能失敗は取り消さず、次のCIで全機能とcoverageを確認する。

## CI coverage boundary repair
- d755f9dのCI run41975756151：Core442件/全機能505件成功・skip0。coverage checkerはArticleExportPorts.swift未計測でexit1。主bundle `.build/Native-functional-20261105-054720-cb5382d9023849f38b1bc3d7fdf72f3e.xcresult`。機能は成功だがCI全体/80%達成とは記録しない。
- ファイルはSwiftFileListとobjectに存在し、target漏れではない。宣言だけの当該objectにcoverage mapping/counter sectionがないことを確認した。実際の失敗を先に確認してから、親の了承により全宣言をDelivery/OSActionsの所有境界へそのまま移し、U3作成のPortsファイルだけを削除した。実行ロジック・試験期待・checker・全製品80%条件は変更していない。
- 修正後`bash scripts/verify-article-export.sh --core`は71件成功・skip0、exit0：`.build/Draft-core-20261105-150756-04413a016c8c40e093c21fa194a1e55b.xcresult`。実xccovのCore.framework計測一覧と全Core.swiftを比較し37/37・missing=[]。Delivery125/OSActions85の実行可能行数は移動前と不変。限定runの率を全製品80%へ転用していない。全体機能/性能を反復せず、再CIへ渡す。

## Fixed-copy DEBUG observation repair
- cae0340のCI41978578213：Core442/smoke2成功。主bundle `.build/Native-functional-20261105-061240-5b6c4c3ae02543e1b9c3673953844ba2.xcresult` は504/505件成功・skip0。唯一の失敗は固定完了コピー試験の末尾DEBUG StaticTextが5秒以内に存在しないこと。機能全体は失敗でcoverage checker未実行。
- 同メソッドを無変更で一件限定再実行し成功、exit0：`.build/U3-fixed-copy-diagnostic-20261105-a.xcresult`。実コピー不良はこのrunでは再現していない。対象DEBUG値は実copyPlainTextが成功した後だけ設定されるが、観測用Textはスクロール末尾へ条件付き挿入される。これをクリックした既存ボタン自身のDEBUG accessibilityValueに結び付け、画面外の動的Text挿入に依存しない観測契約へ改める。固定本文/後続本文非混入/dirty保持の期待と5秒は維持する。
- Red：新しいボタン値の観測期待だけを先に追加。同じ一件が5秒のNSPredicate期待でtimedOutになり、実アサーション失敗・exit65：`.build/U3-fixed-copy-observation-red.xcresult`。起動/型エラーではない。
- Green1：DEBUG accessibilityValueを既存の実成功後捕捉値へ接続し、末尾Textを削除。同じ一件成功・exit0：`.build/U3-fixed-copy-observation-green1.xcresult`。実copyPlainTextとcoordinatorの成功判定は変更していない。
- 整理確認：同一メソッドだけを`-test-iterations 2`で追加実行、exit0。`.build/U3-fixed-copy-observation-green2-3.xcresult`のRepetition1=28.399秒/Repetition2=27.783秒は両Passed、skip0。Green合計3回で停止し、全体/性能は反復しない。CI504/505の失敗とcoverage未到達は保持する。
- 最新cdcfd12/CI41981707708は再び504/505件・exit65。同一ケース73行目のボタン値NSPredicateがtimedOut。Core442/他UI62件成功。主bundle `.build/Native-functional-20261105-064222-541dfce00a1240f19675cbaba11c3bd9.xcresult`。coverage checker未実行。先のローカルGreen3回でこのCI失敗を補完しない。末尾Textだけという原因仮説は未確定で、入口/guard/OS書込/成功後AXのどこかは現証跡で判別できない。追加ソース変更/再試行を止め、CI-host限定診断の本人判断へ渡す。

## Cleanup ownership regressions
- Red：Writerへ未生成04.jpg/article.md/manifest.json、未記録部分JPEG、変更済み生成画像、seal conflict後の外部article/manifest保護を追加。21件中5ケースで未記録bytesの削除と存在不変条件の実アサーションが失敗。`.build/Draft-selected-20261105-163343-a08dde051c234c0aa25b4f1c036cd5f6.xcresult`、exit65。
- Green：削除前に実在パスをexpectedDigestsへ全て照合し、未記録既知名もcleanupFailureへ。Writer21件成功、`.build/Draft-selected-20261105-163423-cd6a3b1c5e4a4c46b3d44845ff5f752c.xcresult`。

## Restart window regressions
- 生成前、片付け完了後、images除去後、receipt/article除去後の再起動を追加。最初のrunはinvalidReference/missing/corruptDataを捕捉し、続いて期待を明示するXCTFail/未完active不変のアサーションへ揃えて同じ失敗を再確認した。Red：`.build/Draft-selected-20261105-163619-fc668b9657b140d4b288758b942082f8.xcresult`、exit65。前runは`.build/Draft-selected-20261105-163541-fee80e4b4db84d8095b4d28d20264253.xcresult`。
- 同じ親とstage/final不在の確認後だけ削除せず解決する。実体が残る場合は残存パス全ての記録/digestを照合し、途中片付け済みの不在を許容する。外部同名stage/finalと未記録bytesは保護。新しい出力が可能になること、成功結果を返さないことを確認。
- Green/整理：Writer21＋Integration19=40件成功、`.build/Draft-selected-20261105-163727-e8c0675edc3c43a99f6f3870ef6a7ecc.xcresult`。全U3 Core83件成功・skip0、`.build/Draft-core-20261105-164229-2bb60c09538a4e76b621b0a3337af7ae.xcresult`。性能は除外している。

## CI diagnostic preparation
- 本人190d3978のRetry後。workflow準備の先行2契約は未作成workflowで実アサーション失敗。branch/marker/単一case/所有bundle限定/1日保存を実装後、runner全28件成功。隠しbundleデータを欠落させない契約も先行失敗→include-hidden-files指定で成功。checkerと80%条件、通常verify.ymlは未変更。
- UI Red：独立headerのDEBUG段階観測が存在せず実アサーション失敗、`.build/U3-copy-diagnostic-contract-red.xcresult`、exit65。
- UI Green：同じ一件成功・skip0、`.build/U3-copy-diagnostic-contract-green.xcresult`。実copyPlainTextを通過した成功のみ捕捉し、固定本文/後続非混入/dirty保持と5秒を維持した。Button同期印、Task/guard、context/pasteboard分類を独立headerへ公開。失敗メッセージに分類と当該fixtureのボタン状態を含める。
- xcresult活動から、app window screenshot2点/当該window AX2点のkeepAlways添付を確認した。全画面や他アプリを明示撮影する処理はない。CI-hostでの診断結果はまだなく、ローカル成功で既知CI失敗を補完しない。全UI/性能は反復していない。詳細はdiagnostic-evidence.md。

## CI-host mouse activation evidence
- 33d94f3/診断CI41989746567は同一ケースを再現して失敗。実アサーションRedはbutton=0/task=0/idleのまま固定本文が現れないこと。正しい可視中心(98,562)へmouse-down/upが送られたが、押下後にButtonがKeyboard Focusedとなりcontentが+334移動、callback前に画面外となった。clipboard処理は呼ばれておらず、clipboard故障と断定しない。
- explicit focusedField変更でマウスに対してscrollToするソースはない。Appleのfocus interaction仕様を踏まえ、固定コピーボタンだけ通常時activate、独自Tabで当該FocusStateとなる時にedit+activateを許す最小修正とした。実マウスcallback/Task各1回、その後タイトルから22Tab/SpaceでTask2回目を要求する。Spaceへの置換ではなくマウス検証後にキー検証を追加した。固定/後続非混入/dirtyと既存5秒は維持。
- ローカル確認`.build/U3-fixed-copy-focus-interactions.xcresult`はUI runner初期化の`Timed out while enabling automation mode`で71秒後exit65。コンパイルは通ったがケース未実行。機能Green/Redには数えず、追加retryと設定変更を停止した。CI-host等でマウス/無設定キーの実成立は未確認。
- 次のCI-host用にOS/Xcode/AppleKeyboardUIModeを読取だけで記録するstepを追加。既存契約を環境run＋単一ケースrunへ更新して先行アサーション失敗後にYAMLを実装し、runner全28件成功。未設定は明記し、設定変更はしない。UIローカルは再試行せず、CI-host検証へ渡す。
- ce88c242/診断CI41992319852でマウスcallback/Task各1回、実pasteboard成功/固定bytes一致を確認。AppleKeyboardUIMode未設定。一方22Tab/Space後のTask2期待が実アサーションRedで失敗した。本文→日付→メタデータ→上部操作のTab進行は保存動画で確認した。
- eligibility条件をFocusState値自身に依存させず、独立keyboard要求stateを先に更新して、そのonChangeでfocusを要求する構造へ変更。各要求/観測をDEBUG bounded traceに残し、Space前のfocus到達を実キーから検査する。App build/対象build-for-testing成功、runner28件成功。実UI Greenは次のCI-host待ちで、ローカルautomation retryなし。既知のマウス/固定本文/dirty/5秒の期待は維持している。
- 片付け変更に関係するメモリ/取消1ケースだけを候補4a3b71dで再測定し成功・skip0、42.513秒。`.build/U3-cancel-memory-refresh-20261105.xcresult`。増分153322216bytes、直接画像112197632bytes、最大観測間隔0.031540209秒、取消受理最大0.000571459秒、論理終端最大0.000258292秒、cleanup p95 0.168357959秒。全30試行と環境はperformance-evidence.mdへ追記。正常p95専用/全UIは反復していない。
- Green：候補4a3b71dのCI-host診断41994394083は同一ケース1件成功・skip0、62.915秒。AppleKeyboardUIMode未設定で実マウス/22Tab focus/Space/固定/dirtyの全期待が成立した。以前の失敗は履歴として保持する。
- 本人5fc4a689のローカル承認後再試行指示を受け、同じ候補/一件を無変更で実行し39.816秒、1件成功・skip0・exit0を実bundleで確認。`.build/U3-fixed-copy-local-authorized-retry-4a3b71d.xcresult`。AppleKeyboardUIMode読取値0、設定変更なし。正式全機能run41994393925の同SHA再実行結果は別に待つ。

## Final candidate qualification
- 候補4a3b71d1e15795fedcba4e8a808addfff3ef2308の[正式CI41994393925 attempt2](https://github.com/yokochie/hitotsuzuri/actions/runs/41994393925/attempts/2)が成功。runner28件、Core454件成功・skip0（job127135410554）。
- 別smoke2件成功・skip0：`.build/Smoke-20261105-083111-a2676144b5ab43af9078f84e0406b6ca.xcresult`、21.101秒。
- 単一主bundleは517件全成功・skip0：`.build/Native-functional-20261105-083248-9aaa1089704348aeb6e60aee5962f25e.xcresult`、native job127136138800。製品全体の加重coverage5227/5739=91.08%。checker/80%条件は変更していない。Core機能と全機能UIを同一bundleで測り、限定率の平均/合算で代替していない。
- 過去の正式ローカル504/505、CIの計測欠落、固定コピー失敗、automation初期化障害は上記の履歴として保持する。現在の候補の成功を、過去runの成功へ書き換えていない。実写真/Sandbox/Finder/noteの本人結果は依然未確認。現在の方針どおりローカル全UIの重複再実行はしていない。
