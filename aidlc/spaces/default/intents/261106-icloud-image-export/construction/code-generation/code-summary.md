# 出力画像のアプリ内取得の実装記録

## 現在の検証状態

Coreの6件の有効Redは、6a389a1の対象CI42212786801で新17件が全成功へ転じた。画面の3件は7561c21のCI42213371286で意図した失敗を確認し、その対応を5d20d82へ実装した。対象CI42214062065ではCore20件と既存写真復帰11件が成功したが、新UI3件は進捗と完了文字の観測で失敗した。観測方法と診断を修復して再確認する段階で、新UI3件の取消実終端・復帰・再出力成功まで通ったとはまだ記録しない。通常全機能CI/全製品80%検証と本人の実iCloud確認も未完。

SHA/job/各assertの詳細正本は同じ場所の[ci-evidence.md](ci-evidence.md)。変更前f272e3dの機能535件・smoke2・91.49%は基準であり、今回の変更後の最終成功へ代用しない。

## 変更したファイルと判断

- `HitotsuzuriCore/ArticleImageAccess.swift`: PhotoKit readerはnetworkAllowedを実optionsへ反映し、progressHandlerをMainActorへ渡す。内部の単調ticketでassetとnative tokenを所有し、要求ID確定前の取消を発行後へ引き継ぐ。完了でentryを解放し、取消後の旧通知は現在の要求へ届かない。SDK optionsを写真ライブラリへ触れず検証する最小注入境界を追加した。
- 同ImageAccessは明示的にnetwork許可した取得待ちに独自の総経過期限を置かず、PhotoKit成功/失敗/本人取消を待つ。待機時間を記録し、変換開始後の30秒期限、256MiB予算、同期変換の実終端までのbusyを維持する。既定のlocal/probe要求は従来のnetwork=false・30秒期限のまま。表示用512px経路と15秒期限は変更しない。
- `HitotsuzuriCore/ArticleExportDelivery.swift`: 出力時だけnetwork=trueを指定し、取得待ち時間を1枚30秒/書込込み40秒/全体180秒の経過から控除する。変換と書込/確定の保護まで無制限にはしない。進捗をjob/request/写真番号と単調fractionで検証し、取消・終端後の古い通知を捨てる。固定保存入力、4枚直列化、所有cleanup/不確定公開照合は既存契約のまま。
- `HitotsuzuriCore/ArticleModels.swift`: 判別できる通信失敗の型networkUnavailableを追加した。共通assetUnavailableを一括で書き換えず、表示と出力の文脈を分ける。PhotoKitの取消キー/ネットワークNSError/詳細不明を分類し、不明なinput欠落をiCloud未取得と断定しない。
- `HitotsuzuriCore/ArticleExportSession.swift`: 写真1〜4の対象番号と進捗を表示する。百分率は1枚の取得状況で、一式成功は実ExportResultを得てから。phase順位・完了枚数・fraction単調性で旧job/前写真/不正値・取消後通知を拒否する。出力の画像取得失敗にはアプリ内での再出力を案内し、要照合/cleanup失敗を盲目的な再試行へ誘導しない。
- `Hitotsuzuri/ArticleExportView.swift`: 進捗なしは不定spinner、利用可能なfractionは確定progressbarと文字/AX値へ反映する。既存の取消操作とfocusを維持した。
- `Hitotsuzuri/DebugFixture.swift`、`Hitotsuzuri/ArticleView.swift`のDEBUG箇所: 合成cloud readerの進捗・終端・単発写真2失敗を制御する。実Coordinator→Session→Delivery→ImageAccessを通し、fixtureがmessage/busyや表示復帰を代行しない。
- 新規 `HitotsuzuriU2Tests/ArticleCloudImageTests.swift`（12件）、`HitotsuzuriU3Tests/ArticleCloudExportTests.swift`（8件）、`HitotsuzuriUITests/ArticleCloudExportUITests.swift`（3件）。初期Core17件に、画面Green時のSession否定回帰3件を追加した。`ArticleExportIntegrationTests.swift`の既存性能用合成readerは新しい出力のnetwork許可を受理し、期待許可回数を0から120へ修正した。これは実通信の実行や性能測定成功を意味しない。

Core/画面の呼出境界を調整したが、保存schema、manifest、entitlements、共有scheme、Xcode設定、通常CIの選択/除外/80%閾値は変更していない。新しい外部依存や独自HTTP/backend、写真変更APIは追加していない。Zero Unitなのでsource-manifestや架空のUnitは作らない。

## 要件と回帰の対応

| 要件 | 実装と検証 |
|---|---|
| FR1 | 実PhotoKit optionsのnetwork許可、出力の明示policy、Core T1/T2とUI U1/U3 |
| FR2 | reader→ImageAccess→Delivery→Session→Viewのfraction、写真番号、Core T3/T4とU1 |
| FR3 | 要求ID前/進捗なし/中の取消、native tokenへ配信、実終端gate、Core T7/T8/T12とU2 |
| FR4 | 写真2失敗、型付き通信/権限/不明失敗、所有cleanup、新job再出力、Core T9/T10とU3 |
| NFR1 | cloud取得待ち301秒後の成功、待機と変換/書込期限の分離、Core T5/T6/T12 |
| NFR2 | 世代/phase/fraction排除、本文/順序と旧成果物保持、256MiB・owner/grant・直列化、T1/T4/T6–T11、既存資源/出力回帰 |
| NFR3 | 下記TDD、CI優先、全機能/80%の最終確認と実機の区別 |

機械可読の対応は[traceability.json](traceability.json)の7要件。対応のOKは最終CIや実機完了を意味しない。

## TDDの証拠

- 2a40f34、CI42211810710/job127872011876: Core8件中6失敗。実optionsとAccessのfalse/false対true/false、進捗空配列、301秒取得timedOut、Deliveryのfalse4個対true4個・301秒待機timedOutという目的のRed。local timeoutと取消gateの対照2件は成功。compile/fixture失敗ではない。
- 6a389a1、CI42212786801/job127875272187: 新Core17件成功（Image12件0.079秒、Export5件0.849秒）。旧Red6件が成功へ転じ、追加の不正/旧進捗、ID確定前取消、変換/書込期限、失敗後再試行も確認した。
- 7561c21、CI42213371286/job127877241459: smoke2件成功、新UI3件は全失敗（54.103秒）。実要求保留後に番号が「画像0/4」、50%が未表示、写真2失敗時に旧写真アプリ案内が残るという目的のRed。後続の取消/復帰/再試行assertは到達前なので、このRedだけで検証済みとはしない。
- 5d20d82、CI42214062065/job127879569109: Core20件とsmoke2件、既存写真復帰11件（290.986秒）が成功。新UI3件は65.160秒で全失敗。U1は新しい写真1/4表示を通過した後の50%待ち、U2も50%待ちで失敗。U3は旧案内が消えて再出力の実result・操作復帰・画像readyまで進んだ後、完了文字のassertだけが失敗した。完了した部分と未到達の後続assertを区別する。
- 新UIhelperは選択可能TextのAX valueを優先していたため、現在のlabelを優先し、実Sessionのfraction/messageと実ProgressViewのAX値を独立照合する観測へ修復した。必要なscroll位置を整え、失敗時はlabel/value/model/progressを記録する。通常出力動作の原因とは未断定で、新UI3件の再CI結果を待つ。assertの目的や期待値は弱めていない。
- b6fd9a8、CI42215343404/job127883831537: smoke2成功、新UI3件は初期readyで失敗（48.893秒）。追加診断のexportStage=none/exportFraction=noneを、全診断文字列へのnone検索が画像なしと誤判定した。実owner=true・pixels4値・要求1,1,1,1であり、製品の表示失敗ではない。readyをpixelsフィールドだけの4値/非none照合へ修復し、元の50%/完了文字の再検証は未到達として区別する。

## 試験とデータの限界

合成画像、専用UUID rootと試験pasteboardだけを使用し、FixtureLaunchのapp内所有cleanupを確認する。cloud-*は記事側readerの観測を独立させるためPicker表示adapterを分ける。通常アプリの共有構成そのものの実iCloud動作やPhotosの通知頻度を、新しい合成試験だけで証明しない。

今回ローカルbuild/native/UI/performance、実Photos/iCloud、OS設定、一般clipboardを操作していない。静的runner/差分確認とgit diff --checkを実施した。既存performance試験の期待許可方針の修正はあるが、新たな実時間/実メモリ測定は未実行。

## 本人確認と引継ぎ

通常Xcode Runで、写真アプリの事前操作なしに未取得画像を含む4枚出力を開始し、取得中の文字/進捗/取消と再出力、成功後の4枚/本文/写真順保持を最終段階で確認する。実写真や記事データ、認可を削除して試験条件を作らない。

残作業は観測修復後の新UI3件の再CI、通常全機能CIと全製品80%以上の確認、一時診断workflowの削除、Build and Testへの記録引継ぎ、本人の実機確認。5d20d82以降の変更は新UIhelperとDEBUG診断だけで、通常の取得/出力動作は維持している。対象CI成功だけを全体成功や実機解消へ代用しない。
