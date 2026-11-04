## Review

**Reviewer:** aidlc-architecture-reviewer-agent
**Verdict:** NOT-READY
**Iteration:** 2
**Date:** 2026-11-04T21:53:17Z
**Verdict Dictated:** no

### Findings

| ID | Severity | Location | Finding | Required action | Status |
|---|---|---|---|---|---|
| R-01 | Major | Hitotsuzuri/ArticleView.swift > bodyのTab処理・moveFocus・photos | 親ViewでTab/Shift-Tabを捕捉し、focusedFieldが既知なら固定配列内を循環する。その配列には「写真1〜4を再試行」がなく、各再試行ボタンにも同じFocusStateとの結合がない。タイトル等からキーボード移動を始めると、本文・撮影情報・既存操作の輪を回り続け、表示写真の再試行へ到達できない。NFR4.22と番号別再試行を組み合わせた操作を満たさない。現UI試験の再試行はマウスクリックであり、この経路を確認していない。 | 利用可能な番号別再試行を焦点順序・画面内スクロール・キー実行へ含めるか、標準の焦点移動を妨げない構成へ変更する。写真取得不能時にTab/Shift-Tabだけで各再試行へ到達し、Space等で実行して文章を保持する限定UI試験を追加する。 | Unresolved |
| R-02 | Major | HitotsuzuriU2Tests/ArticleDraftTestDoubles.swift > DraftFixtures.root、およびHitotsuzuriUITests/ArticleDraftUITests.swift > launch、Hitotsuzuri/DebugFixture.swift > performance fixture | CoreはUUIDごとの.build/article-tests領域、UIは起動ごとのArticleFixture-draft領域を生成するが、試験所有領域の終了時回収がない。性能fixtureは100記事と長文の1000操作を生成し、通常の専用コマンドにも含まれるため、反復ごとに大きな保存物が残る。code-summaryには容量枯渇のexit73と、本人判断で115 fixture/72 bundleを削除した事実がある。容量不足の全原因をこのコードだけとは断定しないが、現在のfixture生成には累積を止める仕組みがない。 | 承認された通常/性能分離と合わせて、試験が所有するrootの追跡・成功/失敗/取消後の安全な回収方針を実装する。失敗証拠を残す場合は保持範囲/上限を決め、性能fixtureを不要に再生成しない。本人データへ触れず、複数回の限定試験で残存量が無制限に増えないことを確認する。 | Unresolved |
| R-03 | Major | aidlc/spaces/default/intents/261104-phase2-article-support/construction/u2-draft-experience/code-generation/code-summary.md > 検証の現在地・全体回帰 | 専用128件は成功しているが、現候補を組み合わせた全体回帰では既存記事UI6件と写真選択UI7件がWindow存在確認で失敗し、さらに1件取消・18件未実行となっている。既存xcresultも401成功/14失敗を示す。起動障害を切り分けた全体回帰成功、現在の製品全体80%以上、現在差分のCI成功はまだ得られていない。起動失敗の原因は未確定であり、既知のNativeキー失敗と同一原因として免除できない。 | 承認された計画改訂を先に反映し、起動smokeと限定した失敗経路からWindow不在の原因と新規回帰の有無を切り分ける。通常/性能・Core/UIの責務を整理した後に必要な全体回帰、全製品カバレッジ、現在差分のCIを確認する。対象除外や過去の専用成功で未実行を合格へ置き換えない。 | Unresolved |

> R-01 Reviewer note: ArticleViewの手動Tab循環は引き続きarticle-probe/back/mode/saveまでで、番号別article-retryを含まない。再試行ボタンの焦点結合・キー実行と限定UI確認は未反映。計画追記だけでは操作上の問題は解消していない。

> R-02 Reviewer note: 新しい計画には通常/性能分離とテスト所有rootの終了時回収が明記されたが、現在のUI試験はUUID rootを生成するままで回収処理がない。Coreの大きなfixtureも含め、実装と残存量確認が必要。

> R-03 Reviewer note: 起動smoke先行、短い代替実行、限定→通常→性能、全体の加重80%という改訂方針は確認した。実装・再検証は未反映で、既存のWindow不在13件、取消1件、18件未実行、正式coverage/現在候補CI未完は解消していない。

### Validation Tool Results

| Tool | Result | Interpretation |
|---|---|---|
| code-generation-plan.mdの本人指定改訂section確認 | smoke停止条件、通常/性能分離、反復回数/閾値維持、Core/UI境界、限定から全体、UI root回収を計画へ追記済み | 人が求めた方向を具体化している。コードの修正・試験成功とは区別する。 |
| 前回所見の短いソース/記録照合 | Tab配列、再試行ボタン、UUID root、code-summaryの全体回帰未完を再確認 | open3件の修正完了は確認できない。新しい所見は追加しない。 |
| bash scripts/verify-draft-experience.sh / bash scripts/verify-native.sh | 今回ともに未実行 | 計画改訂を先行し、改訂前の長時間反復を行わない本人指示による。過去の専用128件成功・全体401成功/14失敗を新実行として扱わない。 |

### Summary

計画の追記は確認したが、前回Major3件は現在の実装に残るためNOT-READY。次は人が指定したテストケース・実行区分の改訂を進め、長時間再実行の前にsmoke等の短い確認を行う段階である。
