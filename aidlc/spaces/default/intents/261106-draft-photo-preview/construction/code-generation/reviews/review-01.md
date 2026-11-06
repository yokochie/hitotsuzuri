## Review

**Verdict:** READY
**Reviewer:** aidlc-architecture-reviewer-agent
**Date:** 2026-11-06T06:44:40Z
**Iteration:** 1
**Verdict Dictated:** no

### Findings

| ID | Severity | Location | Finding | Required action | Status |
|---|---|---|---|---|---|
| R-01 | Major | Hitotsuzuri/ArticleAppCoordinator.swift > exportArticle（442、460–462行）/ resumePhotoPreviews（228–248行）、NFR2 | 出力AのArticleExportSession.startが返るとisBusyはfalseになり、preparingExportも既にfalseのため、続くexportDelivery.pending()のawait中はworkingがfalseになる。同じ記事の出力Bをここで開始できる。Bが表示を停止して保存/保存先準備等をawaitしている間にAが戻ると、AのdeferがresumePhotoPreviewsを実行する。この処理はsession IDと表示request UUIDしか照合せず、別の出力がworkingであることを入口でもTask内でも確認しない。Bの画像処理開始前ならimages.isBusyもfalseなので、Bの準備中に表示ownerと要求が再生成され、その後Bの変換と同時保持し得る。表示request UUIDはB開始時の停止より後でAが発行するため、この順序を防げない。静的に追える再入経路であり、実機/自動試験でこの割込みを再現したという所見ではない。既存T2–T8の単発出力成功はこの順序の否定根拠にならない。 | 出力後の照会と表示復帰までCoordinator側の出力所有期間を保持する、または出力世代とworkingを照合して古い出力の後処理が次の出力中に表示を再開しないようにする。最初の出力後照会を保留した状態で次の出力を開始する制御可能な回帰を追加し、次の出力の実終端まで表示要求が増えないことを確認する。 | New |

### 所見の根拠

1. `ArticleExportSession.start`はdeferで`isBusy=false`にして返る（`HitotsuzuriCore/ArticleExportSession.swift`）。Coordinatorの`working`はoperationWorking・preparingExport・このisBusyの合成だけである（Coordinator13行）。
2. Coordinatorはstartの終了後、MainActorから`await exportDelivery.pending()`へ移る（461行）。この間、同じ入口の`guard !working`（425行）と出力ボタンの無効化条件（ArticleExportView14行）が、次の出力を止めない。
3. 先の呼出しのdeferは同じsession IDで表示復帰を呼ぶ（442行）。resumePhotoPreviewsの入口とowner生成直前にはworking/出力世代の確認がなく、画像busyでなければloadへ進む（228–248行）。次の出力の保存や保存先準備は、実画像要求を始める前にawaitするため、images.isBusyだけでは出力全体の排他にならない。

これは未実行の競合再現を、実測済みの失敗として報告するものではない。静的な再入順序とNFR2の「出力中に表示取得を重ねない」という契約との不整合であり、承認時に修正要否を判断する所見である。

### 確認した実装と試験

- 表示停止/再生成/番号別再試行の責務がCoordinatorへ集約され、同sessionでもowner欠落時に復帰する。旧表示Taskの終了が新requestを消さないUUID照合、session切替/退場時の取消、マウスとキーボードの共通入口を確認した。
- 単発出力については表示解放後のdeferが正常・画像失敗・取消・保存先取消・容量/保存/入力失敗を覆う。表示解放前の確認取消は従来のownerを維持する。出力結果の文言を表示再取得で消していない。
- 新10件は状態文言だけでなく実driver要求数、実ownerのpixel、Image要素、本文/順序、取消到達、実busy、遅い旧応答の排除と保持量を観測する。fixtureが表示ownerの復帰を代行していない。
- restore-*だけPicker検証adapterを分離しているため、新10件だけでは通常の共有Pickerによる同時取消/release干渉を証明しない。この限界と本人実機未確認が記録されており、実機での直接原因/解消を断定していない。通常の共有構成は変更されていない。
- Coreの期限/予算/Photos/保存形式/所有cleanupを変更する差分はない。追加の原点文書・README・Dependabot設定は画像仕様として取り込まれていない。

### Validation Tool Results

| Tool | Result | Interpretation |
|---|---|---|
| git diff --check | PASS | 差分整形のエラーなし |
| sensor-traceability（code-generation） | PASS、gaps/orphans/invalid targetsなし | 6要件の対応先は実在する。振る舞いの競合がないことまで保証する検査ではない |
| git diff --quiet 0fd9e72（App/Core/全試験/scripts/.github） | exit 0 | 現在の製品・試験・通常CIは成功CIの対象と同一 |
| gh run view 42173044894 | completed/success、head 0fd9e72b0aa22c3568227c8b8d3bc952861b6111 | remoteの正式CI完了状態を独立確認 |
| Core job 127745087980の完了ログ取得 | Python28件、Core460件成功 | runner契約と既存Coreを維持 |
| Native job 127745757442の完了ログ取得 | smoke2件、主534件、5467/5981=91.41% | 新10件全成功を含む全機能と製品80%以上を独立確認。上記の出力再入シナリオは新10件に含まれない |

本人のCI優先方針に従い、新しいCI、ローカルbuild/native/UI/性能、実Photos、一般pasteboard、OS設定操作は実行していない。完了済みCIログを独立取得して確認した。Redの有効範囲は記録どおりT2/T5–T8の5件で、最初の観測失敗やT3/T4の観測修復を有効Redへ水増ししていない。

### Summary

既存の表示欠落経路に対する修正と、10件の接続回帰・全機能CI・91.41%のcoverageを確認した。判定はREADYだが所見なしではなく、同じ記事の次の出力へ古い後処理が割り込むMajor1件が残るため、承認前にその扱いを判断する必要がある。
