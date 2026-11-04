# U3 ローカル検証と実行

根拠: [性能設計](../nfr-design/performance-design.md)、[保護設計](../nfr-design/security-design.md)、[論理構成](../nfr-design/logical-components.md)、[機能仕様](../functional-design/functional-spec.md)、[構成要素](../../../inception/domain-design/components.md)、[契約](../../../inception/contract-design/contract-summary.md)。[CI省略](../../../change-decisions/2026-10-31-local-verification.md)を適用する。

## 順序

1. 現在のU1/U2の検証結果を基準に、U3専用hostless XCTestターゲットを準備する。
2. TDDで操作・表示・資源管理と保存完了競合を実装する。測定補助の型と時刻対応を先に確認する。
3. 全既存試験とU3を実行し、全製品Swiftの加重行80%以上を維持する。
4. 実機のキーボード/VoiceOver/幅/実画面性能を本人確認し、実結果または未確認理由を記録する。
5. Construction完了時の関連変更をGitへコミットする。配布公開は行わない。

## 検証の境界

| 項目 | 実行方法 | 承認/結果 |
|---|---|---|
| 単体・結合 | XcodeとXCTest、U3専用コマンド | コード計画で具体化 |
| 全体カバレッジ | 全単位の組合せ結果、既存計測器 | 閾値を下げない |
| 現在の最終検証 | bash scripts/verify-phase1.shはU1/U2を選択 | U3追加を含む新しいコマンドは本人の再確認が必要 |
| 本人の実測 | 現行Mac、任意測定と日本語手順 | 自動結果と区別 |
| CI/CD・秘密情報 | 非適用 | CIランナー/クラウド/配布証明書を追加しない |

## 戻し方

検証済みのGit内容へ戻す手順を文書化する。本人の写真や保存原本を削除しない。戻す操作の実行は本人の判断に従い、検証失敗を隠すためにテスト・閾値・原本を変更しない。

