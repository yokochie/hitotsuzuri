<!-- INVARIANT: examples are single-line HTML comments so a fresh template parses to total=0 (MEMORY_EMPTY). Do NOT un-comment or split across lines. t100 guards this. -->
> This file is kept up to date automatically while the stage runs. Add observations at the review step, not by editing here directly.

## Interpretations

- 2026-11-02 [unit u3-native-experience] — 本人承認9304abf3によりLoop-back 2のStep27〜33を開始。実アプリへのキー/修飾クリックを通すUI試験で入力経路を検証し、計算モデルの成功を実操作の代替としない。合成fixtureはDebug限定かつ個人データに触れない。

- 2026-11-01T03:02:00Z [unit u3-native-experience] — 本人承認済み21ステップの実装を開始。保存成功と認可/取消の競合を先に実Redで固定し、画面操作と任意の実画面計測を同じ既存責務の範囲で完成させる。本人のOS許可・VoiceOver・実Photosは自動試験と分離する。

- 2026-11-01T02:07:00Z [unit u2-session-reliability] — 本人が実装計画を承認したため、U1の基準試験とU2専用runnerの準備を先に確認してTDDへ進む。通常診断は失敗分類だけとし、復元状態はUIに限って扱う。

- 2026-10-31T07:41:58Z [unit u1-integrated-selection] — 本人が16ステップの実装計画を承認した。Testing Contractは生成結果を改変せず保持し、本人承認のCI省略はintent限定の変更記録に従ってローカル検証へ置換する。TDDと80%以上の条件は維持する。製品コードの担当を開発担当へ委ね、本人の写真アクセス確認は未実施と区別する。
<!-- example: 2026-05-29T10:14:32Z — chose REST over GraphQL; the consuming team only needs CRUD, revisit if subscriptions land -->

## Deviations
<!-- example: 2026-05-29T10:14:32Z — skipped the optional caching layer the stage prose suggested; the dataset is small enough that it adds risk -->

## Tradeoffs

- 2026-10-31T08:11:12Z [unit u1-integrated-selection] — 開発担当の最終結果は49件成功・失敗0、全製品Swift655/807行=81.16%。ブートストラップ用テストの削除で途中50件から最終49件となった。UIをCoreのPickerContentへ分けてテスト可能にし、View・実アダプターをカバレッジ分母から除かずに達成した。実ライブラリと最終検証スクリプトの本人承認は未実施と区別する。
<!-- example: 2026-05-29T10:14:32Z — picked TDD over BDD this run; the team is unit-first and the domain is well-understood -->

## Open questions
<!-- example: 2026-05-29T10:14:32Z — confirm the retention window with compliance before the next stage hardens the schema -->
