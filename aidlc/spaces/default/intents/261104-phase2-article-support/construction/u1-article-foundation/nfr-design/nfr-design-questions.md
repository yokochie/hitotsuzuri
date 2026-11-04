# U1 品質設計の確認

## 入力・既決事項
機能設計と品質要件の確認済み内容を引き継ぐ。画像30秒、書込込み40秒、変換1件、直接画像バッファ256MiB、プロセス増分512MiB、取消受理0.5秒/画像論理終端2秒。追加有料依存なし、標準macOS機能を基準とする。

## 調査の根拠
Apple公式資料で、PHContentEditingInputRequestOptionsの通信禁止指定、調整データを扱わない場合の現在編集済みデータ、fullSizeImageURL、Image I/Oの縮小サイズ/向き変換指定を確認した。API仕様は実機結果やメモリ目標の達成証明ではない。
- https://developer.apple.com/documentation/photos/phcontenteditinginputrequestoptions/isnetworkaccessallowed
- https://developer.apple.com/documentation/photos/phcontenteditinginputrequestoptions/canhandleadjustmentdata
- https://developer.apple.com/documentation/photos/phcontenteditinginput/fullsizeimageurl
- https://developer.apple.com/documentation/imageio/kcgimagesourcethumbnailmaxpixelsize

## Consolidated Summary Confirmation
- 写真は通信禁止の読取経路で現在の編集済みデータを受け取り、ファイル参照から記事用サイズへ縮小する。既存512pxキャッシュや埋込プレビュー画像を完成成果物として流用せず、元写真への書込APIを呼ばない。
- 元画像を全て同時に展開せず、1件ずつバッファ予約して処理する。縮小した画素をsRGBへ変換しJPEG品質0.9で新規生成、位置情報等の元メタデータはコピーしない。APIの現在編集/向き/色と実メモリは合成画像試験・本人実画像で検証する。
- 期限/取消は状態管理を1か所に集約し、遅延応答を無効化。OS処理を中断できない間もUIと論理終端を守り、資源が残る間は次の変換を始めない。出力先の未選択状態にはアクセス権を必須にせず、選択後だけ保持する。
- 記事保存は操作記録を不変に書き、最後に確定参照を切り替える。保存前後の同期・排他・参照検査を設け、操作ID照合を競合確認より先にする。異常終了時は確定記録だけを正とし、未参照候補を正常記事にしない。
- 指紋はWorkspaceの共通処理で版付き符号化とSHA256を使う。本文の空白/改行/Unicodeを変換せず、同じ値のテストベクトルをU2にも共有する。記事ID/保存版は指紋とは別に照合する。
- 通常ログは分類と処理段階に限定。計測は合成データで所要時間/バッファ/プロセスメモリを確認し、UIは文字で状態表示する。新しい外部監視・クラウド・通知を追加しない。
- 次の環境設計でSandbox・保存ルート・署名・CIを具体化し、コード計画と実装時の障害注入/実機検証で成立性を確認する。未実測を合格にせず、条件を満たせない点は実装前に明示する。

Does this all look correct before I generate the artifact?

- Looks correct
- Request changes

[Answer]: Looks correct
