## Review

**Verdict:** READY
**Reviewer:** aidlc-architecture-reviewer-agent
**Date:** 2026-10-31T08:22:38Z
**Iteration:** 2
**Verdict Dictated:** no

### Findings

| ID | Severity | Location | Finding | Required action | Status |
|---|---|---|---|---|---|
| R-01 | Major | HitotsuzuriCore/LocalImageAccess.swift > retainedBytes・drain・finish、およびHitotsuzuriCore/SelectionWorkflow.swift > images・loadImage | 256 MiB予算はcacheだけを数えるが、返却済みImageBufferはSelectionWorkflow.imagesにも保持される。drainのLRU削除や検証による同じassetIDのcache置換は、画面側の旧バッファを解放せず計上だけを外す。合成画像のプローブで予算4,194,304 bytesに対して返却画像6,291,456 bytesを保持でき、報告値は3,145,728 bytesだった。全用途の固有バッファと予約を数えるPD2を満たさない。 | 画面・4枠・検証の参照が残るバッファを含めた単一の所有/計上方式へ変更する。実参照が残る間は予算を解放せず、同じ写真の再検証で別バッファを作る場合も両方を計上する。小さい注入予算で返却先の保持と再検証を含む回帰テストを追加する。 | Resolved (reviewer) |
| R-02 | Major | HitotsuzuriCore/LocalImageAccess.swift > Pending・image・finish、およびHitotsuzuriCore/SelectionWorkflow.swift > validateImages | 期限はTask.sleepによるタイマーとの実行順だけで判定し、Pendingに受付時刻/期限がなく、成功時にも現在時刻を照合しない。MainActorが遅延すると期限超過後の成功が先に処理されて採用される。合成driverでtimeout=1msに対し約59ms後の成功が採用された。タイマーTask自体の開始が遅れると受付からの期限も延びる。4枚全体も同じ競合を持つ。 | 受付時と4枚検証開始時に単調時計の絶対期限を確定し、終端結果を採用する境界で期限ちょうど以降を拒否する。注入可能な時計で待機時間・MainActor遅延・期限ちょうど・成功との競合を検証し、個別期限と全体期限の早い方を適用する。 | Resolved (reviewer) |
| R-03 | Major | HitotsuzuriCore/SelectionPersistence.swift > loadSettings・saveSettings・write | 設定の読込みはCodableによる構文/型検査だけで、空IDなどの意味上の不正を検査しない。例えばsettings.jsonが{"schemaVersion":1,"folderIDs":[""]}でもloadSettingsはvalidになり、saveSettingsが正常な新設定を受け取るとwrite内のreadもvalidとなって破損原本を上書きする。新しい入力だけを検査しており、既存の確定JSONに加えた意味上の破損保護が設定JSONにはない。SD2の空でないIDとRD2の破損原本保護に反する。 | 設定レコードの意味上の有効性を読込み境界と書込み前の旧レコード検査へ共通適用し、意味上の破損をcorruptDataとして拒否する。空IDの旧設定を用意し、読込みが失敗を返すこと、設定変更で原本bytesが変わらないことを回帰テストにする。 | Resolved (reviewer) |
| R-04 | Minor | HitotsuzuriCore/SelectionWorkflow.swift > setTargetFolders・clearAlbum、およびHitotsuzuriCore/PresentationSnapshot.swift > noticeの優先表示 | 保存成功後に対象フォルダを変えて現アルバムを対象外にすると、clearAlbumが編集選択を消す一方でnoticeの「4枚を保存しました。」が残る。PresentationSnapshotはisDirtyよりnoticeを優先するため、0枚の編集へ変わっても未保存表示にならない。 | フォルダ変更で編集状態をクリアした際に古い保存成功noticeを消し、現在の編集と最後の確定を区別する表示へ更新する。保存成功→対象外フォルダ変更の状態投影をテストする。 | Resolved (reviewer) |

> R-01 Reviewer note: ImageBufferは不変ImageStorageを共有し、LocalImageAccessはキャッシュ外もweakな生存一覧で計上する。描画プロバイダもそのstorageの寿命を保持する。返却値保持・同一写真の再検証・CGImageだけの保持の回帰テストを確認。前回と同じ小予算プローブは4 MiBに対し実保持/報告とも3 MiBで停止し、追加要求はtimedOutとなった。対象Macの1 MiB Data→NSData橋渡しはポインタ一致も確認した。

> R-02 Reviewer note: 受付時に個別の絶対期限を保存し、drainとfinishで単調時計を照合する。Workflowは4枚の共通絶対期限を渡し、完了後にも検査する。期限ちょうど・期限前・キュー待機・共通期限・MainActor遅延の回帰テストを確認。前回の同期遅延プローブも成功を採用せずtimedOutとなった。

> R-03 Reviewer note: TargetFolderSettings.isValidをloadSettingsと新入力へ適用し、saveSettingsは旧レコードの意味上の検証失敗でも書込みを拒否する。testMalformedSettingsAreRejectedAndOriginalPreservedが空IDの旧設定について読込失敗・保存拒否・原本bytes保持を確認し、独立実行でも成功した。

> R-04 Reviewer note: clearAlbumでnoticeを消す。testRemovingAlbumClearsStaleSavedNoticeが保存成功後のフォルダ除外で選択を消し、旧確定を維持し、古い保存成功文を出さないことを確認。独立実行でも成功した。

### Validation Tool Results

| Tool | Result | Interpretation |
|---|---|---|
| xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriU1Tests -enableCodeCoverage YES -derivedDataPath .build/DerivedData CODE_SIGN_IDENTITY=- test | 独立実行: TEST SUCCEEDED、60 tests、0 failures、exit 0。結果 .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.10.31_17-23-12-+0900.xcresult | 承認済み単位コマンドをtestmanagerd接続に必要な権限で実行。CoreSimulator旧版警告はあるがmacOSテストは成功。修正の回帰テストも含まれる。 |
| swift scripts/check-coverage.swift .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.10.31_17-21-10-+0900.xcresult | 709/862 = 82.25%、exit 0 | 記録済み結果を独立確認。App/Coreの全手書きSwiftを含み、閾値の引下げやView/実アダプターの除外はない。 |
| swift scripts/check-coverage.swift .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.10.31_17-23-12-+0900.xcresult | 再実行分も709/862 = 82.25%、exit 0 | 現在の修正コードでも80%条件を達成した。 |
| 合成ImageDrivingを注入したswift -e再現プローブ | budgetBlocked=timedOut、budget=4194304 actualHeld=3145728 reported=3145728、lateResult=timedOut | 前回の予算迂回と期限後成功採用を再確認し、いずれも修正を確認した。個人写真や権限操作は使用していない。 |
| aidlc engine sensor-traceability --stage code-generation --output-path aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/code-generation/traceability.json | PASS、findings_count=0、すべてのエラー配列は空 | IDと実在ファイルの対応に欠落なし。 |
| aidlc engine sensor-required-sections --stage code-generation --output-path（code-generation-plan.md / code-summary.md / unit-test-instructions.mdの各指定パス） | 全3文書PASS、findings_count=0 | 見出し数は6・5・5。 |
| 修正による境界・寿命・保存状態の照合 | 新規指摘なし | 描画参照の寿命と予算、個別/共通期限、旧設定検証、保存成功文の破棄を確認。既存の通信禁止・参照再検証・単一保存の境界を崩す変更は認めなかった。未承認のbash scripts/verify-u1.shは実行していない。 |

### Summary

前回の4件は修正済みで、独立実行でも60件成功・行カバレッジ82.25%を確認した。実ライブラリの許可・並び・Sandboxでの本人起動は引き続き未確認であり、このREADYを実機成立性や最終Construction検証の完了とは扱わない。
