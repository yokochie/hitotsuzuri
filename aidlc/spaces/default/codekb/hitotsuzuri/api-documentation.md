# API・状態・永続形式

HTTP/GraphQL等のAPIはない。主要境界は次のSwift protocol/型である。

| 境界 | 契約 |
|---|---|
| LibraryAccessing / LibrarySource | 認可、階層、album assets、所属/4枚検証 |
| ImageAccessing / ImageDriving | 表示画像要求、validation目的、deadline、cancel、release、資源数値 |
| SelectionStoring | 設定/選択の独立load/saveと明示confirm。missingと破損/未知版を区別 |
| ArticleStoring | create/open/list/save/resumeWithSelection。operation IDとexpected版 |
| ArticlePhotoPreviews | load/retry/cancel、番号ごとのwaiting/loading/ready/failed、isLoading |
| ArticleImageReading | 出力用編集入力request/cancel。networkAllowed=false |
| ArticleOutputActions | 本文copy、run/cancelExport、reveal。保存済み入力・grantを照合 |

表示PreviewsはMainActor Observableで、statesを初期化しloadが全番号を順次要求する。cancelは世代更新・全表示取消/解放・states空を実行する。retryは番号所属・非loading・states非空が必要。UIのnil/空状態の扱いは品質評価参照。

設定と選択はschemaVersion 1のJSON。記事は `Articles/<projectID>/operations/<operationID>` とcurrent参照を使い、入力digest・前操作・本文版を保持する。文章Unicode/改行を正規化しない。64MiB上限、重複JSON key、未知版・破損を保護する。

4枚出力はUUID別folder内にarticle.md、manifest.json、images/01.jpg〜04.jpg。JPEG、長辺2560以下、quality 0.9、sRGB、非拡大。journalは親/一時folder実体と生成digestを記録する。再起動後の保存先権限は再選択する。今回、保存形式変更の必要性は見つかっていない。
