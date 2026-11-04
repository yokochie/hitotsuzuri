# U2 論理境界

根拠: [性能](../nfr-requirements/performance-requirements.md)、[保護](../nfr-requirements/security-requirements.md)、[容量](../nfr-requirements/scalability-requirements.md)、[信頼性](../nfr-requirements/reliability-requirements.md)、[診断](../nfr-requirements/observability-requirements.md)、[技術選定](../nfr-requirements/tech-stack-decisions.md)、[機能仕様](../functional-design/functional-spec.md)、[契約](../../../inception/contract-design/contract-summary.md)。CIは[本人の変更決定](../../../change-decisions/2026-10-31-local-verification.md)により省略。以下は設計であり未実装。

## L21 既存構成への増分

対応NFR1.21。既存Swift6/macOSアプリへ追加し、外部DB・パッケージ・クラウドは追加しない。LibraryAccessは認可と現在参照、ImageAccessは絶対期限付きローカル画像と寿命予算、SelectionPersistenceは読込/退避/置換、SelectionWorkflowは復元/編集/確定判断、PickerPresentationは状態表示を担当する。

| 境界 | U2で増えるもの | 所有者 |
|---|---|---|
| C1 | restoreStateと原因別案内、二段階復元の一括公開 | SelectionWorkflow |
| C2 | 復元時の現参照検証の利用 | LibraryAccess |
| C3 | 復元4枚の共通期限と全成功条件の利用 | ImageAccess |
| C4 | 正常/破損/未知版/I/Oの読込結果、明示的再確定での退避後置換 | SelectionPersistence |

状態更新はMainActor、ファイルI/Oと探索は既存のバックグラウンド直列境界。非Sendableなプラットフォームオブジェクトを無根拠に境界越しに渡さない。保存形式の既存必須項目と版は互換のまま。退避許可の意図と原本bytes照合の意味を内部APIへ明示し、UIから任意パスを渡さない。具体型と失敗注入の接続はコード生成計画で定める。

