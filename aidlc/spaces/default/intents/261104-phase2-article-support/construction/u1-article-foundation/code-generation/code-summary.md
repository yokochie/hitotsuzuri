# U1 実装候補・未完了記録

## 状態
記事の開始/保存/再開、基本本文編集、4枚の最小画像表示、通信なしの画像1枚変換/別フォルダ出力を実装した候補。品質ゲートと実機確認が残るため、U1完了・統合可とは判定しない。今回、不確定操作の照合が一時I/O障害で失敗しても元操作を保持する修正を追加。狭域16件はRed→最小Green→整理後Green、専用全コマンドではArticle Core94件の成功を確認。公開実行の最新commit/URL/結果はroot所有の`ci-evidence.md`を正とする。

最新候補 **a108134** のCI実行 **41798035585** で、**Core273件・Article UI6件が全成功**。製品全体の重み付き行カバレッジは **2752/3050＝90.23%**。既存Native26件中8件が失敗し、同じrunの旧製品baselineでも同じ8件が失敗した。全体CIはfailureを維持し、成功・統合完了とは扱わない。本人はローカル環境へしばらくアクセスできないため、本人MacのUI起動と実写真確認は未実施で保留。

修正前候補のCI証拠: commit **109a21e**、実行 **41791281896**。**Core269件・Article UI6件が全成功**。既存Nativeは26件中8件失敗し、旧製品commit0e96d28を同じCI環境で実行した26件中8件と完全一致した。全体CIのfailureは維持し、今回の新しい保存修正の合格値には流用しない。詳細は`ci-evidence.md`。

同じCI候補の全製品重み付き行カバレッジは**2747/3046=90.18%**。80%を達成し、除外/閾値変更なし。AppCoordinator141/206、ArticleView136/140、DebugFixture71/80、App27/37、PickerView24/28。既存UI失敗後の診断stepで既存checkerが成功したもので、元の試験失敗を成功へ変えていない。

今回のローカル`bash scripts/verify-article-foundation.sh`は`.build/Article-20261104-170956-25294.xcresult`、Article Core94件成功。UI runnerはXCTFuture Code=1000「Timed out while enabling automation mode」で初期化失敗、コマンドexit65。狭域16件の証拠とともに`tdd-evidence.md`へ記録。

修正前のローカルではArticle Core90件と、独立した全体コマンドのCore269件が成功。`.build/Native-20261104-155016-98891.xcresult`の2245/3026=74.19%は、旧候補のUIを実行できたCI90.18%とも今回の修正結果とも区別して保持する。

## 実装と所有
- `ArticleModels/Ports/Fingerprint`: 選択4IDの順序、全本文/撮影情報保持型、版/日付/時刻検証、固定canonical/SHA256。基準ベクトルは`fingerprint-vectors.md`。
- `ArticleFileSystem/Persistence`: descriptor相対/no-follow、OS排他、不変操作/current確定、fsync/F_FULLFSYNC、operationID先行照合、旧ID結果、外部版競合、未知版/破損保護。rename後同期未確認はuncertainResultで残し、同ID再試行で再同期して照合。
- `ArticleWorkspace/EditSession`: 永続選択から直接解決、写真なし再開、候補あり無断作成防止、作業コピー/固定保存写し、保存中編集のdirty維持、二重保存拒否、離脱3択。
- 不確定な保存は操作IDだけでなく元の固定本文/基準保存値を保持し、追加入力があっても先に元操作を照合する。その後の新入力は更新した基準版から別IDで保存。照合中にさらに進んだ入力はdirtyを維持する。新規作成の応答喪失も同様。
- 不確定性は各PendingSaveに保持する。元操作の照合が一時I/O失敗を繰り返しても、元ID/固定本文/基準値を失わない。照合成功でその操作を解放した後の新操作は独立し、capacity等の確定失敗なら保持せず入力縮小後に保存し直せる。
- 永続化の読込/新規書込は同じ64MiB byte境界を共有し、再開できない大きさの操作ファイルをcurrentへ確定しない。容量失敗時は旧currentと作業入力を残し、入力縮小後に再保存できる。
- `ArticleImageAccess/Converter`: PhotoKit現在編集入力URL、network=false、向き/sRGB/JPEG0.9/長辺2560/非拡大、元メタデータ非転記。30秒絶対期限、同時期限優先、単一実変換、256MiB予約。論理取消後も実workerが戻るまで予約/ゲートを保持。
- `ArticlePhotoPreviews`（ArticleImageAccess内）: 512px表示用経路を出力用JPEGと分離し、4枚の取得待ち/取得中/成功/失敗を番号別表示。取得不能や無応答で本文保存を止めず、二重表示要求を抑止。離脱後の遅延結果を世代で無効化し表示用保持を解放。
- `ArticleProbeDelivery/Journal`: 先頭1枚、内部jobID、一時物の識別、非上書き確定、画像digest照合、最小ローカル回復記録。bookmarkなし、再起動後は本人が同じ先を再選択。
- 不完全なfinalフォルダはcorruptDataとして残し、必須ファイル不在を「成果物なし」にしない。片付け権限失敗はcleanupFailureと残存場所を表示し、journalを保持する。receipt/画像/確定前の容量、rename後同期不確定、確定後応答喪失、未知一時物保護を試験済み。
- `ArticleAppCoordinator/View`とApp/Picker接続: 初期保存、タイトル/導入/写真4本文/結び、Command+S、戻る/閉じる/終了確認、保存記事を開く、Shift+Command+E、フォルダ選択、選択前grantなし/選択済み型/終端解放、結果先の表示。
- NSApplicationDelegateAdaptor経由で終了を調整し、Pickerのwindow delegateはSwiftUIへ任せる。記事の編集中だけwindow delegateを保持して調整し、戻る/閉じる後に復元する。記事入口は確定後に表示。fixture rootは位置引数ではなく環境変数で渡し、起動経路の差を抑える。
- 通常診断は型付き段階/失敗分類だけ。本文/写真ID/人物/場所をsinkへ出さない捕捉試験を追加。
- 新Swiftは既存filesystem synchronized groupへ自動登録。pbxprojの変更不要。既存4試験target、共有schemeの本人差分、README/AGENTS等を保持。
- Sandboxの追加は`user-selected.read-write`のみ。新規依存/有料サービスなし。workflowはxcode-27、固定checkout SHA、contents:read、資格情報非保持、OS/Xcode/SDKログ、アップロードなし。

対象製品/試験/設定30パスはstrict schemaの`source-manifest.json`。承認計画の本文と試験指示は変更せず、完了したstepのcheckboxだけ更新。

今回のArticle Core成功件数: Model10、Persistence10、Recovery11、Workspace6、Session16、Image10、Resource7、Probe14、Integration10、合計94件。Sessionへ4件を追加し、作成/保存の連続照合I/O失敗、照合中の新編集、照合後の新payload容量失敗からの縮小再保存を検証。旧候補CIはSession12/合計90件であり混同しない。

## 計測と実証範囲
100記事/対象1000操作準備後、タイトル200文字・導入/4本文/結び各1万文字で30保存を計測しp95<2秒を確認。全体中間runのp95は0.015692416秒。独立store再開10回は0.000323〜0.000610秒。アプリのcold起動10回とは区別。

4000x3000合成画像30回、5秒基線/25msサンプルで、記録済みrunは最大0.094417417秒、基線35,455,816 bytes、サンプル増分89,195,000 bytes。OS lifetime peak131,515,280は事前fixture由来のため、今回の短ピーク帰属は未確認。直接予約は実worker取消試験で保持/解放と256MiB以内を確認した。

全強制終了点、OS呼出停止、実写真/RAW/HEIF編集結果、実Sandbox、アプリcold起動の達成を上記の合成試験で代用しない。詳細runとRed→Greenは`tdd-evidence.md`。

## 残る作業・品質ゲート
1. ローカルUI runnerは今回XCTFuture Code=1000のautomation mode開始待ちで初期化不能。以前のLocalAuthentication Code=-4および旧候補CIの6件成功とは区別する。本人Macでの焦点/狭幅/閉じる/終了の全経路は別確認。
2. a108134でCore273件・Article UI6件成功、製品90.23%をCI確認。全体CIは既存Native8件の失敗でfailureを維持。同じrunの変更前baselineも同じ8件が失敗しており、新規回帰と区別する。CI greenの条件は未充足。
3. 今回修正後も製品80%基準を達成。対象/閾値は変更せず、新候補の実測値で判定している。ローカルの未実施/失敗や実機未確認をCIの測定値で補完しない。
4. 最小4枚表示/取得状態、画像待ち/不能時の本文保存、開始/日本語編集/手動保存/再起動再開/未保存継続/実合成1枚出力をCore・Article UIで検証。実写真/本人実機の操作を合成CIで代用しない。
5. 指定した保存/出力の書込・公開・同期checkpoint、容量不足、実権限喪失、片付け失敗、遅延取消、未知/不完全物保護は注入試験を実行済み。実プロセス強制終了、OS応答停止、電源断、OSパネル経由grantの寿命は別途実機確認が必要。例外注入を物理的な電源断保証とは扱わない。
6. 512MiBの短ピーク帰属、UI取消受理0.5秒、全実機経路の40秒、入力可能までのアプリcold起動10回は未実証。閾値を下げず追試する。

全割当AC/BR/詳細NFRは`traceability.json`へ列挙し、Core実証/部分/未確認/後続Unitを分離。U2の候補決定/日付フォーム、U3の四枚/Markdown/manifest/コピー/Finderは本Unitで完成を主張しない。本人手順と戻し方は`user-verification.md`。VoiceOver追加確認なし。
