# U2 CI検証記録

## 実行準備

- 作業ブランチ: `codex/phase2-u2-draft-experience`。承認済みU1の現在の作業ツリーを保持して分岐した。main統合・配布は行わない。
- 本人の公開コード/試験push承認と、U2の承認済みコード計画Step17に基づく。
- 新しいスクリプトの無引数はsmoke→全4target→単一主bundleの製品加重カバレッジ80%以上。部分実行の結果は全体合格に置き換えない。
- workflowは通常・性能・全体の区分を持つ。全体を指定すると通常/性能ジョブは同時に重複起動しない。旧U1ブランチのbaseline-native診断は保持する。
- GitHubのdefault branchはmainだが、2026-11-05時点のmainに`.github/workflows/`は存在しなかった。手動実行はworkflowがdefault branchに必要なため、統合前にも全体検証できるよう、commit messageの`[verify-all]`を明示指定したpushでもnative-allを選べるようにした。これは試験をskipする指定ではなく、全体の試験/カバレッジを一度だけ実行する選択である。
- 上記の手動実行条件は[GitHub公式説明](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow?tool=webui)で確認。新YAMLはRuby標準YAMLで構文読取成功。GitHub上での実行成功とは別である。

## 確定結果

U2候補`771d101fbb6be38a76b84d1a422bf5a1b29598b2`をcommit/pushした。[全体CI実行41928800409](https://github.com/yokochie/hitotsuzuri/actions/runs/41928800409)のnative-all（job126920116908）は約30分でcancelledとなった。timeout-minutesは30。ログでは23:21:13 UTCに取り消しを確認し、workflowは23:21:20 UTCに完了。APIの確定値はcancelledであり、全体合格ではない。全体を指定したためnative/native-performanceは重複起動せず、旧U1ブランチ専用baselineも対象外。

実行中ログはGitHub側で未提供だったため、終了後にjob logを取得して確認した。xcresultの最終summaryではなく、確定した各Test Caseのログから以下を集計した。

| 群 | 成功 | 失敗 | 状況 |
|---|---:|---:|---|
| 起動smoke | 2 | 0 | 記事/Picker、回収まで成功 |
| Core U1 | 154 | 0 | 完了 |
| Core U2 | 150 | 1 | メモリ計測サンプル間隔の検査失敗 |
| Core U3 | 71 | 0 | 完了 |
| U2詳細性能UI | 3 | 0 | 完了、771.132秒 |
| U2通常UI | 24 | 0 | 完了、532.871秒 |
| 既存記事UI | 6 | 0 | 完了、87.147秒 |
| 既存NativeInput UI | 12 | 5 | 1件が実行途中で中断、8件は未開始 |

完成したケースは合計422成功/6失敗。途中1件と未開始8件は成功/skipへ置き換えない。製品全体の加重カバレッジ検査は後段へ進まず未実行。CI成功と80%条件は未達のまま。

### Coreの失敗

`ArticlePreviewRetryTests/testDisplayMemoryAndCancellationThirtyTrials`の78行。最大観測間隔0.107867292秒が要求0.05秒を超えた。これはサンプリング品質の失敗であり、メモリ512MiB超過を観測した失敗ではない。baselineMedian65,784,000B、samplePeak69,617,856B、delta3,833,856B、OS peak65,784,000→69,634,240B、39samples、directPeak4,194,304B。閾値を緩めたり、欠けた観測を合格扱いしたりしない。

### 既存NativeInputの失敗

- testAlbumArrowsInCompactAfterMouseSelectionFollowPhotos: 87行、アルバム写真枚数4枚への追随待ち。
- testCompactAlbumTabCanActivateEnabledConfirm: compactWithFourSelectedの8行、4枚選択の前提。
- testCompactConfirmShiftTabReturnsToAlbumRow: 同じ前提。
- testCompactPhotoTabCanActivateEnabledConfirm: 同じ前提。
- testCompactPhotoTabConfirmAndShiftTabReturnCanSave: 同じ前提。

`testPhotoTabWithEnabledConfirmCanSaveBySpace`は開始後に中断し、結果なし。残る8件も未実行。ローカルのWindow不在とは異なり、今回smokeと既存記事UI6件は成功している。旧CIの同名失敗と同じ原因だとは断定せず、入力/焦点/選択の段階を限定して調べる。

### 実行構成の未解決点

Core失敗は22:53台に出ていたが、単一xcodebuildは後続UIを実行し続けた。今回の分離ではCore失敗時の早期停止が不十分だった。全体をそのまま再実行せず、Core先行の停止条件と、通常/性能CIを分けた検証・全製品カバレッジ判定の構成を見直す。これは今後の修正案であり、まだ実装していない。

最後に確認済みの[旧U1候補の実行](https://github.com/yokochie/hitotsuzuri/actions/runs/41798035585)は失敗している。U2の限定ローカル成功からCIの成功を推定しない。

公開対象はsource-manifestに列挙するコード/試験と、このUnitの関連記録に限定する。本人のscheme変更、Phase1 audit、未追跡のハーネス設定等をまとめてstageしない。

## Retry38d447b5後の分割候補

- native-core（15分上限）で全3Core targetを実行し、失敗なら両UI jobを起動しない。
- nativeはその成功後に全Core機能+全機能UIと、単一主bundleから全製品sourceの加重80%を判定する。先行Coreで必須実行済みのU2 Core性能2件だけ重複させない。
- native-performanceもCore成功後に起動し、UI性能3件とsmokeを実行する。両UIジョブは別runnerであり、どちらも成功が必要。Coreに含む性能2件も必須で、性能の率をcoverageへ平均・合算しない。
- CI依存確認済み環境のHZS_CORE_PREFLIGHT_DONEは先行Coreの重複を省く印。主bundleのCore機能は実行し、ローカルの無引数全体は省略を使わない。14件の短いrunner契約が成功。
- メモリsamplerはプロセス内の専用Thread/10msへ変更し、5秒baseline・50ms以下の実観測間隔等を維持。ローカル限定1件が成功し最大間隔14.918ms。CIでの成立はまだ確認していない。
- Nativeは各入力の論理焦点・選択数・slotを検査するようにした。代表1件はローカル成功、残4件の解消は未確認。診断表示をレイアウト中立のoverlayへ移した最終候補はCIで確認する。製品の焦点意味は変更せず、既存期待を緩めていない。
- 候補の新commit/push・分割CIの結果はこの時点では未取得。旧771d101の取り消しを新候補の成功に置き換えない。
