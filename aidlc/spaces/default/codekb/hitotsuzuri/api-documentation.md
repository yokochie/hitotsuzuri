# アプリ内の契約と入出力

| API・契約 | 動作 |
| --- | --- |
| `LibraryAccessing`、`SelectionWorkflow` | 写真アクセス許可、フォルダ・アルバム・写真の読取り、選択4枚を検証・確定。ランダム選択は表示対象のアルバムと現在の操作世代を照合する |
| `ImageAccessing`、`ArticleImageReading` | 表示画像と出力画像の取得。進捗・キャンセルとPhotoKitのネットワーク可否を境界で扱う |
| `SelectionStoring`、`ArticleStoring` | 設定・確定選択、記事の一覧・読込・作成・保存・選択関連付け。記事保存は操作ID・期待する保存版を持つ |
| `ArticleMetadataInput`、`ArticleEditSession.validatedContent()` | 撮影日の年・月・日の入力を検証し、候補と確認済みを区別して記事内容へ反映 |
| `ArticleProjectionContext.renderArticle(source:content:)` | 記事ID、保存内容のフィンガープリント、プレーンテキスト、Markdown、固定順の相対画像パスを返す |
| `ArticlePresentation.showPreview()`、`copyCurrent()` | 保存前の現在の入力を変換。プレビュー画面は、表示時にタイトルと本文を `ArticleContent` から描く |
| `ArticlePresentation.prepareSavedExport(_:)`、`PreparedArticleExport` | 未保存の内容への選択を処理し、保存済みの版とその変換結果の一致を検証 |
| `ArticleOutputActions`、`ArticleExportSession` | クリップボード、出力、取消し、Finder操作。完了後のコピーは `ExportResult.fixedPlainText` を使う |

## ファイルの契約

- 選択・記事・出力の進捗はローカルに保存する。`SavedArticle` v1は既存の本文と撮影メモ項目も保持し、`ArticleFingerprint` がデータ破損検査に使われる。
- 完成出力のファイルは `article.md`、`manifest.json`、`images/01.jpg` から `images/04.jpg`。manifestは記事・選択・保存版の識別子、入力フィンガープリント、写真の順序・相対パス、JPEG設定を記録する。
- `ArticleExportRecoveryRecord` v1は保存済み記事、固定本文、Markdown、出力実体と作成済みファイルのダイジェストを持つ。検証時にその記事を再変換し、固定本文とMarkdownをバイト単位で照合する。
- OS境界に写真ライブラリのアクセス許可と選択フォルダへの権限がある。アプリ独自のHTTP APIは見当たらない。
