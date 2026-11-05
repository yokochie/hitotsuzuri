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

## 分割CIの確定結果

- 候補`2bd2a1a5f29ca329f615dae7f92f4f1273443ef0`。[実行41936577672](https://github.com/yokochie/hitotsuzuri/actions/runs/41936577672)、native-core job126946432823。
- 23:48:20〜23:50:14 UTCの1分54秒でfailure。Coreは375ケース成功/1ケース失敗（同ケース内のassertion2つが失敗）。native/native-performanceはneedsにより未起動。Core失敗後にUIが続く問題は停止できた。
- 失敗は同じtestDisplayMemoryAndCancellationThirtyTrialsの観測間隔。専用Threadでもmax100.192459ms、baselineもmax100.192459msで50msを満たさない。baseline5.009731秒/105samples、measurement90samples、delta3,817,472B、OS peak66,144,448→69,961,920B、directPeak4,194,304B。メモリ上限超過の観測ではないが、測定品質は未成立。
- 環境はmacOS27.0.1（26A434）、Xcode27.1、arm64、VirtualMac2,1、AC Power。ローカル成功値とは混ぜない。仮想環境が原因だと断定せず、今回のCIで条件が成立しなかった事実を残す。
- 新候補のNative5件、通常UI、性能UI、全体coverageは未実行。旧候補の成功やローカル代表1件で補完しない。

## 旧対応案（本人指定ed903fa6で下記へ変更）

NFRの「CIの性能値は参考で、本人Mac測定の代替ではない」に沿い、正式な実測の合否とCI参照値の取得を分離する。本人Macでは50ms以下/5秒baseline/256MiB・512MiBの条件をそのまま検証し、CIでは取得値と測定の成立/未成立を明示する。未成立値を性能合格へ使わない。予算・取消・期限等の機能検査と、計測品質の判定ロジックはCIでも必須の決定的テストにする。現時点で条件分岐や試験除外を実装したわけではなく、本人の次の判断を待つ。

計測プロセスの稼働条件も調査した。Appleは[process activityでApp Napや処理の延期を制御できる](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/PrioritizeWorkAtTheAppLevel.html)と説明するが、今回の遅延原因がApp Napだという証拠はない。測定中だけのactivity指定は仮説で、OS全体の設定変更や閾値緩和は行っていない。

## 本人Macだけで性能合否を判定する改訂

本人ed903fa6の指定により、CI参照計測も廃止する。native-coreは実時間/実メモリ5件を除く全Core機能、nativeはsmoke・全機能回帰・全製品加重80%を確認し、native-performance jobは削除した。CIで性能区分/無引数全体/性能UIクラスを指定すると起動前に失敗する。決定論的な予算・取消・期限検証は維持する。本人Mac専用--performanceはU1実測3件+U2実測2件、smoke2件、UI性能4件を要求し、従来閾値を変えない。

runner契約は先に16件中4失敗（3.028秒）を確認し、実装後17件が3.184秒で成功。追加した欠落メソッド検査は同じ性能クラス内の他ケースが成功しても未実行を拒否する。これは代替コマンドでの短い検証で、製品テストの成功ではない。

認証後の軽量UI1件は導入文が画面外のままclickされ失敗した。本人45362ce6の修正承認に基づき、既存のフォームスクロール・viewport内・isHittable確認を適用し、保存前の本文実値も検査。U2-Lightweight-Loading-Reveal-20261105-091200.xcresultは1成功/0失敗/0skip、UI25.109秒、exit0。CIとMac性能の新候補結果はこれから確認する。
