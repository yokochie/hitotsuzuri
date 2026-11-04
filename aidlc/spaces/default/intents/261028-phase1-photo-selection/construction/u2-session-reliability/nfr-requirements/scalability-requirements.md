# U2 scalability-requirements

根拠: [機能仕様](../functional-design/functional-spec.md)、[ルール](../functional-design/rules.md)、[要件](../../../inception/requirements-analysis/requirements.md)、[契約](../../../inception/contract-design/contract-summary.md)、[CI省略](../../../change-decisions/2026-10-31-local-verification.md)。本書は要求であり動作確認結果ではない。

| ID | 条件 | 検証 |
|---|---|---|
| NFR2.24 | 復元と確定は単一セッションで競合させず、書込みは1件ずつ。古い世代の復元結果を採用しない | 遅延応答・重複開始・切替/取消のテスト |
| NFR3.24 | 破損退避は同じ原本bytesに対し重複を増やさず、1 MiBの既存読込/保存上限を維持 | 反復失敗/再試行で同一内容の退避再利用と過大入力拒否を確認 |

既決の条件を維持するため、追加の製品質問はない。具体的な実行境界・退避方式・テスト構成を次の技術設計で決める。本人のMacだけを対象とし、クラウドのSLA・水平拡張・遠隔監視は非該当。復元UIの完成条件をU3の最終操作支援と混同しない。

