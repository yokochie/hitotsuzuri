# 画像表示復帰のCI証拠

## 変更前の基準

- コミット: d3feef45fe647eea80261d9f04bfc80123cdfa69。
- CI: https://github.com/yokochie/hitotsuzuri/actions/runs/42030797393 （push、success）。
- native-core job127256435543: success。runner契約Python28件成功（7.187秒）。Core460件成功。
- native job127257687149: success。起動smoke2件、全機能524件（Core460 + UI64）が成功。全製品5284/5798行、91.13%。
- 同SHAのPR run42030806045はcancelled。これを成功根拠にはしない。

2026-11-06にrun metadataと両jobのログを読み取った。新しいCI、ローカルbuild/native/UIを起動していない。計画作成前にApp/Core/各Tests/scripts/.githubのソースがd3feef4と一致することをgit diff --quietで確認（終了0）。e6111daは調査/要件等の記録のみ。

## 今回のRed / Green

### 最初の回帰試験実行（有効なRed未取得）

- コミットf912576c7ebf9dcac6855a03f2798b241ab0d3a5、CI42167693848（push）。
- Core job127727889551成功。native job127728593017は26分36秒でexit65。
- 起動smoke2件、既存Core460件と既存UI64件は成功。新ArticlePhotoRestorationUITestsの10件は失敗。
- T1–T8は初期表示を確認するhelperの45行でStaticText.labelが空となり失敗。owner/pixel/要求数と実画像要素の初期条件を通った後の観測不備で、出力後の欠落まで到達していない。
- T9は初回要求と再試行有効状態、T10は初回保留応答数の待機でtimeout。診断が足りず、これらを製品の再現成功と扱わない。
- T4には別途、Deliveryが実画像処理終了を待つのに応答を返す前にendedを待つ手順不備も静的に見つかった。初回CIではそこまで到達していない。

現在はテスト/fixtureの観測と手順を修復する。通常の表示復帰ロジックは未変更。有効な意図した失敗を再観測してからGreenに進む。変更前の成功や試験準備の失敗を修正根拠へ代用しない。

### 観測修復後の対象限定CI（有効なRed）

- コミットd45acb74a7c8f48db690a10880bf5aa984c3aab2。
- CI https://github.com/yokochie/hitotsuzuri/actions/runs/42171059895 、job127738722780、6分33秒、exit65。
- 起動smoke2件成功、新UI10件は3成功・7失敗（279.881秒）。
- 対照T1（fresh下書き再開）、T9（マウス/キーで番号別再試行）、T10（遅い旧応答の排除/不要保持解放）は成功。
- T2正常出力、T5保存先取消、T6容量拒否、T7保存失敗、T8入力検証失敗の5件は、出力終端後に `owner=false;imageBusy=false;pixels=none,none,none,none;entered=1` の状態で4枚のready/要求再開を待って失敗。通常復帰ロジックは未修正で、目的の表示欠落を再現した有効なRedとする。
- T3出力画像失敗はAX snapshotの取得エラー、T4取消はbusy中のメッセージ待ちtimeout。両者は有効なRed5件と区別し、修復してから成功を確認する。

修復したfixtureはrestore-*の場合だけPickerの検証用adapterを分け、記事driverの要求/保留とcacheを独立観測する。通常App/既存fixtureの共有構成は変更しない。この新classはPicker共有時の相互作用を証明せず、既存の共有資源試験/既存UIと本人確認を併用する。

全機能CIを繰り返す負担を減らすため、一時的なmarker限定 `diagnose-photo-restoration.yml` で承認計画の対象指定コマンドを実行した。同SHAの通常full runs42171059761/42171064663は取消を要求した。これらを成功証拠にはしない。Greenを対象限定で確かめた後は一時workflowを削除し、通常の全Core→smoke→全機能/80%検査を通す。最終CIの条件を省略しない。

### 修正後の対象限定Green

- コミット8173d90416855eed3d6e0eca2c6ec12b444c840e。
- CI https://github.com/yokochie/hitotsuzuri/actions/runs/42172183678 、job127742336787、6分13秒、success。
- 起動smoke2件、新ArticlePhotoRestorationUITests10件が全成功（262.727秒）。T2/T5–T8の意図したRed5件が成功へ転じ、T3の観測とT4の取消手順も修復して成功した。
- 番号ごとの実画像、再取得回数、本文/順序、取消中の出力実busyと要求不変、旧応答拒否/解放を確認。部分実行であり全体成功・全体coverageを主張しない。
- 重複する同SHAの通常full runs42172183673/42172188955は取消を要求し、成功証拠にしない。

一時診断workflowを削除して通常の全機能CIへ進む。製品・試験ソースは対象限定Green8173d90から変えず、全体結果を追記する。

### 通常の全機能Green

- コミット0fd9e72b0aa22c3568227c8b8d3bc952861b6111（製品/試験は8173d90と同一）。
- CI https://github.com/yokochie/hitotsuzuri/actions/runs/42173044894 、pull_request、success。
- native-core job127745087980: 1分59秒、runner契約28件成功（5.431秒）、機能Core460件（157+149+154）成功。
- native job127745757442: 27分56秒、起動smoke2件、全機能534件（Core460+UI74）成功。新10件は全成功（265.995秒）。選択した機能試験のskip0。性能試験は既存の別区分のままで、今回新しい性能結果を主張しない。
- 全手書きApp/Core Swiftの行カバレッジ5467/5981 = 91.41%。80%閾値は不変。
- macOS27.0.1 (26A434)、Xcode27.1 (27A9275)、arm64、VirtualMac2,1。
- 主bundleはCI内の `.build/Native-functional-20261106-061710-61cb68a8dfe64683ac4142902c3a4f0d.xcresult`。ローカルへダウンロードしていない。
- 重複push run42173038631は取消要求済みで、証拠は上記PR runのみ。

両jobログとrunのhead SHA/conclusionを読み取って確認した。新しいローカルbuild/native/UI/性能試験を実行していない。本人Macでの今回の表示解消確認は未取得。

## 出力後照会を含む所有期間の回帰

本人の変更依頼に従い、出力Sessionの終了後も記録照会が終わるまで再要求を受理しないことをT11へ追加した。既存の全機能成功534件はこの追加条件の成功証拠へ代用しない。

### 追加回帰のRed

- コミットf160e52da263f0e131676e8febb73dad4b86654f。
- CI https://github.com/yokochie/hitotsuzuri/actions/runs/42178316595 、job127761830583、1分42秒、exit65。
- 対象は `testPostExportQueryKeepsOwnershipUntilNextExportCanStart` の1件のみ。1件実行・1件失敗（27.553秒）。
- 225行、後照会中の受理回数は期待1に対して実際2。診断は `working=false;exportSessionBusy=false;entered=2;accepted=2;reentryAttempts=1;postQueryWaiters=2;postQueryCalls=2;requests=1,1,1,1`。
- 通常のbusy/入口guard/復帰は未修正で、記録照会相当のDEBUG gateにより既存awaitの割込み順を制御した。実Coordinator入口が再要求を受理するという目的の失敗を確認し、compile/fixture失敗とは区別する。
- 重複full runs42178316585/42178324015は取消要求済み。新回帰のRedは上記の対象1件で確認し、既存10件の無駄な再実行を省いた。

通常制御を修正し、既存runnerのclass11件でGreenを確認した後、通常の全機能CIへ戻す。

### 所有期間修正後の対象限定Green

- コミットc9a4d00b39e69f3c95fd13319d899f9f93da94c0。
- CI https://github.com/yokochie/hitotsuzuri/actions/runs/42178850429 、job127763494549、7分7秒、success。
- 起動smoke2件成功、class11件が全成功（315.966秒）。追加T11は44.434秒で成功し、再受理のRedからGreenへ転じた。
- 実入口で後照会中の再要求を拒否し、UIも無効化、表示要求不変、照会解除後の表示復帰、次の通常出力の受理・終了・4枚の復帰を確認した。T11のassertはGreenのために弱めていない。
- 重複full runs42178850387/42178856617は取消要求済み。部分実行のため全体coverageと全体成功はまだ主張しない。

通常ソースの変更は、exportArticleのpreparingExportを単一deferで後照会まで保持し、解除と同じ記事の表示復帰準備の間にawaitを置かないもの。最初の保存確認取消では表示を維持し、早期returnでもbusyを解放する。Core/既存の世代防御は不変。一時診断workflowを削除し、通常の全機能/80%検査を実行する。
