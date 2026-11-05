# API・保存契約

HTTP/GraphQL/WebSocket endpointはない。以下はSwift内の境界である。

| 境界 | 主な操作・契約 |
|---|---|
| LibraryAccessing / LibrarySource | 認可・階層・album assets・4枚の参照検証。Photosを読取用途のみで使う |
| ImageAccessing / ImageDriving | image、cancel、release。表示/確定用を区別し、deadline・queue・memory budgetを守る |
| SelectionStoring | load/saveSettings、load/saveSelection、confirmSelection。missingと破損/未知版を区別 |
| ArticleStoring | create、open、list、save、resumeWithSelection。operationIDとexpected版で再試行・競合を判定 |
| ArticleWorkspace | readCommittedSelection、listDrafts、openArticle、resolveArticle。保存した写真順序が入力 |
| ArticleImageReading | request/cancel。PhotoKit編集結果をownerとともに保持、ネットワーク不可 |
| ArticleOutputActions | copyPlainText、runExport、cancelExport、revealExport。grantIDの登録と保存済み版の照合 |

`selection.json` と `settings.json` はschemaVersion 1のJSON。選択は識別子と順序・確定時刻を持ち、写真本体は恒久保存しない。

記事は `Articles/<projectID>/operations/<operationID>` にschemaVersion 1、previous、inputDigest、SavedArticleを保存する。 `current` はprojectID・operationID・operationDigestを持つ。文章のUnicode/改行は正規化せずdigestへ含める。ファイル読書き上限は64MiB、重複JSON keyと未知版は拒否する。

出力は `記事-<jobID>/article.md`、`manifest.json`、`images/01.jpg`〜`04.jpg`。manifestは入力版・順序・相対パス・2560長辺上限・JPEG quality 0.9・sRGB・非拡大を保持する。内部所有receiptは公開前に除去する。journalは親と作業folderの実体identity・生成digestを保持し、再選択時に回復する。

`ArticleFailure` はmissing、invalidReference、permissionDenied、capacity、conflict、uncertainResult等を区別する。記事読込のpermissionDeniedは写真認可を直接意味しない（`code-quality-assessment.md`）。保存形式変更の必要性は本調査では確認されていない。
