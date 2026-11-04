# U1 ローカル実行環境

根拠: [性能設計](../nfr-design/performance-design.md)、[保護設計](../nfr-design/security-design.md)、[容量設計](../nfr-design/scalability-design.md)、[信頼性設計](../nfr-design/reliability-design.md)、[診断設計](../nfr-design/observability-design.md)、[論理構成](../nfr-design/logical-components.md)、[構成要素](../../../inception/domain-design/components.md)、[機能仕様](../functional-design/functional-spec.md)、[内部契約](../../../inception/contract-design/contract-summary.md)、[CI省略の決定](../../../change-decisions/2026-10-31-local-verification.md)、[確認回答](infrastructure-design-questions.md)。設計であり環境設定・製品ビルド・自動テストの実施結果ではない。

## Deployment

| Facet | Choice | Rationale |
|---|---|---|
| 実行モデル | 本人のMac上の単一macOSネイティブアプリ | 個人利用。コンテナ・サーバーは不要 |
| 開発環境 | 導入済みXcode27.2/Swift6.4.2、arm64、macOS27.2の観測環境 | アプリの最低OS設計値27.0、Swift6。ビルド結果は別に記録 |
| ネットワーク | 製品の画像取得通信をfalse。外部API・待受ポートなし | アプリの読取用途。OS独立同期の停止は保証しない |
| 保存 | SandboxのApplication Support/Hitotsuzuri、settings.jsonとselection.json | 固定名・版付きJSON・独立した原子的置換。写真本体は保存しない |
| 環境分離 | 通常実行は本人の実ライブラリ、自動テストはFakeと実行ごとの専用保存先 | 自動テストで個人データを読み書きしない |
| 構成管理 | Hitotsuzuri.xcodeproj・共有scheme・設定ファイルをGit管理 | ローカルで再現する。CI・クラウドIaCは生成しない |
| 署名 | ローカル実行用のad-hoc署名を第一候補。開発者アカウントや証明書の取得を前提にしない | Sandbox・写真権限を含む実行可否を対象Macで確認し、不成立なら変更案を示す |
| 資源 | 画像予算256 MiB、画像同時8件、確定保存1件 | アプリ内部の制御。マシン全体の使用量上限ではない |
| 追加費用 | クラウド・専用CI・有料証明書の新規契約なし | 既存Macの電力・ディスクは利用するが月額料金を捏造しない |

## Infrastructure Services

| Service | Role | Configuration | Notes |
|---|---|---|---|
| 写真ライブラリ | 読み取り元 | システム写真ライブラリ1つ。認可は本人操作 | アプリから変更を提供しない |
| 専用JSON | 設定・確定参照 | 各最大1 MiB、版1、保存直列化 | 破損・未知版保護、画像なし |
| 画像管理 | メモリキャッシュ | 明示バッファと予約予算、LRU、不要要求取消 | OS内部の保持量は別観測 |
| OS標準Logger | ローカル診断 | 失敗分類のみ | 個人ID・名称・画像は含めない |
| 外部DB・queue・search・CDN・DNS・load-balancer | 非該当 | 新規作成なし | ローカルアプリの責務内で完結 |

## Shared Infrastructure

| Shared Resource | Owner Unit | Consumer Units | Access Boundary |
|---|---|---|---|
| Xcodeプロジェクトとアプリ構成 | U1 | U2、U3 | 同じアプリへの増分。別アプリを増やさない |
| 設定と最後の確定JSON | U1 | U2、U3 | SelectionPersistence経由のみ。版変更時は移行を設計 |
| 写真参照・画像予算 | U1 | U2、U3 | C2/C3の既存所有者を通す |

## 準備と実機確認

日本語手順はXcodeでプロジェクトを開く・schemeを選ぶ・Runする・写真の利用目的を読んで許可する順に作る。初回拒否・制限・手動並びの比較・ローカル画像・保存の結果を本人が記録する。bundle identifierはコード生成計画で一意の固定値を選び、途中で勝手に変えて権限状態や専用保存先を分断しない。アプリ権限のリセット・既存データ削除は自動検証の前処理にしない。

