# APIと保存契約

## 外部API
HTTP endpoint、認証サーバ、SNS投稿APIはない。SystemLibrarySourceとSystemImageDriverがPhotoKitを読む。認可はreadWriteレベルを要求するが、変更APIの呼出しは製品コードにない。authorized以外を拒否し、limited等はunsupportedとして扱う。

## 内部境界
| 境界 | 操作 | 契約 |
|---|---|---|
| LibrarySource | status、requestAccess、hierarchy、assets | OS境界。階層と写真ID一覧 |
| LibraryAccessing | requestAuthorization、hierarchy、albums、assets、validate | 複数フォルダの重複排除、所属と4件検証 |
| ImageDriving | request(assetID, completion)、cancel(requestID) | コールバックは暫定/最終画像、取得不能、取消、失敗 |
| ImageAccessing | image(validation, deadline)、cancelDisplayRequests、release(except) | ImageBuffer。validation時はキャッシュ迂回、共有期限を許容 |
| ImageClock | now、sleep | 単調時計、テストで注入可能 |
| SelectionStoring | load/saveSettings、load/saveSelection、confirmSelection | async。missing/valid/failureを区別。confirmの既定はsave |

## 操作API
SelectionWorkflowはstart、requestAuthorization、setTargetFolders、selectAlbum、loadImage、toggle、confirm、updateVisibleImagesを公開する。状態のsetterは外へ公開しない。canConfirmは認可・4枚・画像・ロード/保存状態等で判定。lastCommittedは直近の成功保存または成功復元に限って公開する。

## 保存スキーマ
| レコード | 内容・検証 |
|---|---|
| settings.json | schemaVersion=1、重複なし・空文字なしのfolderIDs |
| selection.json | schemaVersion=1、selectionID UUID、albumID非空、albumTitle、orderedAssetIDs非空かつ一意の4件、confirmedAt有限 |

JSON日はISO8601、確定時点は秒精度へ切捨て。Application Support/Hitotsuzuri配下。読み書き1 MiB上限、通常書込はatomic。未知版はunsupportedVersion、構文/意味破損はcorruptData、I/OはioFailureとして区別する。画像・記事・選択revisionは含まない。

## エラー
PickerFailureはauthorization、invalidReference、unavailable、ioFailure、corruptData、unsupportedVersion、timedOut、cancelled、capacity、oversizedData。日本語messageと失敗種別のみの診断ログを持つ。article/export固有のエラーはまだない。

## Phase2の互換性注意
確定のたびにselectionIDは新しい。現在のlastCommittedは画像検証失敗の復元で公開されないため、文章再開の入口をそこだけに結び付けると取得不能時に下書きへ到達できない。既存スキーマを壊さず記事用の保存・出力契約を追加する方式を後続で判断する。
