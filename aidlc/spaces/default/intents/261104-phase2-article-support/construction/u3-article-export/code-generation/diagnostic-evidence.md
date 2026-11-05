# U3 CI-host固定本文コピーの診断記録

## 現在の確認結果（2026-11-05）
候補4a3b71dの診断CI41994394083は1件成功・skip0。本人承認後の同一ローカルケースも1件成功・skip0・exit0。実マウス、未設定環境での22Tab/Space、固定本文/後続非混入/dirty保持が成立した。片付け関連の更新性能も成功した。[正式run41994393925 attempt2](https://github.com/yokochie/hitotsuzuri/actions/runs/41994393925/attempts/2)はCore454件/runner28件、別smoke2件、単一主bundleの全機能517件が成功・skip0。全製品の加重行coverage5227/5739＝91.08%で80%条件を満たした。以下の失敗や未実施の記述は各候補時点の履歴として保持する。

## 今後の実行制約（本人e97e172f）
通常の自動試験はCI優先とし、同じ目的のローカル/CI全体検証を重複させない。ローカルUIは承認操作が必要でリモート開発を妨げるため、本人の明示依頼/承認時だけ行う。CIで診断できない不足がある場合も必要性を明らかにし、実機専用性能や実写真の確認と実行機会をまとめる。既存のローカルretryは本人5fc4a689の明示依頼による承認確認だった。現在の正式全機能/coverageはCIだけで実行し、ローカルの全UIや正常性能を追加反復していない。

## 診断開始時の許可と不明点（41981707708失敗後）
本人190d3978は当時のCI41981707708の失敗に対して、CI-host単一ケースの診断Retryを選択した。その時点ではButton未発火、Task/guard、完了context拒否、pasteboard失敗、成功後AX反映のどれかは未確定だった。末尾Textだけという仮説も確定していなかった。ローカル成功をCI成功や80%達成と扱わず診断を進めた。

## 実行経路
新しいworkflow_dispatchはdefault branchへ配置されている必要があるため、mainを変更せず利用できるbranch限定push方式を採用した。[GitHub公式説明](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow)。

- workflowファイル：`.github/workflows/diagnose-article-export.yml`
- workflow名：`Diagnose U3 fixed copy`
- job：`fixed-copy`
- 対象branch：`codex/phase2-u2-draft-experience`のみ
- opt-in条件：head commit messageが`[u3-copy-diagnostic]`を含む場合だけ実行。通常pushはjobをskipする。
- runner：既存`xcode-27`、timeout10分、contents readのみ。
- artifact名：`u3-fixed-copy-diagnostic-<完全commit SHA>`、保存1日。
- upload対象：`.build/ArticleExport-copy-diagnostic.xcresult`だけ。所有bundle内の隠しデータも含める。全`.build`、実写真、下書き全体は指定しない。自作の診断添付は下記の合成app window限定。

```sh
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination platform=macOS -only-testing:HitotsuzuriUITests/ArticleExportUITests/testFixedCompletionCopyDoesNotUseLaterEditorChanges -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath .build/ArticleExport-copy-diagnostic.xcresult CODE_SIGN_IDENTITY=- test
```

commit/pushと同SHAで重複する通常Verify runの取消は親が扱う。取消は正式全機能合格を意味せず、診断後は通常の全機能CI/同一主bundleの全製品80%以上が依然必要。verify.ymlと既存coverage checkerは変更していない。

## 固定actionと契約
checkoutは既存SHA `d23441a48e516b6c34aea4fa41551a30e30af803`。upload-artifactは公式repositoryのv4.6.2参照を`gh api repos/actions/upload-artifact/git/ref/tags/v4.6.2`で確認し、commit `ea165f8d65b6e75b540449e92b4886f43607fa02`へ固定した。[公式tag API](https://api.github.com/repos/actions/upload-artifact/git/ref/tags/v4.6.2)。新規外部packageはインストールしていない。

`python3 scripts/test-native-runner.py`は既存26件＋診断workflow2契約＝28件成功。branch/marker、単一case、read権限、10分、固定SHA、always upload、所有bundle限定、1日保存を実YAMLの読取で確認する。これはGitHub実行成功の代替ではない。

## 段階と証拠
DEBUGかつ合成記事fixtureだけで記録する。通常製品ログへ本文/写真ID/場所/パスを追加しない。実OSActionsやguardをバイパスせず、general clipboardを試験で読む/上書きする処理もない。

| 観測 | 判別すること |
|---|---|
| button count/event | SwiftUI Buttonの同期closureが発火したか |
| task count、result/sameProject/working | Task入口とguardで停止したか |
| context-rejected | 完了ID/記事/固定bytes検証が拒否したか |
| pasteboard-failed | 実OSActionsの専用pasteboard書込が失敗したか |
| pasteboard-succeeded;captured、capturedMatches、byte数 | 実成功後の捕捉が成立したか |
| ボタンvalueと独立header、OS表示、window AX/screenshot | 実成功とAX観測のどこに差があるか |

現在の候補はクリック前、コピーの5秒待機後、22Tabのfocus待機後に、当該app windowだけのscreenshotとwindow AX文字列を各1点、計6添付をxcresultへ保存する。失敗メッセージにも分類、ボタンexists/enabled/hittable/frame/value、OS表示を含め、artifact取得前にもCIログから読める。添付はcontinueAfterFailureのアサーションより前に収集する。

追加観測とheader表示がタイミング/配置へ影響する可能性はある。診断成功だけで間欠不具合解消と断定しない。元の固定本文含有・後続本文非混入・dirty保持と5秒期限は維持する。

## 初回ローカル準備時の結果（33d94f3以前）
独立header観測の実Red後、同一UI1件が成功・skip0。bundle：`.build/U3-copy-diagnostic-contract-green.xcresult`。実活動記録から当時のkeepAlways screenshot2/AX2添付を確認した。この時点ではCI-host診断とその後の修正は未実施で、全UI/性能は反復しなかった。

## CI-hostの最初の結果
候補33d94f3の診断CI41989746567は2分13秒で同じケースを失敗として再現し、artifact13397980736を保存した。取得先は`.build/U3-fixed-copy-CI-41989746567`、展開した添付は同名末尾`-attachments`。同SHAの通常Verify41989746509は取消され、全機能合格の証跡ではない。CI環境はmacOS27.0.1/Xcode27.1、ローカルは27.2/27.2。

失敗時は`button=0;task=0;events=idle;capturedBytes=0;capturedMatches=false`。Button callback/Taskより前で止まり、context/pasteboard失敗を示す証拠はない。クリック前のボタンはframe(16,550,164,24)、外側viewport(0,231,1024,474)内に実際に表示されていた。合成イベントplistはその中心(98,562)へ移動し同じ点でmouse-down/upした。直前のwheelは全て-350で、クリックイベント中にwheelはない。クリック後はボタンにKeyboard Focusedが付き、content全体が+334移動してボタンframeは(16,884,164,24)、hittable=falseとなり、callbackは0のまま。保存済み動画でもポインタ到達後の移動を確認した。

アプリのfocusedField onChangeは入力IDの記憶だけで、そのマウスfocus変更を契機に明示scrollToするコードはない。scrollToは独自キー移動、session/mode、出力busy/terminalで使っている。したがって単なる古いXCTest座標や末尾Text不在と断定せず、TextEditorから`.focusable()` Buttonへ押下時にedit focusを移す相互作用を原因候補とした。

AppleはButtonのactivate focusと入力用edit focusを区別し、引数なしfocusableは全interactionを許すと説明している。[公式focus説明](https://developer.apple.com/videos/play/wwdc2023/10162/)。activateだけでは無設定Tab要件を満たす保証がないため、次のce88c242では固定コピーボタンを通常時`.activate`、独自TabでFocusStateが当該IDになった時だけ`[.edit,.activate]`とする最小修正を試した。マウスcallback一回/Task一回と、その後タイトルから実Tab22回/SpaceでTask二回目へ到達する期待を同一ケースへ加えた。既存5秒、固定本文/後続非混入/dirty保持、診断添付は維持した。この時点ではCI-host再判定が必要だった。

ce88c242のローカル事前確認はコンパイル後にUI runner初期化が`Timed out while enabling automation mode`で71秒後にexit65となった。bundleは`.build/U3-fixed-copy-focus-interactions.xcresult`。対象ケースは未実行で、マウス/Tab/SpaceのGreenとは扱わなかった。環境障害を製品の機能Redとも扱わず、その時点で追加実行・設定変更を止めた。条件付きfocus修正の成立と実キー経路は当時未確認だった。

次のCI-host診断には`sw_vers`、`xcodebuild -version`、既存`AppleKeyboardUIMode`の読取stepだけを追加した。設定が存在する場合は生の値を表示し、未設定ならnot explicitly configuredと記す。設定は書き換えず、未設定を有効と解釈しない。契約を先に環境step不在で失敗させ、環境読取と単一only-testing runを区別した後、`python3 scripts/test-native-runner.py`全28件成功。ローカルautomation retry、通常全機能/性能の再実行はしていない。今回のsource変更はArticleExportView.swift、ArticleExportUITests.swift、診断workflow、test-native-runner.pyの4パスで、manifest29パスは変わらない。

## マウス成功とキー経路の切り分け
ce88c242の診断CI41992319852ではマウスが成功し、`button=1;task=1`、guard許可、実pasteboard成功、105bytesの固定本文捕捉一致を確認した。環境はmacOS27.0.1/Xcode27.1、AppleKeyboardUIMode未設定。設定変更はしていない。一方、実22Tab/Space後にTask2が現れず97行目の期待が失敗した。artifact13398399291（118121166bytes、SHA256 b78692f97de6d2f078ad44dd08badb9b2bbb3f7294d3143a4bd68d0a26ac80dd）を取得済み。

既存動画で本文→日付→メタデータ→上部操作へTabが進むことを確認した。通常時activateとする条件がFocusState値自身に依存しているため、当該値のfocus要求が受理されないとeligibilityも変わらない循環を除去する。独立したkeyboardCopyFocusRequestedを先に更新し、その更新のonChangeでfocusを要求する構造に変更した。任意sleepは置かず、マウスで別対象へ焦点を移すと解除する。

DEBUG fixtureには各Tabの要求ID、focus-changed、eligibility-updated、move番号を最大80件まで記録する。Space前に22Tabの固定コピーfocusを明示検査し、同じapp windowのAX/screenshotを追加で保存する。固定本文/後続非混入/dirty、最初の実マウス成功、5秒の各期待を維持する。

4a3b71dの準備時にはapp buildと対象build-for-testing、runner28契約が成功した。この段階ではローカルUI automationを再試行せず、キー修正の実Greenを次のCI-host結果待ちとした。正常p95専用性能は反復せず、片付け修正に関係するメモリ/取消性能を別途更新する方針とした。その後の結果は次節に記す。

## 同じ候補での診断成功
4a3b71d1e15795fedcba4e8a808addfff3ef2308の診断CI41994394083は1件成功・skip0（62.915秒、job127133961320）。macOS27.0.1/Xcode27.1、AppleKeyboardUIMode未設定で、実マウスcallback/コピー、実22Tabのfocus到達、Spaceによる二回目の実コピー、固定本文/後続非混入/dirty保持の全期待が成立した。artifact13399253408は`u3-fixed-copy-diagnostic-4a3b71d1e15795fedcba4e8a808addfff3ef2308`、116084473bytes、SHA256 ffdf15925da1bc2572bef4a7499983c52fc6a9cfe68ebcabbf719360704d7894、保存期限2026-11-06T08:28:41Z。

本人5fc4a689がローカル承認後の再試行を明示したため、同じ候補/同じ一メソッドをソース無変更で実行し39.816秒、1件成功・skip0・exit0を実bundleで確認した。bundleは`.build/U3-fixed-copy-local-authorized-retry-4a3b71d.xcresult`、ローカルのAppleKeyboardUIMode読取値は0。こちらでも設定を変更していない。

診断1件の成功は正式全機能/coverageの代替ではない。同SHAで取消済みだった通常run41994393925のattempt2を別途実行して成功を確認した。主bundleは`.build/Native-functional-20261105-083248-9aaa1089704348aeb6e60aee5962f25e.xcresult`、別smokeは`.build/Smoke-20261105-083111-a2676144b5ab43af9078f84e0406b6ca.xcresult`。片付け関連の更新性能はperformance-evidence.mdへ記録済み。
