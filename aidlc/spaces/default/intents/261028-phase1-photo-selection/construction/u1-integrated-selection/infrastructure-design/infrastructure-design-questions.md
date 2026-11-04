# U1 実行環境・CI設計の確認

## 入力と既決事項

本人のMacでローカル実行し、配布公開・AWS配置・クラウド機能は追加しない。当初の専用Mac CI案は、本人の変更承認により今回のPhase 1では撤回した。[変更記録](../../../change-decisions/2026-10-31-local-verification.md)に従い、統合前ローカルビルド・自動テスト・カバレッジ80%以上を必須とする。具体的検証コマンドは最初の検証前に本人確認する。

2026-10-31にGitHub連携からリモートyokochie/hitotsuzuriのvisibility=privateを確認した。公開範囲の変更は行っていない。CIランナーは未登録として計画し、既存設定がある場合は構築前に確認する。

## Q1 CIを動かすMac

専用のCI実行環境を、どこに用意するか。

A. 現在のMacにCI専用ユーザー — 開発・写真用ユーザーと別のmacOSアカウントを用意する。
B. 別のMac — 別のMacに専用環境を用意する。OS/Xcodeと接続方法は後で確認する。
X. Other (please specify)

[Answer]: X. CIを省く。CI専用Macは用意せず、統合前ローカル検証へ変更する。本人の変更承認c3dba068・90df9923に基づき、この質問は非該当となった。

## Consolidated Summary Confirmation

- 本人のMacのXcodeでビルド・実行する。クラウド・配布公開・CI専用環境を追加しない。
- CI工程を省き、各実装単位の統合前にローカルビルド・自動テスト・行カバレッジ80%以上を確認する。TDDを維持し、具体的な検証コマンドは検証前に本人確認する。
- アプリの写真アクセスは本人用の実ライブラリで確認し、自動テストはFakeと分離したテスト保存先を使用する。
- アプリはSandbox内の専用領域に保存する。ローカル用署名設定と写真権限の説明をXcodeプロジェクトへ含め、本人が起動して許可・拒否・並び・画像取得を確認できる日本語手順を用意する。
- 通常診断は失敗種別のみ、性能計測は検証時だけとし、外部監視・通知を追加しない。
- 更新した設計と統合前の検証記録をGitで管理し、AI-DLCフェーズ完了時のコミットを続ける。

Does this all look correct before I generate the artifact?

- Looks correct
- Request changes

[Answer]: Looks correct
