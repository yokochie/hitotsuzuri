# GitHubの基本設定

## 依頼と適用

2026-11-06、画像表示修正と並行して本人からDependabotとGitHub設定を依頼された（eda1ccfb）。本人が「推奨の基本設定（依存の脆弱性通知・修正PR、mainへの直接push防止、CI必須、squash merge）」を選択した（4b4dc643）。画像表示修正の要件や計画の変更ではなく、追加のリポジトリ管理作業として実施。

## GitHub側で適用・読み返し確認済み

| 設定 | 適用値 |
| --- | --- |
| Dependabot alerts | 有効、GETの成功で確認 |
| Dependabot security updates | enabled=true、paused=false |
| 統合方式 | squashのみ。merge commit/rebase mergeは無効 |
| マージ後の作業ブランチ | 自動削除 |
| squashコミット | PRタイトルとPR本文を使用 |
| mainへの変更 | PR経由必須、管理者にも保護を適用 |
| 必須チェック | GitHub Actions（app15368）のnative-coreとnative |
| 最新mainへの追従 | 必須 |
| 承認件数 | 0（個人開発で自己承認できないため。他者への依頼は送信しない） |
| レビュー会話 | 解決必須 |
| 履歴 | linear必須、force push/削除禁止 |

既存のbranch protection/rulesetは未設定だった。既存設定の上書きや権限拡張、リポジトリ公開範囲の変更、マージ/自動マージ実行はしていない。GitHub connectorに設定更新機能がないためgh APIを使用した。

## 定期更新ファイル

`.github/dependabot.yml` を追加。既存の更新対象はGitHub Actionsで、Swiftの外部packageはない。毎週月曜09:00 Asia/Tokyo、全Actionsを1グループ、開いている更新PR上限2。自動マージ、reviewer/assignee追加は設定しない。

この設定ファイルはmainへ統合されて初めて定期更新の対象になる。現在の作業ブランチにcommitした時点を定期更新の稼働済みと記録しない。リポジトリ側の脆弱性通知/修正PRの有効化とは区別する。

## 公式仕様の確認

- https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference
- https://docs.github.com/en/rest/branches/branch-protection

要望文書cac45ca、README更新8d30c87は各単独コミット。既存の修正前CIを中断しないよう、追加文書と設定のpushは次の修正とまとめる。
