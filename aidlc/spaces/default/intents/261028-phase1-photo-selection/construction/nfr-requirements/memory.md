<!-- INVARIANT: examples are single-line HTML comments so a fresh template parses to total=0 (MEMORY_EMPTY). Do NOT un-comment or split across lines. t100 guards this. -->
> This file is kept up to date automatically while the stage runs. Add observations at the review step, not by editing here directly.

## Interpretations

- 2026-11-01T02:54:00Z [unit u3-native-experience] — UI単位の非機能条件を性能・操作支援・原本保護・検証の3文書へ具体化した。実画面の200msと資源安定の未測定を明示し、内部状態更新だけで代用しない。

- 2026-11-01T01:53:57Z [unit u2-session-reliability] — 既決の画像期限・予算と原本保護を復元へ適用し、15詳細要件へ整理した。CIは省略済みのため統合前ローカル検証を適用し、本人確認と自動試験を分離する。

- 2026-10-31T06:40:37Z [unit u1-integrated-selection] — 本人は画像待機15秒、画像保持256 MiB、最小限の診断を選択し、要約を確認した。待機は1要求と4枚検証全体の両方へ適用し、認可回答待ちと保存処理は除外する。
<!-- example: 2026-05-29T10:14:32Z — chose REST over GraphQL; the consuming team only needs CRUD, revisit if subscriptions land -->

## Deviations
<!-- example: 2026-05-29T10:14:32Z — skipped the optional caching layer the stage prose suggested; the dataset is small enough that it adds risk -->

## Tradeoffs

- 2026-10-31T06:40:37Z [unit u1-integrated-selection] — アプリ管理の画像バッファの保持予算とOS内部・プロセス全体の使用量を区別する。性能の最終実測はU3に残すが、U1の取消・期限・予算制御を省略しない。導入済みツールはXcode27.2/Swift6.4.2を新たに観測した。
<!-- example: 2026-05-29T10:14:32Z — picked TDD over BDD this run; the team is unit-first and the domain is well-understood -->

## Open questions
<!-- example: 2026-05-29T10:14:32Z — confirm the retention window with compliance before the next stage hardens the schema -->
