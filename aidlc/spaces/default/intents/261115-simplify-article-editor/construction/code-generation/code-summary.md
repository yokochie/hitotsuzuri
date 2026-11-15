# 記事編集の実装結果

## 変更内容

- `Hitotsuzuri/ArticleView.swift` と `Hitotsuzuri/ArticleMetadataFields.swift` から導入文、写真ごとの文章、締め、撮影メモの入力欄を外した。タイトルと撮影日の候補操作を維持した。
- `Hitotsuzuri/ArticlePreviewView.swift` と `HitotsuzuriCore/ArticleProjection.swift` で本文の表示をそろえた。固定文を「【ダミー】」と表示し、記事プレビュー、コピー、Markdownで写真の並びとともに使用する。
- `HitotsuzuriCore/ArticleOutputPorts.swift` と記事出力の配信・記録・書き込みで、新規ジョブに形式2を使い、形式1の中断ジョブは旧本文で照合できるようにした。旧下書きの保存形式とフィンガープリントを維持した。
- `HitotsuzuriU2Tests/` と `HitotsuzuriU3Tests/` で本文変換、下書き、出力と復旧を検証した。`HitotsuzuriUITests/` のfixture操作をタイトルや日付候補に合わせ、対象欄の非表示とダミー本文の検査を追加した。

## 検証

- 変更前の対象Core試験は74件成功。新しい期待値を旧実装で確認したCoreのRedでは、16件中6件の試験が想定どおり失敗した。
- 変更後の対象Core試験は112件成功。失敗とスキップは0件。 `.build/ArticleEditorCore/Logs/Test/Test-Hitotsuzuri-2026.11.15_12-52-31-+0900.xcresult`
- アプリとUI試験はビルドできた。変更前後のUI試験はアプリを前面化できず、画面の検査に入る前に停止した（`Running Background`）。最終結果は `.build/ArticleEditorBaseline/Logs/Test/Test-Hitotsuzuri-2026.11.15_12-53-42-+0900.xcresult`。UIの動作確認に関わる計画のStep 5とStep 7は保留。
- Git差分の空白チェックは成功。全体の行カバレッジとGitHub Actionsの結果は未確認。実写真ライブラリでは未検証。

## UI再試験後の修正

- 日付候補の文言をアクセシビリティのラベルと値から検査し、下書き候補の操作を該当シートに限定した。写真の再取得は画像不足のfixtureを使用し、対象写真にのみ要求が1件増えることを検査する。
- 記事編集で写真4枚を通常のGridに載せ、出力後に画像が戻る際もセルが保持されるようにした。復帰試験では画像の座標を使ってスクロールし、実際の画像全体が表示領域に入ることを確認する。
- 画面ロック解除後の中間再試験では旧グリッドで写真3の失敗を再現した（10件中5件成功）。修正後は、前回失敗の10件と画面幅、キーボード、コピー、保存などの関連7件がすべて成功した。失敗・スキップともに0件。結果は `.build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.15_19-45-42-+0900.xcresult`。
- この修正を含む全機能試験、製品の行カバレッジ、GitHub Actionsと実写真での確認は次の段階に残る。
