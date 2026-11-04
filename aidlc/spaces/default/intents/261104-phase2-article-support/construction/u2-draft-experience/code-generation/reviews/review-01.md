## Review

**Reviewer:** aidlc-architecture-reviewer-agent
**Verdict:** NOT-READY
**Iteration:** 1
**Date:** 2026-11-04T21:45:45Z
**Verdict Dictated:** no

### Findings

| ID | Severity | Location | Finding | Required action | Status |
|---|---|---|---|---|---|
| R-01 | Major | Hitotsuzuri/ArticleView.swift > bodyのTab処理・moveFocus・photos | 親ViewでTab/Shift-Tabを捕捉し、focusedFieldが既知なら固定配列内を循環する。その配列には「写真1〜4を再試行」がなく、各再試行ボタンにも同じFocusStateとの結合がない。タイトル等からキーボード移動を始めると、本文・撮影情報・既存操作の輪を回り続け、表示写真の再試行へ到達できない。NFR4.22と番号別再試行を組み合わせた操作を満たさない。現UI試験の再試行はマウスクリックであり、この経路を確認していない。 | 利用可能な番号別再試行を焦点順序・画面内スクロール・キー実行へ含めるか、標準の焦点移動を妨げない構成へ変更する。写真取得不能時にTab/Shift-Tabだけで各再試行へ到達し、Space等で実行して文章を保持する限定UI試験を追加する。 | New |
| R-02 | Major | HitotsuzuriU2Tests/ArticleDraftTestDoubles.swift > DraftFixtures.root、およびHitotsuzuriUITests/ArticleDraftUITests.swift > launch、Hitotsuzuri/DebugFixture.swift > performance fixture | CoreはUUIDごとの.build/article-tests領域、UIは起動ごとのArticleFixture-draft領域を生成するが、試験所有領域の終了時回収がない。性能fixtureは100記事と長文の1000操作を生成し、通常の専用コマンドにも含まれるため、反復ごとに大きな保存物が残る。code-summaryには容量枯渇のexit73と、本人判断で115 fixture/72 bundleを削除した事実がある。容量不足の全原因をこのコードだけとは断定しないが、現在のfixture生成には累積を止める仕組みがない。 | 承認された通常/性能分離と合わせて、試験が所有するrootの追跡・成功/失敗/取消後の安全な回収方針を実装する。失敗証拠を残す場合は保持範囲/上限を決め、性能fixtureを不要に再生成しない。本人データへ触れず、複数回の限定試験で残存量が無制限に増えないことを確認する。 | New |
| R-03 | Major | aidlc/spaces/default/intents/261104-phase2-article-support/construction/u2-draft-experience/code-generation/code-summary.md > 検証の現在地・全体回帰 | 専用128件は成功しているが、現候補を組み合わせた全体回帰では既存記事UI6件と写真選択UI7件がWindow存在確認で失敗し、さらに1件取消・18件未実行となっている。既存xcresultも401成功/14失敗を示す。起動障害を切り分けた全体回帰成功、現在の製品全体80%以上、現在差分のCI成功はまだ得られていない。起動失敗の原因は未確定であり、既知のNativeキー失敗と同一原因として免除できない。 | 承認された計画改訂を先に反映し、起動smokeと限定した失敗経路からWindow不在の原因と新規回帰の有無を切り分ける。通常/性能・Core/UIの責務を整理した後に必要な全体回帰、全製品カバレッジ、現在差分のCIを確認する。対象除外や過去の専用成功で未実行を合格へ置き換えない。 | New |

### Validation Tool Results

| Tool | Result | Interpretation |
|---|---|---|
| bash scripts/verify-draft-experience.sh | 今回は未実行 | 人が長時間反復の見直しを承認し、起動smoke先行・通常/性能分離等の計画改訂前の長時間再実行を保留する指示があるため。過去結果を新実行として記載していない。 |
| bash scripts/verify-native.sh | 今回は未実行 | 同じ保留指示による。再実行を保留した事実そのものをNOT-READYの理由にはしていない。 |
| 既存専用bundleのxcresulttool summary読取 | .build/Draft-20261105-054710-2230.xcresult：Passed、128成功、失敗0、skip0 | 既存のCore103＋UI25成功を確認。新しい実行ではなく、全体回帰/CIの成功証拠へ拡張しない。 |
| 既存全体bundleのxcresulttool summary読取 | .build/Native-20261105-060746-8142.xcresult：Failed、401成功、14失敗 | 既存のCore376＋追加UI25成功と、Window不在等の失敗/取消を区別。残る18未実行はcode-summaryの記録であり、このsummaryのskip0を「全件実行済み」と解釈しない。 |
| 静的差分・成果物確認 | manifestの33パス、共有境界の変更、入力/保存/関連付け/投影/表示/操作接続と試験を確認 | 元操作の不確定状態保持、raw日付のdirty、Unicodeのbyte保持、記事ID付き投影、旧投影の不採用/待機解除は具体化されている。上記のキー到達・fixture寿命・全体検証に残る問題を記録した。 |
| bash -nおよびRubyによる追加静的検査 | PreToolUse hookがdirective kind askからworkspace mutationの承認対象を選べないとして拒否。未実行 | 構文検査/JSON検査のPASSとは記録しない。拒否を回避するライフサイクル操作や成果物変更は行っていない。書面と通常の読取結果に基づく確認とは区別する。 |

### Summary

専用128件の成功と保存・投影等の実装改善は確認した。一方で、番号別再試行のキー到達、大量fixtureの寿命管理、全体回帰で観測された起動失敗と残る品質検証にMajor3件があり、現状はNOT-READYと判断する。次の作業は人が承認したテスト計画改訂を起点とする。
