# U1 実装候補・未完了記録

## 状態
記事の開始/保存/再開、基本本文編集、4枚の最小画像表示、通信なしの画像1枚変換/別フォルダ出力を実装した候補。品質ゲートと実機確認が残るため、U1完了・統合可とは判定しない。候補commit732d203の後にも追加変更があり、最終変更はまだ公開していない。

最終ローカル全体検証: `bash scripts/verify-native.sh`、`.build/Native-20261104-151800-83081.xcresult`。**262成功、UI runner初期化障害1、exit65**。既存179件を維持し、Article83件（うち統合10件）が成功。Article UI6件は作成済みだが未実行。

全製品の重み付き行カバレッジは**2232/3006=74.25%**。80%未達。App/UI製品466行が未実行であり、除外/閾値変更は行っていない。`swift scripts/check-coverage.swift`は正しくexit1を返す。

## 実装と所有
- `ArticleModels/Ports/Fingerprint`: 選択4IDの順序、全本文/撮影情報保持型、版/日付/時刻検証、固定canonical/SHA256。基準ベクトルは`fingerprint-vectors.md`。
- `ArticleFileSystem/Persistence`: descriptor相対/no-follow、OS排他、不変操作/current確定、fsync/F_FULLFSYNC、operationID先行照合、旧ID結果、外部版競合、未知版/破損保護。rename後同期未確認はuncertainResultで残し、同ID再試行で再同期して照合。
- `ArticleWorkspace/EditSession`: 永続選択から直接解決、写真なし再開、候補あり無断作成防止、作業コピー/固定保存写し、保存中編集のdirty維持、二重保存拒否、離脱3択。
- `ArticleImageAccess/Converter`: PhotoKit現在編集入力URL、network=false、向き/sRGB/JPEG0.9/長辺2560/非拡大、元メタデータ非転記。30秒絶対期限、同時期限優先、単一実変換、256MiB予約。論理取消後も実workerが戻るまで予約/ゲートを保持。
- `ArticlePhotoPreviews`（ArticleImageAccess内）: 512px表示用経路を出力用JPEGと分離し、4枚の取得待ち/取得中/成功/失敗を番号別表示。取得不能や無応答で本文保存を止めず、二重表示要求を抑止。離脱後の遅延結果を世代で無効化し表示用保持を解放。
- `ArticleProbeDelivery/Journal`: 先頭1枚、内部jobID、一時物の識別、非上書き確定、画像digest照合、最小ローカル回復記録。bookmarkなし、再起動後は本人が同じ先を再選択。
- 不完全なfinalフォルダはcorruptDataとして残し、必須ファイル不在を「成果物なし」にしない。片付け権限失敗はcleanupFailureと残存場所を表示し、journalを保持する。receipt/画像/確定前の容量、rename後同期不確定、確定後応答喪失、未知一時物保護を試験済み。
- `ArticleAppCoordinator/View`とApp/Picker接続: 初期保存、タイトル/導入/写真4本文/結び、Command+S、戻る/閉じる/終了確認、保存記事を開く、Shift+Command+E、フォルダ選択、選択前grantなし/選択済み型/終端解放、結果先の表示。
- 通常診断は型付き段階/失敗分類だけ。本文/写真ID/人物/場所をsinkへ出さない捕捉試験を追加。
- 新Swiftは既存filesystem synchronized groupへ自動登録。pbxprojの変更不要。既存4試験target、共有schemeの本人差分、README/AGENTS等を保持。
- Sandboxの追加は`user-selected.read-write`のみ。新規依存/有料サービスなし。workflowはxcode-27、固定checkout SHA、contents:read、資格情報非保持、OS/Xcode/SDKログ、アップロードなし。

対象製品/試験/設定30パスはstrict schemaの`source-manifest.json`。承認計画の本文と試験指示は変更せず、完了したstepのcheckboxだけ更新。

Article成功件数: Model10、Persistence7、Recovery11、Workspace6、Session8、Image10、Resource7、Probe14、Integration10。Recoveryには別storeのOS flock競合拒否と実権限喪失、Imageには無応答中の本文保存と離脱後遅延無効化を含む。

## 計測と実証範囲
100記事/対象1000操作準備後、タイトル200文字・導入/4本文/結び各1万文字で30保存を計測しp95<2秒を確認。全体中間runのp95は0.015692416秒。独立store再開10回は0.000323〜0.000610秒。アプリのcold起動10回とは区別。

4000x3000合成画像30回、5秒基線/25msサンプルで、記録済みrunは最大0.094417417秒、基線35,455,816 bytes、サンプル増分89,195,000 bytes。OS lifetime peak131,515,280は事前fixture由来のため、今回の短ピーク帰属は未確認。直接予約は実worker取消試験で保持/解放と256MiB以内を確認した。

全強制終了点、OS呼出停止、実写真/RAW/HEIF編集結果、実Sandbox、アプリcold起動の達成を上記の合成試験で代用しない。詳細runとRed→Greenは`tdd-evidence.md`。

## 残る作業・品質ゲート
1. UI runnerはLocalAuthentication Code=-4「System authentication is running」で初期化不能。意図したUI Red/Green、既存UI焦点/狭幅/終了回帰を未確認。OS認証競合解消後、6件UIと全体検証が必要。
2. 公開pushは自動承認レビューで具体データ送信の明示承認不足として拒否された。CIは未実行。本人の送信承認後、最終変更と同commitのCI成功が必要。ローカルをCIとは呼ばない。
3. 製品80%未達。UI未実行の除外では解消しない。
4. 記事画面の最小4枚プレビュー/番号別取得状態を接続済み。表示待ち/取得不能でも本文保存可能なCore試験は成功し、実画面の操作確認はUI runnerのOS障害により未確認。
5. 指定した保存/出力の書込・公開・同期checkpoint、容量不足、実権限喪失、片付け失敗、遅延取消、未知/不完全物保護は注入試験を実行済み。実プロセス強制終了、OS応答停止、電源断、OSパネル経由grantの寿命は別途実機確認が必要。例外注入を物理的な電源断保証とは扱わない。
6. 512MiBの短ピーク帰属、UI取消受理0.5秒、全実機経路の40秒、入力可能までのアプリcold起動10回は未実証。閾値を下げず追試する。

全割当AC/BR/詳細NFRは`traceability.json`へ列挙し、Core実証/部分/未確認/後続Unitを分離。U2の候補決定/日付フォーム、U3の四枚/Markdown/manifest/コピー/Finderは本Unitで完成を主張しない。本人手順と戻し方は`user-verification.md`。VoiceOver追加確認なし。
