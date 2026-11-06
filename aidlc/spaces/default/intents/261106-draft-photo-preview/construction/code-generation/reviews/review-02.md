## Review

**Verdict:** READY
**Reviewer:** aidlc-architecture-reviewer-agent
**Date:** 2026-11-06T07:48:41Z
**Iteration:** 1
**Verdict Dictated:** no

### Findings

| ID | Severity | Location | Finding | Required action | Status |
|---|---|---|---|---|---|
| R-01 | Major | Hitotsuzuri/ArticleAppCoordinator.swift > exportArticle（442、460–462行）/ resumePhotoPreviews（228–248行）、NFR2 | 出力AのArticleExportSession.startが返るとisBusyはfalseになり、preparingExportも既にfalseのため、続くexportDelivery.pending()のawait中はworkingがfalseになる。同じ記事の出力Bをここで開始できる。Bが表示を停止して保存/保存先準備等をawaitしている間にAが戻ると、AのdeferがresumePhotoPreviewsを実行する。この処理はsession IDと表示request UUIDしか照合せず、別の出力がworkingであることを入口でもTask内でも確認しない。Bの画像処理開始前ならimages.isBusyもfalseなので、Bの準備中に表示ownerと要求が再生成され、その後Bの変換と同時保持し得る。表示request UUIDはB開始時の停止より後でAが発行するため、この順序を防げない。静的に追える再入経路であり、実機/自動試験でこの割込みを再現したという所見ではない。既存T2–T8の単発出力成功はこの順序の否定根拠にならない。 | 出力後の照会と表示復帰までCoordinator側の出力所有期間を保持する、または出力世代とworkingを照合して古い出力の後処理が次の出力中に表示を再開しないようにする。最初の出力後照会を保留した状態で次の出力を開始する制御可能な回帰を追加し、次の出力の実終端まで表示要求が増えないことを確認する。 | Resolved (reviewer) |

> R-01 Reviewer note: Hitotsuzuri/ArticleAppCoordinator.swift > exportArticle（425–473行）では、入口のguard通過直後にpreparingExportを立て、保存確認・出力準備・ArticleExportSession.start・出力後のpending照会の全awaitを通して保持する。単一deferで解除してからresumePhotoPreviewsを呼び、その間にawaitがないため、前の照会中に次の出力が受理される経路が閉じている。表示停止後にのみphotoSessionIDを設定するので、保存確認の取消で既存ownerを作り直すこともない。T11は後照会相当の待機位置を保留し、通常ボタンを迂回して実入口へ再要求する。旧実装では受理2回で失敗し、修正後は受理1回・working=true・表示要求据置を確認する。照会解除後の復帰と次の出力・再復帰も確認している。

### Validation Tool Results

| Tool | Result | Interpretation |
|---|---|---|
| 静的経路確認 | exportArticle、表示停止/復帰、DEBUG照会gateと再要求入口、T11を確認 | gateは呼出元を保留するだけでbusyや表示復帰を代行しない。修正が実Coordinatorの所有期間を延ばしていることを確認した。 |
| GitHub Actions既存Redログ読取：42178316595 / job127761830583 | T11が27.553秒で失敗。期待受理1回に対し実受理2回、working=false、postQueryWaiters=2 | 従来の入口排他の欠落を実Coordinatorで観測した根拠。旧後処理による表示再開の全割込み順序を実機再現したという意味ではない。 |
| GitHub Actions既存Greenログ読取：42178850429 / job127763494549 | 新class11件成功、T11成功44.434秒、smoke2件成功 | 再要求拒否と所有解放後の通常出力を含む回帰を確認した。 |
| GitHub Actions最終通常CI読取：42179866652 | head f272e3d4fb9783f38acc7745a1d3bcd8ac2b60b9、completed/success。Core job127766730191でPython28件とCore460件成功。native job127767229796でsmoke2件・機能535件成功、新class11件を含む。製品全体5527/6041行、91.49% | ci-evidenceとcode-summaryの最終結果に一致する。既存80%条件を満たす。 |
| git diff --check / 対象ソース・試験・通常CIとf272e3dの差分確認 | いずれも終了コード0、差分なし | 検証済みHEADと現在の対象実装が一致する。 |
| aidlc engine sensor-traceability --stage code-generation --output-path aidlc/spaces/default/intents/261106-draft-photo-preview/construction/code-generation/traceability.json | pass=true、findings_count=0 | 6要件の対応に欠落・孤立・無効な参照先はない。実際の挙動は別途コードと試験で確認した。 |

### Summary

R-01は修正済み。今回の変更と追加回帰について、新たに承認判断へ挙げる所見はない。本人指定のCI優先方針に従い、ローカルbuild/native/UI/performanceや新CIは実行せず、完了済みCIを独立に読み取った。

本人のMacで報告された症状の直接原因と解消は未確認のままである。またrestore-* fixtureのPicker adapterは分離されており、新11件だけで通常の共有Picker adapterとの相互作用を証明するものではない。これらの限界は成果物に明記され、CI成功と区別されている。
