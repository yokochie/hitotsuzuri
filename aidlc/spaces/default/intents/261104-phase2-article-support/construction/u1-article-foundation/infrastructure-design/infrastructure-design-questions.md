# U1 実行環境の確認

## 調査と既決事項
- 本人環境macOS27.2/Xcode27.2、製品対象macOS27.0、既存Bundle ID com.yokochie.Hitotsuzuri、署名Manual/ad-hocを維持する。
- 現entitlementsはSandboxと写真ライブラリ。利用者選択先への書込権限は未設定で、Phase2で追加する。
- 選択保存はApplication Support/Hitotsuzuri以下のselection.json/settings.json。記事はこの既存領域の別サブディレクトリに分離し、旧形式を書換えない。
- GitHubの公開リポジトリと標準xcode-27、承認済みbash scripts/verify-native.shを使う。CI成功前の統合なし、有料追加なし。
- Apple一次資料: https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.files.user-selected.read-write 、https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox

## Consolidated Summary Confirmation
- 本人のMacで動く単一アプリを維持し、サーバー/AWS/新しいクラウド保存を追加しない。Sandboxと既存写真許可を保ち、写真変更APIと画像通信を使わない。
- 記事と内部操作記録はアプリ専用Application SupportのHitotsuzuri/Articlesに保存し、選択/設定と分離する。内部UUIDと版付きレコード、OS排他・同期・原子的確定参照を使う。試験は別一時領域へ注入し本人データを使わない。
- 出力先は標準のフォルダ選択で都度選び、user-selected.read-write権限だけを追加する。ジョブ中のアクセスを管理し、保存先への永続bookmarkや全ファイル権限は追加しない。再起動後の片付けには必要なときだけ同じ保存先の再選択を求める。
- 本人Macのローカル正常ボリュームで保存/復旧と画像性能を検証する。任意の外付け/ネットワーク保存先の原子性や同期成功を仮定せず、非対応時は旧データを守って失敗/不確定を案内する。電源断の絶対保証とはしない。
- CIは標準xcode-27、PR/作業ブランチpush/手動実行、読取権限・秘密情報なし。合成fixtureの単体/統合/UI試験と80%以上のカバレッジを同じ検証コマンドで実行。初回CIはU1統合前に動かす。
- CIの追加キャッシュ/成果物アップロード、大型runner、有料サービス、配布/公開は追加しない。テストログとコミットを証拠にする。実写真/色/回転/Sandbox/noteは本人Macで別確認する。
- 計測はOS標準機能とローカル診断を使い、機密をログへ出さない。起動/署名/写真認可/確認/戻し方を日本語で残す。期限の同時競合は完了を採用する直前にも絶対期限を比較し、順序逆転試験をコード計画へ引き継ぐ。

Does this all look correct before I generate the artifact?

- Looks correct
- Request changes

[Answer]: Looks correct
