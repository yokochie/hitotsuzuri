# 下書き写真表示の修正記録

## 状態

対象限定Greenに続き、製品/試験ソース8173d90416855eed3d6e0eca2c6ec12b444c840eと同一の0fd9e72で通常の全機能CI42173044894が成功した。起動smoke2件、機能534件（Core460+UI74）、行カバレッジ5467/5981 = 91.41%。本人Macでの今回の表示解消は未確認。CIの詳細は同じディレクトリの[ci-evidence.md](ci-evidence.md)を正本とする。

## 変更と判断

- `Hitotsuzuri/ArticleAppCoordinator.swift`: 表示の停止/復帰/番号別再試行をCoordinatorへ集約した。出力のため表示を解放した直後にdeferを登録し、正常終了・画像取得失敗・取消・保存先取消・容量拒否・保存/入力検証失敗の全returnから、同じ有効sessionの表示を再開する。解放前の最初の確認取消では従来の表示を維持する。
- 同じsession IDでもownerがnil/空なら再生成する。表示Taskを単一のrequest UUIDで管理し、Task開始前も再試行を直列化する。退場/新session/出力開始で旧Task・ownerを取り消し、旧Taskの後処理が新requestを消さないようUUIDを再照合する。
- `ArticleImageAccess.isBusy`が残る場合は取消可能な待機Taskで実終端を待ち、Task取消・request UUID・現在sessionを再確認してから取得を始める。既存DeliveryのsettleImagesによる実終端待ちも維持した。再取得処理で出力結果や失敗メッセージを消さない。
- `Hitotsuzuri/ArticleView.swift`: マウス/キーボードを同じretry入口とcanRetryPhotosへ接続。owner正常時は対象番号だけ、欠落時は新ownerの初回loadへ進み、二重取得しない。`Hitotsuzuri/ArticlePreviewView.swift`と共に、出力/実終端待ちを文字で示す。試験識別子は実Image要素へ付けた。
- `Hitotsuzuri/DebugFixture.swift`: 合成画像の可用性、保留した旧表示/出力応答、reader取消到達、保存失敗、保存先取消、容量/不正日付を決定的に制御する。fixtureは表示ownerの復帰を実行しない。診断は実sessionの写真順、実ownerのpixel、実driverの要求数を読む。
- Core、Photos adapter、保存形式、Xcode設定、entitlements、共有scheme、runner、通常のCI閾値を変更していない。Refactorは停止/復帰/再試行の共通責務とUUID後処理の整理で完了とし、対象限定Green後の意味変更を加えていない。

## 要件と試験の対応

新しい`HitotsuzuriUITests/ArticlePhotoRestorationUITests.swift`は実Coordinator/View/LocalImageAccess/出力Sessionを通る10件。各シナリオに計画T番号のコメントを保持する。

| 要件 | 実装/検証 |
| --- | --- |
| FR1 | synchronizeSession/resumePhotoPreviews、T1 fresh保存・再起動・4枚の実画像/本文/順序、T9 一部失敗から回復 |
| FR2 | exportArticleのdeferとresumePhotoPreviews、T2–T8 正常/画像失敗/処理取消/保存先取消/容量/保存/入力失敗、T10 旧応答と新session |
| FR3 | retryPhoto/canRetryPhotos、Viewのマウス/キー共通経路、T9 対象要求の増加・実画像・他番号/未保存タイトル保持 |
| NFR1 | session/写真順/本文保持、T1/T2/T3/T7/T8/T9、専用UUIDの合成fixtureと既存所有cleanup。通常記事・Photos・通信・権限を変更しない |
| NFR2 | 単一Task/UUID、取消・実busy待ち、T4 出力中の表示要求不変と実終端後の復帰、T10 旧応答拒否/不要保持解放。既存ArticleImageTests/ArticlePreviewRetryTests/ArticleResourceTestsの期限・予算・世代契約を維持 |
| NFR3 | 承認済みTDD、CI Red→対象限定Green→通常全機能Green。91.41%で80%条件を満たし、本人実機確認と区別 |

機械可読の6要件→既存source/testへの対応は[traceability.json](traceability.json)。対応付けのOKは、全CIや実機確認が完了したという意味ではない。

## Red / Greenの根拠と観測修復

- 基準d3feef4のCI42030797393: Core460、旧UI64、smoke2成功、全製品91.13%。記録のみe6111daまで対象ソース同一を確認して利用した。
- 最初のf912576、CI42167693848は既存Core/旧UI成功、新10件失敗。有効Redではない。T1–T8はSwiftUI StaticText.labelだけを読む観測不備、T9/T10はPicker起動validationとの共有cache/要求/取消の干渉と診断不足で、目的の出力後欠落を確認できなかった。T4の応答解放と終了待ちの順も修復した。
- d45acb7、CI42171059895: smoke2成功、T1/T9/T10成功。T2/T5/T6/T7/T8の5件は出力後に`owner=false;imageBusy=false;pixels=none,none,none,none;entered=1`でready/要求再開を待って失敗。有効なRedはこの5件。T3のAX snapshotエラー、T4のbusy中メッセージ待ちtimeoutは別の観測不備として扱った。
- T3はpredicate内のremote AX lookupを減らし、同一診断snapshotで実状態と要求数を照合してから独立counterも確認する。T4は通常文言を変えず、実readerへ取消が届いた事実・保留数・busy・表示要求不変で制御する。
- 8173d90、[CI42172183678](https://github.com/yokochie/hitotsuzuri/actions/runs/42172183678): smoke2、新10件全成功（262.727秒）。5件がGreenへ転じ、修復したT3/T4も成功。部分実行を全体成功や全体coverageへ代用しない。
- 一時診断workflowを追加/削除し、削除コミット0fd9e72では対象製品/試験を変えず通常全機能CIへ戻した。[通常PR CI42173044894](https://github.com/yokochie/hitotsuzuri/actions/runs/42173044894)で全機能534件とsmoke2件が成功し、全製品5467/5981行＝91.41%。選択した機能試験のskip0。性能は従来の別区分で、新しい性能測定の成功を意味しない。重複push CI42173038631には取消を要求した。重複cancelled runは成功証拠にしない。

## 試験範囲とデータ保護

restore-* fixtureだけPicker用adapterを分ける。通常App/従来fixtureはLocalImageAccessを共有する。新10件は記事driver自身の要求と所有を観測し、Picker共有時の同時取消/release干渉は対象外。既存の画像/資源部品試験、通常共有構成の既存UI、および本人実機確認を併用し、新10件だけで共有相互作用や本人環境の解消を証明しない。

合成画像とケース専用UUID root、試験用pasteboardのみを使用し、既存FixtureLaunchがapp内で所有rootだけをcleanupして成功を確認する。通常記事の移行/削除、写真ライブラリやOS設定の操作、一般pasteboardの操作は行わない。保存のnofollow/fd相対I/O、出力所有照合/確定/cleanupは既存実装のまま。今回ローカルbuild/native/UI/性能試験は実行していない。静的runner発見とgit diff --checkを実施した。

## 本人確認と残作業

本人実機での解消は未確認。通常Xcode Runで次をまとめて確認する。試験fixture引数は使わない。

1. 保存済み下書きを再開し、4枚と保存された本文・写真順を確認する。
2. 出力を完了または取り消し、同じ記事へ戻って4枚を確認する。必要なら番号別再試行と文章編集を行い、入力が保持されることを確認する。
3. 写真アプリで事前読込後に出力可能になる事象と、表示要求/ownerの欠落を区別する。残る場合は操作順と表示文言を記録し、記事データや権限を消して回避しない。

CI結果と6要件の対応をBuild and Testへ引き継ぎ、本人の確認結果は最終段階で別に記録する。本人の原点要望文書、README、Dependabot/GitHub設定の別件commitは画像要件への追加仕様として転用していない。
