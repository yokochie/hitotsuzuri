# U3 測定と観測

根拠: [性能設計](../nfr-design/performance-design.md)、[保護設計](../nfr-design/security-design.md)、[論理構成](../nfr-design/logical-components.md)、[機能仕様](../functional-design/functional-spec.md)、[構成要素](../../../inception/domain-design/components.md)、[契約](../../../inception/contract-design/contract-summary.md)。[CI省略](../../../change-decisions/2026-10-31-local-verification.md)を適用する。

## Metrics & KPIs

| Metric | Source | Threshold | Why it matters |
|---|---|---|---|
| 入力→実画面 | 入力単調時刻と表示済みフレーム | 30回以上の95%以上200ms以内 | 内部状態時間では代用不可 |
| 不要要求 | 必要集合との差と要求台帳 | 最後の端点後15秒以内0 | 取消漏れ |
| 所有画像と予約 | 生存台帳 | 合計256MiB以下、往復比例の増加継続なし | キャッシュ外も含める |
| 同時要求 | 受付/完了台帳 | 合計8以下 | 表示4/検証4 |
| 操作支援 | 本人のキーボード/VoiceOver | 全主フロー到達、順序/保存結果を確認 | 未確認を自動成功としない |
| コントラスト | 本人Macの表示色測定 | 通常文字4.5:1、大文字/要素3:1 | ライト/ダーク/設定 |

## Alerts

| Alert | Condition | Severity | Routes to |
|---|---|---|---|
| 性能/上限違反 | 測定が閾値外 | 受け入れ未達 | 日本語検証結果と修正計画 |
| 測定不能 | 許可なし/対応フレームなし | 未確認 | 本人の確認表 |
| 操作失敗 | 権限・参照・保存の失敗 | 原因別案内 | アプリ状態欄 |

## SLIs / SLOs

| SLI | SLO target | Measurement window |
|---|---|---|
| 選択反映 | 95%以上200ms以内 | ローカル100枚以上・30操作以上 |
| 資源回復 | 不要要求0、上限内、増大継続なし | 先頭末尾10往復と終了15秒 |
| 自動検証 | 全件成功、全製品80%以上 | 統合前ローカル |

## Logs & Tracing

通常は失敗分類のみ。任意測定の連番・時刻・件数・bytesは個人IDなしで集計する。フレームは照合後破棄しGit/通常ログ/外部へ保存しない。クラウド監視・分散トレース・通知サービスは追加しない。

