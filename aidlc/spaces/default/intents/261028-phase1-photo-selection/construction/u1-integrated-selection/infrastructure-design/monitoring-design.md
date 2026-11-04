# U1 ローカル診断・計測の構成

根拠: [性能設計](../nfr-design/performance-design.md)、[保護設計](../nfr-design/security-design.md)、[容量設計](../nfr-design/scalability-design.md)、[信頼性設計](../nfr-design/reliability-design.md)、[診断設計](../nfr-design/observability-design.md)、[論理構成](../nfr-design/logical-components.md)、[構成要素](../../../inception/domain-design/components.md)、[機能仕様](../functional-design/functional-spec.md)、[内部契約](../../../inception/contract-design/contract-summary.md)、[CI省略の決定](../../../change-decisions/2026-10-31-local-verification.md)、[確認回答](infrastructure-design-questions.md)。設計であり環境設定・製品ビルド・自動テストの実施結果ではない。

## Metrics & KPIs

| Metric | Source | Threshold | Why it matters |
|---|---|---|---|
| 入力から描画まで | U3のInstrumentsと画面記録・検証時マーカー | 30操作以上の95%以上が200ms以内 | 内部計算だけで表示性能を誤判定しない |
| 画像要求の経過 | 注入した単調時計 | 1件15秒、確定前4件全体15秒 | 進行不能時に操作を戻す |
| 保持画像と予約byte数 | 単一画像管理のカウンタ | 256 MiB以下 | 全用途を同じ予算へ含める |
| 不要要求数 | 必要集合と要求表の差分 | 10往復後15秒以内に0 | 要求の残留を発見 |
| 行カバレッジ | Xcodeテスト結果 | 80%以上 | 統合前のローカル品質条件 |

## Alerts

| Alert | Condition | Severity | Routes to |
|---|---|---|---|
| 画像取得失敗・期限 | 最終画像未取得 | 操作可能な失敗 | 本人へ画面内の日本語案内 |
| 保存失敗 | 書込失敗・未知版等 | 確定成功にしない | 本人へ保持と再試行/回復案内 |
| 検証未達 | テスト失敗・カバレッジ不足・性能未達 | 統合停止 | ローカル検証記録と本人への報告 |
| 外部通知 | 非該当 | 非該当 | メール・クラウド通知なし |

## SLIs / SLOs

| SLI | SLO target | Measurement window |
|---|---|---|
| 200ms以内の画面反映率 | 95%以上 | 本人のMac・100枚以上・画像読込後30操作以上 |
| 不要要求残留 | 0 | 10往復後15秒以内 |
| 画像保持予算 | 256 MiB以下 | 検証セッション全体の最大値 |
| サーバー稼働率 | 非該当 | ローカルアプリのため月間SLAなし |

## Logs & Tracing

| 種類 | 実装先 | 取扱い |
|---|---|---|
| 通常の診断 | OS標準Logger | 固定の失敗種別だけ。独自ログ保存・外部集約なし |
| 検証用相関 | メモリ内の匿名操作ID | 写真IDと結びつく出力は残さずセッション終了で破棄 |
| 匿名集計 | 作業記録のMarkdown | 条件・対象コミット・件数・最大値・合否を記録 |
| ダッシュボード | 非該当 | Instruments/Xcode結果と日本語記録で確認 |

未測定・測定不能・失敗を成功と表記しない。実機データ・写真ID・名称・画面の個人写真を検証記録へ転載しない。

