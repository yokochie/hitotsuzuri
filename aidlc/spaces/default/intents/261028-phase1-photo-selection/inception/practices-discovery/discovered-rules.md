# ひとつづり — 確認済みの必須条件

本人の依頼、Ideationで確認済みの条件、本段階の確認回答を根拠とする。本段階の承認・規約への反映はまだ行っていない。開発方式は[team-practices.md](team-practices.md)へ記録し、ここには本人の明示した必須条件を残す。

## Mandated

- ALWAYS アプリ表示名を「ひとつづり」、リポジトリ名を`hitotsuzuri`、Xcodeプロジェクト名を`Hitotsuzuri`、Swiftアプリ型名を`HitotsuzuriApp`とする。
- ALWAYS Phase 1をSwiftUIによるmacOSネイティブアプリとして実装し、まず本人の現在のMacでのローカル実行を確認する。
- ALWAYS システム写真ライブラリ1つの中にある複数の写真フォルダを対象とする。
- ALWAYS 要件と実装計画の本人確認後にConstructionへ進む。
- ALWAYS 要件・設計判断・進捗・検証結果を日本語Markdownへ残し、Swift・Xcodeの経験を前提にしない実行・検証手順を用意する。
- ALWAYS 写真アクセス等、本人による実機確認が必要な項目を明示する。
- ALWAYS AI-DLCの各フェーズ完了時に、そのフェーズの成果物と関連変更をGitにコミットする。

## Forbidden

- NEVER アプリから写真ライブラリ内の写真・アルバム・フォルダを変更する。
- NEVER アプリから画像取得のための通信を要求する。
- NEVER 今回のPhase 1へnote連携・記事生成・動画生成・SNS投稿・クラウド機能・毎週の自動実行と通知・写真本体の恒久複製・履歴管理を追加する。
- NEVER 設計資料の技術選定や参考コードを、成立性を検証せず確定仕様として扱う。

## 根拠

[evidence.md](evidence.md)に入力資料と確認状況を示す。OSやPhotosが独立に行う同期を停止する保証は、アプリの画像取得通信禁止とは区別する。readWrite権限要求は本人が許容済みであり、上記禁止はアプリの変更処理を対象とする。
