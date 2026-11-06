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
