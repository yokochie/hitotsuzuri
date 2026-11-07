# ビルドと試験の結果

## 実行結果

- macOS 27.2 / Xcode 27.2。今回の実装を含むアプリのビルドは終了コード0。
- `U1WorkflowTests` は16件成功、0件失敗。結果は `.build/random-album-picker/Logs/Test/Test-Hitotsuzuri-2026.11.07_17-21-38-+0900.xcresult`。
- `bash scripts/verify-native.sh --functional` のCore工程は485件成功、0件失敗。結果は `.build/random-album-picker/verification/Native-core-20261107-172255-e558441a36324a32a5fb41b089cdeaa6.xcresult`。上の16件を含む。
- 同じコマンドのUIスモークで `testArticleFixtureWindowAndEntryAreReady` が失敗。画面ロック中にアプリが `Running Background` のままで前面化できなかった。再度の起動にも時間がかかったため2件目の途中で停止した。終了コード130。全機能UIと製品全体のカバレッジ計測には到達していない。
- 追加したアルバム抽選UIテストの単独実行も、実装前後に同じ前面化の問題で機能のアサーションまで到達しなかった。
- 性能測定を含めた別のCore実行は491件成功、1件失敗。記事書き出しの `testExportMemoryAndCancellationThirtyTrials` で最大観測間隔75.2msが上限50msを超えた。この試験はCIの機能検証とは別枠。
- 記事書き出しの性能試験を単独で再実行すると1件成功、終了コード0。結果は `.build/random-album-picker/Logs/Test/Test-Hitotsuzuri-2026.11.07_17-27-17-+0900.xcresult`。

## Target Verification Matrix

| ID | 根拠 | 期待値 | 実測 | 証拠 | 担当 | 判定 |
| --- | --- | --- | --- | --- | --- | --- |
| FR1・FR2 | 承認済み要件 | 一覧の全件から抽選し、0件・1件・同じIDを扱う | Core成功。ボタンの操作は未確認 | U1WorkflowTests、NativeInputTests | Build and Test | Unverified |
| FR3・FR4 | 承認済み要件 | 確認・取消と狭幅の一覧保持 | Coreの確認条件と古い結果の拒否は成功。画面操作は未確認 | U1WorkflowTests、UI前面化エラー | Build and Test | Unverified |
| NFR1 | 承認済み要件 | 写真ライブラリを変更せず、画像取得の通信を要求しない | 抽選は現在の一覧を使用し、選択後は既存の読み取り経路を利用 | SelectionWorkflowと対象Core試験 | Build and Test | Met |
| NFR2 | 承認済み要件 | 製品全体の行カバレッジ80%以上 | UIスモークで停止したため未計測 | verify-native.sh --functional | Build and Test | Unverified |

統合前のGitHub Actions実行と、本人の写真ライブラリを使う手動確認は別に記録する。

## 検証結果の扱い

利用者は「Accept failure」を選択した。UIと製品全体の行カバレッジを未確認として、このステップの承認確認に進む。80%以上の基準と統合前CIの条件は維持する。
