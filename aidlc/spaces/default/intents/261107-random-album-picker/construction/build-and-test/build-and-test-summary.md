# ビルド・試験のまとめ

アプリのビルドと機能検証のCore 485件が成功した。Macの画面ロック中はUIテスト用アプリが前面化できず、機能UIとカバレッジの判定が残っている。画面ロックを解除したセッションでUIを再実行する。要件と検証の詳細は[試験結果](test-results.md)を参照。

利用者の「Accept failure」の選択に従い、未確認項目を明記したまま承認確認に進む。統合の可否は既存のCI条件で判定する。

## Target Verification Matrix

| 対象 | 根拠 | 期待値 | 実測 | 証拠 | 担当 | 判定 |
| --- | --- | --- | --- | --- | --- | --- |
| FR1・FR2 | 要件書 | 一覧からの抽選と境界処理 | Core成功、UI未確認 | U1WorkflowTests | Build and Test | Unverified |
| FR3・FR4 | 要件書 | 切り替え確認、取消、狭幅の一覧保持 | Core成功、UI未確認 | UI前面化エラー | Build and Test | Unverified |
| NFR1 | 要件書 | 写真ライブラリを読み取り専用で扱う | 既存の読み取り経路を使用 | 対象Core試験と差分確認 | Build and Test | Met |
| NFR2 | 要件書 | 製品全体の行カバレッジ80%以上 | 全機能UI未実行のため未計測 | verify-native.sh --functional | Build and Test | Unverified |
