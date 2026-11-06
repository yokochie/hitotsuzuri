# APIと契約

## 外部接続

HTTP server/API endpointはない。PhotosのreadWrite authorizationを参照に用いるが、写真を変更するperformChanges等はない。画面はAppKit/SwiftUI、保存先はNSOpenPanelと一時security scope、コピーはNSPasteboard、表示はNSWorkspace。

## 内部境界

| API | 主な契約 |
|---|---|
| LibrarySource / LibraryAccessing | status/request authorization、hierarchy、album assets、4参照の再検証 |
| ImageDriving / ImageAccessing | request/cancel、display/validation、15秒deadline、release/資源snapshot |
| SelectionStoring | settingsとselectionのload/save、明示confirmで破損原本を退避 |
| ArticleStoring | create/open/list/save/resumeWithSelection、operation UUIDとexpected保存版で冪等/競合検出 |
| ArticleImageReading | request(assetID, networkAllowed, completion)→Int token、cancel(token)。現実装はnetwork引数を無視 |
| ArticleExportImageProviding | image(assetID, requestID)→JPEG、cancel(requestID)、busy/予算。進捗引数はない |
| ArticleOutputActions | copy、runExport固定入力/保存先/進捗、cancel、reveal |
| ExportProgress | jobID、stage文字列、completedImages、optional fraction。現状fractionを生成しない |

## 出力画像取得の現状

`ArticleImageAccess.image`は30秒deadline、単一current、取消handlerとtimerを持つ。`PhotoKitArticleImageReader.request`はPHAssetを検索し、PHContentEditingInputRequestOptionsのnetworkをfalse、canHandleAdjustmentDataをfalseにして現在の編集結果のURLを得る。PhotoKit callbackのinfo/errorは捨てる。asset/input/URL不在は同じassetUnavailable。progressHandlerは設定しない。入力ownerを変換完了まで保持し、出力JPEGは長辺2560・quality0.9・sRGB・向き焼込み・GPS等非継承。

公式APIにはnetwork許可と進捗callbackがあるため、呼出policy/進捗型/取消/期限の接続を設計する余地がある。出力改善のために表示用SystemImageDriverのnetwork=falseまで一律変更する必要はない。

- [Apple: isNetworkAccessAllowed](https://developer.apple.com/documentation/photos/phcontenteditinginputrequestoptions/isnetworkaccessallowed)
- [Apple: progressHandler](https://developer.apple.com/documentation/photos/phcontenteditinginputrequestoptions/progresshandler)

上記仕様は親が確認した参考資料。実Photosによる取得成功や、現在のアプリに実装済みである証拠ではない。

## 保存・出力の互換契約

schemaVersion1のJSON。記事はsource/photoID順序と本文・revision・fingerprintをvalidateする。PreparedArticleExportは投影と固定保存入力を照合し、manifestは4番号/設定/参照を照合する。Writerはfd/identity/digestを確認し、既存成果物を置換せず公開する。今回のiCloud改善を理由に保存形式変更や所有確認の省略を導かない。
