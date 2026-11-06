# Phase2の制約一覧

入力は `../intent-capture/intent-statement.md`、`feasibility-questions.md` と既存規約・コード。評価の根拠と未検証箇所は `feasibility-assessment.md` に記載する。

| ID | 分類 | 制約 | 出典・確認方法 |
|---|---|---|---|
| C1 | 製品 | 本人向けのPhase2記事制作支援。動画・履歴一覧・通知・AI文章補助・自動投稿・外部公開・クラウド機能は除外 | 承認済みintent-statement |
| C2 | 接続 | 追加の連携先なし。noteへの受け渡しは手動 | 本段階Q1 |
| C3 | 通信・写真保護 | 記事用も画像取得の通信を要求せず、事前ダウンロードで運用。写真ライブラリを変更しない | 前段階Q6、project.md Forbidden |
| C4 | 個人利用 | 本人のMacで個人利用。勤務先・依頼元の追加指定なし。法令全般の非該当を断定する意味ではない | 本段階Q2 |
| C5 | 費用・期限 | 固定期限・特別な予算枠・停止事情なし。有料サービス・ツールの追加を前提にしない | 本段階Q3 |
| C6 | 承認 | 要件と実装計画の本人確認後に実装する | 前段階Q4、project.md Mandated |
| C7 | データ | 選択済み4枚の順序と既存成果物を保護。失敗・キャンセルを成功扱いしない | intent-statement、既存schemaVersion 1の選択データ |
| C8 | 環境 | 既存設定はmacOS 27.0、Swift 6.0、Sandbox有効。対応環境変更は本評価で確定しない | project.pbxproj |
| C9 | 品質 | TDD、80%以上の行カバレッジ、統合前CI。Phase1のCI省略を今回の免除として扱わない | team.md Testing Posture、前回build-and-test記録 |
| C10 | 確認 | 実写真・写真アプリの編集・Sandbox・noteへの手動受け渡しは、自動試験と本人の実機確認を区別して記録 | team.md、intent-statement |
