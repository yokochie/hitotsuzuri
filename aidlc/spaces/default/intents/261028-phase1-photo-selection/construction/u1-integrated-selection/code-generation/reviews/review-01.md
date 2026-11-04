## Review

**Verdict:** NOT-READY
**Reviewer:** aidlc-architecture-reviewer-agent
**Date:** 2026-10-31T08:11:12Z
**Iteration:** 1
**Verdict Dictated:** no

### Findings

| ID | Severity | Location | Finding | Required action | Status |
|---|---|---|---|---|---|
| R-01 | Major | HitotsuzuriCore/LocalImageAccess.swift > retainedBytes・drain・finish、およびHitotsuzuriCore/SelectionWorkflow.swift > images・loadImage | 256 MiB予算はcacheだけを数えるが、返却済みImageBufferはSelectionWorkflow.imagesにも保持される。drainのLRU削除や検証による同じassetIDのcache置換は、画面側の旧バッファを解放せず計上だけを外す。合成画像のプローブで予算4,194,304 bytesに対して返却画像6,291,456 bytesを保持でき、報告値は3,145,728 bytesだった。全用途の固有バッファと予約を数えるPD2を満たさない。 | 画面・4枠・検証の参照が残るバッファを含めた単一の所有/計上方式へ変更する。実参照が残る間は予算を解放せず、同じ写真の再検証で別バッファを作る場合も両方を計上する。小さい注入予算で返却先の保持と再検証を含む回帰テストを追加する。 | New |
| R-02 | Major | HitotsuzuriCore/LocalImageAccess.swift > Pending・image・finish、およびHitotsuzuriCore/SelectionWorkflow.swift > validateImages | 期限はTask.sleepによるタイマーとの実行順だけで判定し、Pendingに受付時刻/期限がなく、成功時にも現在時刻を照合しない。MainActorが遅延すると期限超過後の成功が先に処理されて採用される。合成driverでtimeout=1msに対し約59ms後の成功が採用された。タイマーTask自体の開始が遅れると受付からの期限も延びる。4枚全体も同じ競合を持つ。 | 受付時と4枚検証開始時に単調時計の絶対期限を確定し、終端結果を採用する境界で期限ちょうど以降を拒否する。注入可能な時計で待機時間・MainActor遅延・期限ちょうど・成功との競合を検証し、個別期限と全体期限の早い方を適用する。 | New |
| R-03 | Major | HitotsuzuriCore/SelectionPersistence.swift > loadSettings・saveSettings・write | 設定の読込みはCodableによる構文/型検査だけで、空IDなどの意味上の不正を検査しない。例えばsettings.jsonが{"schemaVersion":1,"folderIDs":[""]}でもloadSettingsはvalidになり、saveSettingsが正常な新設定を受け取るとwrite内のreadもvalidとなって破損原本を上書きする。新しい入力だけを検査しており、既存の確定JSONに加えた意味上の破損保護が設定JSONにはない。SD2の空でないIDとRD2の破損原本保護に反する。 | 設定レコードの意味上の有効性を読込み境界と書込み前の旧レコード検査へ共通適用し、意味上の破損をcorruptDataとして拒否する。空IDの旧設定を用意し、読込みが失敗を返すこと、設定変更で原本bytesが変わらないことを回帰テストにする。 | New |
| R-04 | Minor | HitotsuzuriCore/SelectionWorkflow.swift > setTargetFolders・clearAlbum、およびHitotsuzuriCore/PresentationSnapshot.swift > noticeの優先表示 | 保存成功後に対象フォルダを変えて現アルバムを対象外にすると、clearAlbumが編集選択を消す一方でnoticeの「4枚を保存しました。」が残る。PresentationSnapshotはisDirtyよりnoticeを優先するため、0枚の編集へ変わっても未保存表示にならない。 | フォルダ変更で編集状態をクリアした際に古い保存成功noticeを消し、現在の編集と最後の確定を区別する表示へ更新する。保存成功→対象外フォルダ変更の状態投影をテストする。 | New |

### Validation Tool Results

| Tool | Result | Interpretation |
|---|---|---|
| xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriU1Tests -enableCodeCoverage YES -derivedDataPath .build/DerivedData CODE_SIGN_IDENTITY=- test | 独立実行: TEST SUCCEEDED、49 tests、0 failures、exit 0。結果 .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.10.31_17-11-47-+0900.xcresult | 承認済み単位コマンドをtestmanagerd接続に必要な権限で実行した。CoreSimulator旧版の警告はあったがmacOSテストは成功。既存テストは上記の資源所有・厳密期限・設定の意味上の破損を検出していない。 |
| swift scripts/check-coverage.swift .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.10.31_17-08-35-+0900.xcresult | 655/807 = 81.16%、exit 0 | 記録された既存結果の数値を独立に確認した。手書きApp/Core全体を含み、未計測ファイル検査を行っている。 |
| swift scripts/check-coverage.swift .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.10.31_17-11-47-+0900.xcresult | 再実行分も655/807 = 81.16%、exit 0 | 現時点の単位テストでも80%を超える。行カバレッジ達成は上記の振る舞いの成立を代替しない。 |
| 合成ImageDrivingを公開APIへ注入したswift -eプローブ | budget=4194304 actualHeld=6291456 reported=3145728。deadline=1ms acceptedSuccessAfter=0.059319458 seconds | 製品フレームワークを読み、個人写真を使わずに予算の計上漏れと期限後成功採用を再現した。ソース/テストファイルは変更していない。最初の試行はシステムModuleCacheのsandbox制限でコンパイルできず、プロジェクト内.build/ReviewModuleCacheへ切り替えて実行した。 |
| aidlc engine sensor-traceability --stage code-generation --output-path aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/code-generation/traceability.json | PASS、findings_count=0、すべてのエラー配列は空 | IDと実在ファイルの対応は成立する。振る舞いの実装不備は上記に別途記録した。 |
| aidlc engine sensor-required-sections --stage code-generation --output-path（code-generation-plan.md / code-summary.md / unit-test-instructions.mdの各指定パス） | 全3文書PASS、findings_count=0 | 見出し数は6・5・5。計画・結果・実行手順の構造に欠落なし。 |
| manifest記載26パスと共有契約の照合 | ソース・テスト・構成・スクリプトを確認 | 4枚順序、現アルバム所属再検証、通信false、直列atomic保存、検証/保存中の編集拒否を確認。写真アプリの実順序、実権限、Sandboxでの本人起動は未確認のまま。CI省略決定を適用し、未承認のbash scripts/verify-u1.shは実行していない。 |

### Summary

承認済みテストとカバレッジ条件は独立実行でも達成しているが、画像予算・厳密期限・破損設定の保護に3件のMajorがあるためNOT-READY。これらはU1で備える安全性と資源管理の実装不備であり、U2/U3の実機受け入れ待ちとは別に修正が必要である。
