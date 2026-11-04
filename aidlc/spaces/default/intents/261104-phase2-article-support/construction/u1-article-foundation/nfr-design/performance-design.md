# U1 性能・画像資源の設計

入力: `../nfr-requirements/performance-requirements.md`、`tech-stack-decisions.md`、`../functional-design/functional-spec.md`、`../../../inception/contract-design/contract-summary.md`。本設計は実装方針で、実測済み性能ではない。

## 画像経路（NFR3.1 / NFR3.2 / NFR3.6 / NFR7.1）
ArticleImagesの単一実行ゲートで、要求状態・単調期限・予約バイトを所有する。PhotoKitの`requestContentEditingInput`で`isNetworkAccessAllowed=false`を毎回明示し、`canHandleAdjustmentData`はfalseを返して現在の編集済みデータを要求する。`PHContentEditingInput`と`fullSizeImageURL`の寿命を処理終了まで保持する。これは読取に限定し、`PHContentEditingOutput`や変更要求を作らない。

URLからImage I/Oの画像ソースを遅延作成し、元ファイル全体をDataへ読み込まない。型/寸法/向きを先に検査し、埋込小プレビューを使わず`kCGImageSourceCreateThumbnailFromImageAlways=true`、最大辺min(元の表示長辺,2560)で実画素から縮小する。向きは`fullSizeImageOrientation`を正とし、ソースEXIFと合わせて同じ向きを二重適用しないよう1度だけ正規化する。実装ではPhotoKitの向きとソース値の差をfixtureと実機で照合する。

縮小画素を8bit sRGBの明示的描画先へ変換し、JPEG品質0.9で新規生成する。出力の向きは画素へ反映済み、元メタデータ辞書をコピーしない。ICC/sRGB等の必要項目だけを出力しGPS/EXIF人物/場所等を引継がない。JPEG bytes・色空間・寸法・復号を確認して結果型へ渡す。Live Photoの静止画用URLが得られないケースはassetUnavailable、動画へフォールバックしない。

### 予約と上限
1. 画像ソースのメタデータ検査後、縮小画素のrowBytes×height、sRGB描画先、JPEG生成バッファ、既存結果を合計して予約する。オーバーフローはinvalidInput。作成時の実rowBytesを検証し、予約を超える場合は解放してcapacity。
2. 直接所有画像バッファは256MiBの単一予算。JPEG生成は上限付きのデータ受け口を使い、超えたら失敗。圧縮データを複製する返却/橋渡しも予約へ含める。画像結果を呼出側が保持する間も予約を移譲し、ローカル変数解放だけで予算が戻ったとしない。
3. PhotoKitによる表示サイズ画像やデコーダ内部は直接予約で完全には制御できない。プロセス実メモリ増分512MiBを別計測する。実APIで上限を保証できない画像を黙って許容せず、寸法/デコーダ種別の事前判定・対応可否の失敗分類を実装計画へ明示し、実測で成立しない経路は合格にしない。
4. 結果は出力後に破棄、原画像の恒久キャッシュなし。表示512pxキャッシュは別責務。処理終了は入力オブジェクト/画像ソース/描画先/エンコーダを解放してから実行ゲートを空ける。

## 期限と取消（NFR3.1 / NFR3.3 / NFR3.4 / NFR4.1）
要求の開始時にContinuousClockで30秒の期限を作る。タイマーとPhotoKit完了/変換完了/取消が同じ状態所有者へ届き、最初の終端だけを採用する。期限時はtimedOut、明示取消はcancelled。PhotoKitのrequestIDへ`cancelContentEditingInputRequest`を送る。同期デコーダは専用バックグラウンド実行上で動かし、UIタスクから切り離す。UIを塞ぐ同期待機や、取消不能な子タスクの完了を待たないと返らない構造にしない。

取消受理表示0.5秒、論理終端2秒の目標を守るため、終端後のOS応答には世代チェックで無効化を適用する。同期処理が残る場合は占有状態を維持し、次の変換は開始不可として理由を表示する。参照と予約は実処理が終わるまで保持し、論理取消だけで解放しない。処理再開可能性を偽る自動リトライはしない。

画像結果後の出力には残り10秒の書込期限を設け、正常ローカル先で合計40秒を測る。書込/renameが停止した場合の論理不確定状態と照合はreliability-designに従う。ユーザー選択の待機は時計区間から除外する。取消と確定競合は確定成功を正とし、UIの取消受理だけでは片付け済みにしない。

## 保存性能（NFR3.5）
記事ごとの最新確定参照を読み、開くときに全履歴を展開しない。履歴走査は同operationIDの再試行照合等で必要な時だけ逐次実行し、協調的な中断点を置く。保存は変更記事の新操作レコードと小さな確定参照だけを書き、全記事索引の再書込を成功条件にしない。通常編集の状態とUI更新はMainActor、保存/検査はI/O境界へ分離する。

基準データと30回以上の計測、cold起動10回、95%2秒目標はperformance-requirementsどおり。OSファイル同期を省いて目標達成に見せない。採用比較は全原画素デコード/表示用キャッシュ流用より、URLからの用途別縮小を選ぶ。代償はRAW等のデコーダ差と実機検証である。

## 一次資料と実証範囲
[現在編集済みデータ](https://developer.apple.com/documentation/photos/phcontenteditinginputrequestoptions/canhandleadjustmentdata)、[通信指定](https://developer.apple.com/documentation/photos/phcontenteditinginputrequestoptions/isnetworkaccessallowed)、[元サイズURL](https://developer.apple.com/documentation/photos/phcontenteditinginput/fullsizeimageurl)、[縮小上限](https://developer.apple.com/documentation/imageio/kcgimagesourcethumbnailmaxpixelsize)、[取消](https://developer.apple.com/documentation/photos/phasset/cancelcontenteditinginputrequest(_:))を参照。APIの存在/意味を確認した根拠であり、30秒/資源/実写真の合格証拠ではない。
