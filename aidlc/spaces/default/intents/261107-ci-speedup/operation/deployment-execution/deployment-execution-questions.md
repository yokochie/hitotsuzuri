# GitHub Actionsでの検証

## Consolidated Summary Confirmation

- GitHubの最新mainから作成した `codex/ci-speedup` のcommit `4d64dc4` を検証対象とする。差分はUIテスト2ファイルのみ。別作業のローカルコミットは含まない。
- このブランチをGitHubへpushし、main宛てのドラフトPRを作って既存の必須CIを実行する。マージとアプリ配布はこの確認の対象外。
- Core、smoke、全機能、80%カバレッジの結果と所要時間を確認する。初回は1標本として記録し、30%目標には同等条件の成功標本が合計3件以上必要。

Does this all look correct before I generate the artifact?

- Looks correct
- Request changes

[Answer]: Looks correct
