# Test Results

## 候補と実行方針
2026-11-05、候補4a3b71d1e15795fedcba4e8a808addfff3ef2308。本人のCI優先方針e97e172fと確認コマンド承認0c6f9332に基づく。UI認証を必要とするローカル実行を増やさず、既に実行した同一ソースのCI証拠を使う。全体の新しいCI runも起動していない。

## この段階で実行した確認
`bash aidlc/spaces/default/intents/261104-phase2-article-support/verification-command.txt`：exit0、0.649秒。stdout: Run Verify native application (41994393925) has already completed with 'success'。ファイルの承認済み1行はHEADの固定SHA、指定した製品/試験/runner/workflow差分なし、CI終了成功を確認する。これは新たな517件の試験実行ではない。

GitHub jobログをこの段階で再取得し、run headSha/attempt2/conclusion successも独立に読取確認した。主bundleはCI runner上にあり、ローカルに取得・再解析したとは主張しない。

## Build / Unit / Integration / UI
| 実コマンドと場所 | 結果 | 証拠 |
|---|---|---|
| python3 scripts/test-native-runner.py / CI native-core | 28件、4.161秒、OK | job127135410554 |
| bash scripts/verify-native.sh --core / CI native-core | Core454件実行成功、0skip、exit0 | 同job、08:30:55Zの実行済み検査 |
| bash scripts/verify-native.sh --functional / CI native | xcodebuildがApp/Core/全試験をビルド、別smoke2件成功、主bundle517件成功、0skip、exit0 | job127136138800、08:54:49Z |
| 既存check-coverage.swift / 同じ主bundle | 5227/5739=91.08%、80%達成、exit0 | 同job08:54:58Z |

517件はCore454+UI63であり、先行Core454を足して971件としない。smoke2は別bundle。旧CIの失敗や今回取消した重複runを成功に数えない。正式主bundleは.build/Native-functional-20261105-083248-9aaa1089704348aeb6e60aee5962f25e.xcresult、smokeは.build/Smoke-20261105-083111-a2676144b5ab43af9078f84e0406b6ca.xcresult（ともにCI runner上）。OS macOS27.0.1/Xcode27.1。

## 過去の限定/実機証拠
同候補の固定コピー診断CI41994394083は1件成功、実マウス→固定本文、22Tab→focus→Space二回目、dirty保持/後続未保存本文非混入を確認。本人5fc4a689のローカル再試行も同候補1件成功0skip、39.816秒。これらを現在の全体CIの代用にせず、追加のローカル再実行もしていない。

U1/U2のMac性能はaidlc/spaces/default/intents/261104-phase2-article-support/construction/u2-draft-experience/code-generation/tdd-evidence.mdのCore5件/実UI4件を使用する。U3はaidlc/spaces/default/intents/261104-phase2-article-support/construction/u3-article-export/code-generation/performance-evidence.mdの正常四枚30回p95 1.001353625秒と、片付け修正後メモリ/取消1件の更新を使用する。Mac15,3/M3/16GB/macOS27.2/Xcode27.2、AC観測。各bundle・全試行・baseline/間隔・未測定の範囲は原記録を保持する。性能sourceが変わっていないものを今回再測定したとはしない。

## Target Verification Matrix
最終全76項目はbuild-and-test-summary.mdの表を正とする。{"Met":53,"Not Met":1,"Unverified":19,"N/A":3}。Unverifiedの根拠は実写真/実権限/手動受渡し、最小高さ、実描画時刻、一枚工程実時間、実中断と初期TDD証拠。UI/制御の成功を異なる実証へ読み替えない。

## Cross-Unit Coverage
sensor-traceability --stage build-and-testはpass=false、62行、未対応10ID（FR12/FR15/FR18/NFR2/NFR3/NFR4/NFR5/NFR6/NFR7/AC1.8.4）。cross-unit-traceability.mdに全行・所有・対象を記録した。U1の過去のGAPを含む元対応表は凍結を保持し、単に合格へ変更しない。

## 診断と残る確認
機能コマンドの新規失敗はない。総合判定を止めるのは適用目標の証拠不足と対応表GAP。本人の私的写真・実Sandbox/Finder/note、最小高さ、取消描画/一枚工程を一度の実機確認へまとめる。U1初期TDDの不足は実装後に架空のRedを追加して修復できず、履歴上の制約として残る。

## 影響の評価
現時点で自動のコード変更候補はない。新しいOS/TCC/認証変更やテスト閾値低下で不足を隠さない。手動確認を行う場合は本人の時間と試験用出力先が必要で、外部有料費用は不要、既存写真/下書き/完成物を保護する。実施時間は素材/環境に依存し未確定。コード/選択approach起因の識別可能な修正がないため自動loop-backは行わない。Loop-back使用0/3。

## 最終状態
自動機能とcoverageは成功、Build and Testの総合判定は未達/確認待ち。本人a861c7f7はAccept failureを選択し、未確認項目と未達判定を保持したまま後続CI Pipelineへ進むことを了承した。未確認をMetへ変更せず、main統合/配布を完了したとはしない。
