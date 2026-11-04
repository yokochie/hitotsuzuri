# U2 ローカル構成

根拠: [性能](../nfr-design/performance-design.md)、[保護](../nfr-design/security-design.md)、[容量](../nfr-design/scalability-design.md)、[信頼性](../nfr-design/reliability-design.md)、[診断](../nfr-design/observability-design.md)、[論理構成](../nfr-design/logical-components.md)、[構成要素](../../../inception/domain-design/components.md)、[機能仕様](../functional-design/functional-spec.md)、[契約](../../../inception/contract-design/contract-summary.md)、[CI省略](../../../change-decisions/2026-10-31-local-verification.md)。追加環境の構築結果ではなくU2の構成設計。

## Deployment

| Facet | Choice | Rationale |
|---|---|---|
| 実行 | 同じmacOSアプリと本人のMac | U1への増分、別サーバーなし |
| ネットワーク | 画像通信false、外部API/待受なし | 読取用途を維持 |
| 保存 | 同じSandbox内Application Support/Hitotsuzuri | 正常JSONは版1・各1 MiB上限 |
| 退避 | 同領域quarantine内のハッシュ方式固定名 | 同じ破損bytesを重複退避せず保護。写真本体なし |
| 環境 | 実機は本人ライブラリ、試験はFakeと専用一時領域 | 破損/削除の試験で個人原本を触らない |
| IaC/配置 | 新規なし | クラウド・配布公開・CIを追加しない |
| 資源/費用 | 既存256 MiB/8要求/書込1を共有。新契約なし | 退避は1 MiB以下の原本だけ、実ディスク使用は計測 |

## Infrastructure Services

| Service | Role | Configuration | Notes |
|---|---|---|---|
| 専用ファイル | 設定/確定/破損原本保護 | 固定名、通常ファイルのみ、symlink拒否 | 退避失敗は確定失敗 |
| メモリ | 復元候補と画像 | 全4枚成功時だけ公開、失敗解放 | 予算の別管理を増やさない |
| Logger | 診断 | 通常は失敗分類のみ | 復元状態はUI用、常時診断へは記録しない |
| 外部DB/queue/CDN/DNS/LB | 非該当 | 作成なし | 既存アプリで完結 |

## Shared Infrastructure

| Shared Resource | Owner Unit | Consumer Units | Access Boundary |
|---|---|---|---|
| アプリと正常保存形式 | U1 | U2、U3 | 5責務/C1〜C4を継続 |
| 破損退避操作 | U2 | 同じアプリ | SelectionPersistence経由、新規確定の意図に限定 |
| 全体品質検証 | 各単位 | U1、U2、U3 | ローカル実行、全製品80%以上 |

