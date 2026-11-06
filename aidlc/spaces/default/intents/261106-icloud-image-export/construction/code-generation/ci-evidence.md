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
