# アプリ内画像取得のCI証拠

## 変更前基準

PR CI42179866652、f272e3d4fb9783f38acc7745a1d3bcd8ac2b60b9のCore460/UI75＝機能535件とsmoke2件成功、全製品5527/6041行＝91.49%。今回開始前の製品・試験・runner/CIは同headと差分なしを確認。記録のみ4fae0a6/7f7faeeへ進んだ。ローカルの同じbuild/native/UI/性能は再実行していない。

## Core Red

- head2a40f34ee2adc5cd6a7c9705edf50cce62cd9ef2。
- [対象限定CI42211810710](https://github.com/yokochie/hitotsuzuri/actions/runs/42211810710)、job127872011876、1分14秒、exit65。
- `bash scripts/verify-native.sh ArticleCloudImageTests ArticleCloudExportTests`。Image6件中4失敗、Export2件中2失敗。対照2件成功。
- PhotoKit optionsとImageAccessの許可は実際false,false、期待true,false。進捗は実際[]、期待0/0.25/1。取得待ち301秒後の完了はtimedOut。
- Deliveryは4枚ともfalse（期待true）、各画像301秒の待機を経た一式出力がtimedOut。コンパイル/fixture不備ではなく、目的の6件の失敗を観測した。
- 対照の既定local経路期限と取消後の実終端gateは成功。
- Redでは試験注入境界と旧動作へforwardするoverloadのみ追加し、通常network=false・期限・進捗未接続を維持した。
- 重複する通常full push42211810466、PR42211818940は取消要求済み、成功証拠に数えない。一時marker限定workflowは最終全機能CI前に削除する。

Core Green、UI Red/Green、最終通常全機能の結果はこれから記録する。上記基準を変更後成功へ代用しない。

## Core Green

- head6a389a1f102e52f1c4e0f7cf6f2c8c3973eb61f9。
- [対象限定CI42212786801](https://github.com/yokochie/hitotsuzuri/actions/runs/42212786801)、job127875272187、TEST SUCCEEDED。
- 同じ対象指定でImage12件（0.079秒）とExport5件（0.849秒）、計17件が全成功。先の意図Red6件も成功へ転じた。
- reader内部の一意ticket、options許可/進捗、取得待ちと変換30秒の分離、Deliveryで取得待ちを期限へ算入しない処理、取消後実終端/旧通知拒否、失敗再試行・書込期限を検証した。
- UI/Sessionの進捗表示はまだ未変更で、画面接続の成功を主張しない。全機能/全体coverageは最終通常CIで別途確認する。
- 重複通常full42212790791（PR）/42212786896（push）は取消要求済み。これらを成功証拠に数えない。

## UI Red

- head7561c21717f252fbff79b4e8cc9543fbe1bc65f3。
- [対象限定CI42213371286](https://github.com/yokochie/hitotsuzuri/actions/runs/42213371286)、job127877241459、2分31秒、exit65。
- 起動smoke2件成功、ArticleCloudExportUITests3件は全失敗（54.103秒）。
- U1: 実際の取得中表示「画像 0/4：画像を取得中」が対象写真1/4を示さない（58行）。U2: 実readerの進捗後も50%を表示しない（19行）。U3: 写真2の取得失敗時に写真アプリの事前取得案内が残る（91行）。
- 実Coordinator→Delivery→ImageAccess→合成readerを通り、通常Session/Viewを変更する前の画面接続不足を再現した。compile/fixtureの失敗ではない。後続の取消/復帰/再出力assertはGreenで確認する。
- 重複full42213373800（PR）/42213371196（push）は取消要求済み、成功証拠にしない。

## 画面修正後の初回検証

- head5d20d82109271dae3004ff8a61763b7e7ac2f324。
- CI42214062065、job127879569109、7分28秒、exit65。
- Core20件（Image12＋Export8）とsmoke2件、既存写真復帰11件（290.986秒）は成功。
- 新UI3件は失敗（65.160秒）。U1/U2は50%進捗の待機timeout、U3は一式result存在/操作復帰/表示readyを経た後、完了メッセージassertで失敗。新3件を成功と扱わず、製品接続とfixture/AX観測を切り分ける。
- 対象UI合計14件は11成功/3失敗。重複full42214065371（PR）/42214062037（push）は取消要求済み。

### 観測修復の切分け

b6fd9a835543c47d7690b88b7e5553e59dd228e9、CI42215343404/job127883831537はsmoke2成功、新UI3件失敗（48.893秒）。今回は追加診断の `exportStage=none;exportFraction=none` が、ready helperの全体文字列 `!contains("none")` に衝突し、出力開始前に失敗した。実診断はowner=true、working=false、pixels=47,64,81,98、要求各1。製品や画像取得の失敗ではなく試験観測の不備であり、元の進捗/完了文字の確認へは未到達。写真状態のフィールドだけを正確に照合するよう修復する。

重複full42215347506（PR）/42215343423（push）は取消要求済み。上記を有効な製品RedやGreenへ数えない。

### 状態文字の更新不整合

caac75b7963e6c86b7e8061f2776ed5df2ec0e31、CI42215899010/job127885705780、2分59秒、smoke2成功、新UI3件失敗（77.493秒）。写真readyの観測修復後、次を確認した。

- U1/U2: 実SessionはexportFraction=0.5、exportMessageは写真1/4の50%、実ProgressViewのAX値も0.5。一方、状態Textのlabelは空、valueは初期取得中の文字を保持し50%なし。
- U3: 実Sessionは一式完了、resultあり、4枚ready/操作復帰/再出力6要求も確認。一方、Textのvalueは前の写真2失敗案内を保持。

このためmodelだけを成功条件へ緩めず、選択可能Textの更新境界を修正する。Core取得/進捗処理の失敗とは区別する。重複full42215902921（PR）/42215899016（push）は取消要求済み。

## UI Green

- head78be69a01da29f993110637ce98a1c4b54951c3d。
- [対象限定CI42216526269](https://github.com/yokochie/hitotsuzuri/actions/runs/42216526269)、job127887810479、3分0秒、success。
- smoke2件と新UI3件が全成功（75.878秒）。取消27.059秒、進捗/一式完了24.727秒、写真2失敗後の再出力24.092秒。
- 状態文字のidentityをmessage更新ごとに変え、選択可能Textを再生成した。現在のTextと実Sessionと進捗バーの独立照合を維持し、取消実終端後の復帰/4枚再出力の末尾assertも成功した。
- Core20/既存写真復帰11件は5d20d82の対象CI成功結果を保持し、最新全体はこれから通常CIで検証する。
- 重複full42216530398（PR）/42216526253（push）は取消要求済み。対象限定workflowを削除して通常CIへ戻す。

## 通常全機能CIの時間切れ

e52f64703d01073f74afaa7ec37de4f2edf3236c、PR CI42217045109。native-core127889544511は2分20秒でCore480件とrunner契約試験が成功。native127890554218は30分27秒、jobの30分上限で取消された。ログ上、新cloud UI3件と写真復帰11件は成功し、最後は既存NativeInputTestsの途中だった。全件完了・coverage集計へ到達していないため全体成功ではない。

当初は通常workflowを変更しない予定だったが、今回の全体実行が実行時間枠を超えたため、native jobの上限だけを30→45分へ変更する。試験選択・除外・実行順・80%カバレッジ条件・Core先行は変更しない。所要時間が短くなるという主張や品質条件の免除ではなく、既存試験を最後まで実行するための環境修正として記録する。重複push42217041720は取消要求済み。
