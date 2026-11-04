<!-- INVARIANT: examples are single-line HTML comments so a fresh template parses to total=0 (MEMORY_EMPTY). Do NOT un-comment or split across lines. t100 guards this. -->
> This file is kept up to date automatically while the stage runs. Add observations at the review step, not by editing here directly.

## Interpretations

- 2026-11-01T02:58:00Z [unit u3-native-experience] — 既存ローカル環境を維持し、SDKヘッダの表示済みフレーム時刻を測定候補として確認した。実計測とOS許可は未確認であり、U3を含む最終コマンドは本人の再確認を必要とする。

- 2026-11-01T01:53:57Z [unit u2-session-reliability] — 既存ローカル環境を継続し、専用領域の破損退避とU2を含む検証だけを追加する。既存U1専用の承認コマンドではU2を検証できないため、変更時の本人承認を計画に明記した。

- 2026-10-31T06:53:34Z [unit u1-integrated-selection] — 本人はCI省略と統合前ローカル検証への変更を承認した。ci-pipelineだけを省く再計画を適用し、旧成果物を保存して現行文書に変更注記を追加した。TDD・80%以上・実機確認は維持する。今回のintent限定の変更として記録し、他作業の共有規約を変更していない。
<!-- example: 2026-05-29T10:14:32Z — chose REST over GraphQL; the consuming team only needs CRUD, revisit if subscriptions land -->

## Deviations
<!-- example: 2026-05-29T10:14:32Z — skipped the optional caching layer the stage prose suggested; the dataset is small enough that it adds risk -->

## Tradeoffs

- 2026-10-31T07:40:46Z [unit u1-integrated-selection] — CI省略後も各単位の統合前ローカル検証を必須とし、具体コマンドの本人確認を未承認のまま代替しない。ローカル署名はad-hocを第一候補とし、Sandboxと写真権限の実機成立性はコード生成後に確認する。公開配布や有料証明書の準備は追加しない。
<!-- example: 2026-05-29T10:14:32Z — picked TDD over BDD this run; the team is unit-first and the domain is well-understood -->

## Open questions
<!-- example: 2026-05-29T10:14:32Z — confirm the retention window with compliance before the next stage hardens the schema -->
