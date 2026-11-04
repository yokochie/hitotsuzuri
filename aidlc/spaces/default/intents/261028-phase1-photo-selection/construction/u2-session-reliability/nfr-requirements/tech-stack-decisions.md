# U2 tech-stack-decisions

根拠: [機能仕様](../functional-design/functional-spec.md)、[ルール](../functional-design/rules.md)、[要件](../../../inception/requirements-analysis/requirements.md)、[契約](../../../inception/contract-design/contract-summary.md)、[CI省略](../../../change-decisions/2026-10-31-local-verification.md)。本書は要求であり動作確認結果ではない。

| ID | 条件 | 検証 |
|---|---|---|
| NFR1.21 | 既存SwiftUI/macOSアプリと5責務・C1〜C4へ追加し、別DB・外部依存・サービスを追加しない | 導入済みXcode/Swift6でビルド、U1互換の版1形式を継続 |

既決の条件を維持するため、追加の製品質問はない。具体的な実行境界・退避方式・テスト構成を次の技術設計で決める。本人のMacだけを対象とし、クラウドのSLA・水平拡張・遠隔監視は非該当。復元UIの完成条件をU3の最終操作支援と混同しない。

