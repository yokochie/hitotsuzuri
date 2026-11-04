<!-- INVARIANT: examples are single-line HTML comments so a fresh template parses to total=0 (MEMORY_EMPTY). Do NOT un-comment or split across lines. t100 guards this. -->
> This file is kept up to date automatically while the stage runs. Add observations at the review step, not by editing here directly.

## Interpretations

- 2026-11-01T03:51:00Z — Loop-back 1の修正後は全176件と85.95%が成功し、不変操作の合格問題を解消した。残る実機対象は本人の観察が必要なため、未確認を合格へ置換せず、まず起動・許可・保存・再起動復元の結果を受け取る。
<!-- example: 2026-05-29T10:14:32Z — chose REST over GraphQL; the consuming team only needs CRUD, revisit if subscriptions land -->

## Deviations

- 2026-11-02 — 本人3fc70abcが入力3操作の成功と静的見出しへの不要なTab停止を報告。Loop-back 3でU3のみ再開し、VoiceOverの見出しを保持してキーボード停止先を整理する。追加費用0、小規模20〜40分。既知の子折畳み問題と他単位は維持する。

- 2026-11-02 [本人確認] — フォルダの左右キー展開・Command複数選択・写真キーボード選択が失敗したと本人が報告。実入力経路を通さない既存試験の限界を認め、Loop-back 2としてU3の実UI入力回帰と接続修正へ戻す。基本保存/復元の成功は保持する。

- 2026-11-01T03:34:00Z — 既存159件は成功したが、不変選択30回で性能判定が合格になる公開境界プローブが期待違反となった。U3だけの測定入口/モデル/回帰テストを小規模に是正する再実装へ戻し、他単位と実機未確認の基準を維持する。
<!-- example: 2026-05-29T10:14:32Z — skipped the optional caching layer the stage prose suggested; the dataset is small enough that it adds risk -->

## Tradeoffs

- 2026-11-03T16:03:06Z — 本人9f8f65c4が実測の200ms速度未達を残し承認確認へ進むことを選択。Not Metを維持し、資源10往復のMetと分離する。他のUnverifiedと横断追跡FAILも提示し、今回の回答を全体承認へ拡張しない。
<!-- example: 2026-05-29T10:14:32Z — picked TDD over BDD this run; the team is unit-first and the domain is well-understood -->

## Open questions
<!-- example: 2026-05-29T10:14:32Z — confirm the retention window with compliance before the next stage hardens the schema -->
