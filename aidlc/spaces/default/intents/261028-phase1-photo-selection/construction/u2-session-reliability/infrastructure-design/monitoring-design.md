# U2 ローカル計測

根拠: [性能](../nfr-design/performance-design.md)、[保護](../nfr-design/security-design.md)、[容量](../nfr-design/scalability-design.md)、[信頼性](../nfr-design/reliability-design.md)、[診断](../nfr-design/observability-design.md)、[論理構成](../nfr-design/logical-components.md)、[構成要素](../../../inception/domain-design/components.md)、[機能仕様](../functional-design/functional-spec.md)、[契約](../../../inception/contract-design/contract-summary.md)、[CI省略](../../../change-decisions/2026-10-31-local-verification.md)。追加環境の構築結果ではなくU2の構成設計。

## Metrics & KPIs

| Metric | Source | Threshold | Why it matters |
|---|---|---|---|
| 4枚復元画像期限 | 単調時計 | 全体/個別の早い方、最大15秒 | 部分成功を復元にしない |
| 画像保持 | 単一管理台帳 | 生存バッファ+予約256 MiB以下 | 復元画像も同じ予算 |
| 正常/破損/未知版/失敗 | 注入I/Oと結果型 | 誤分類・誤上書き0 | 原本保護 |
| 行カバレッジ | 全単位のXcode結果 | 80%以上 | U2追加後の製品全体 |

## Alerts

| Alert | Condition | Severity | Routes to |
|---|---|---|---|
| 復元不可 | 欠損/画像不可等 | 回復案内 | 画面の状態文 |
| 破損/未知版 | 読込検査失敗 | 原本保護 | 日本語の次操作案内 |
| 検証失敗 | テスト/カバレッジ未達 | 統合停止 | ローカル記録 |

## SLIs / SLOs

| SLI | SLO target | Measurement window |
|---|---|---|
| 全有効4枚の復元 | 全成功時だけ一括復元 | 各起動・結合テスト |
| 失敗時原本bytes | 不変 | 退避/置換の失敗注入 |
| 常時サービス稼働率 | 非該当 | ローカル実行 |

## Logs & Tracing

通常診断は失敗分類のみ。上流O21の「復元状態と失敗分類」という表現のうち復元状態は画面の状態投影として扱い、通常ログには残さない。検証時の匿名な時間/件数だけ一時計測し、個人ID・名称・原本bytes・パスは記録しない。外部送信/監視基盤なし。

