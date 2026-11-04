# U3 技術・検証方針

根拠: [機能仕様](../functional-design/functional-spec.md)、[規則](../functional-design/rules.md)、[要件](../../../inception/requirements-analysis/requirements.md)、[契約](../../../inception/contract-design/contract-summary.md)。[CI省略](../../../change-decisions/2026-10-31-local-verification.md)を適用し統合前ローカル検証を維持する。未測定を合格としない。

## 継続する構成

| ID | 方針 | 根拠 |
|---|---|---|
| NFR1.31 | 既存Swift6/SwiftUI/PhotoKit、本人Mac、既存5責務とC1〜C4を維持 | 表示のために所有者・保存形式・外部依存を増やさない |
| NFR5.32 | 各層TDD、全製品行カバレッジ80%以上、全既存回帰とU3のUI/状態/資源試験 | 統合前ローカルで確認、UI/アダプタも分母 |
| NFR5.33 | 日本語のXcode中心手順と本人確認表、実OS/画面幅/入力/VoiceOver/測定結果を記録 | 自動試験・本人観察・未確認を分離 |

## 非適用と依存

サーバーの台数増加・分散トレース・稼働率SLAは非適用。画像要求数と生存予算はNFR2.32〜2.34、画面信頼性はNFR3.32へ集約する。UI状態とフォーカスの実装は既存表示担当へ追加する。通常診断の最小化はNFR5.31。実画面のタイミングを計測できるかを実装前に検証し、測定不能を合格へ読み替えない。

