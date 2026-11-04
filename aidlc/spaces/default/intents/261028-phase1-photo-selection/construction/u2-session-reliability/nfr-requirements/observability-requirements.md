# U2 observability-requirements

根拠: [機能仕様](../functional-design/functional-spec.md)、[ルール](../functional-design/rules.md)、[要件](../../../inception/requirements-analysis/requirements.md)、[契約](../../../inception/contract-design/contract-summary.md)、[CI省略](../../../change-decisions/2026-10-31-local-verification.md)。本書は要求であり動作確認結果ではない。

| ID | 条件 | 検証 |
|---|---|---|
| NFR5.21 | TDD・製品全体行カバレッジ80%以上・統合前ローカルビルド/自動テストを維持する。CIは省略済み | U2専用テストと全単位テストで対象/コミット/結果を記録 |
| NFR5.22 | 診断は失敗分類のみ。本人の保存/再起動/欠損確認と自動検証を区別し、未確認を成功にしない | 日本語手順・未確認欄・匿名指標。個人ID/名称/画像なし |

既決の条件を維持するため、追加の製品質問はない。具体的な実行境界・退避方式・テスト構成を次の技術設計で決める。本人のMacだけを対象とし、クラウドのSLA・水平拡張・遠隔監視は非該当。復元UIの完成条件をU3の最終操作支援と混同しない。

