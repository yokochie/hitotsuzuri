# U2 並行性と容量

根拠: [性能](../nfr-requirements/performance-requirements.md)、[保護](../nfr-requirements/security-requirements.md)、[容量](../nfr-requirements/scalability-requirements.md)、[信頼性](../nfr-requirements/reliability-requirements.md)、[診断](../nfr-requirements/observability-requirements.md)、[技術選定](../nfr-requirements/tech-stack-decisions.md)、[機能仕様](../functional-design/functional-spec.md)、[契約](../../../inception/contract-design/contract-summary.md)。CIは[本人の変更決定](../../../change-decisions/2026-10-31-local-verification.md)により省略。以下は設計であり未実装。

## C21 単一復元セッション

対応NFR2.24、NFR3.24。SelectionWorkflowが復元操作IDと世代を発行する。二重startは同じ起動処理を再入させず、既存の進行完了を待つ。開始し直す必要がある場合は旧世代の画像を取消してから新世代を発行する。復元中は編集を受けず、遅延結果は現世代と一致するものだけ採用する。

設定/確定の読込・退避・置換はSelectionPersistenceの直列境界。1件の退避と置換を別処理から割り込ませない。画像予算はP21を共用。退避は同じ原本ごとに1ファイル、破損内容が異なる場合は別原本として保護するが、無制限の自動再試行/自動退避はしない。本人の新規確定以外では増えない。保存フォルダの全ファイルを起動時に列挙せず、固定の正常レコードだけを読む。

