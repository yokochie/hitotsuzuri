# U1 品質機構と責務の対応

入力は`../nfr-requirements/`の6文書、`../functional-design/functional-spec.md`、`../../../inception/contract-design/contract-summary.md`。下表は既存の5責務へ配置する内部機構であり、新しい業務正本を増やさない。

| 機構 | 所有責務 | NFR/障害範囲 | 共有資源・環境設計への引継ぎ |
|---|---|---|---|
| ArticleStore / OperationReconciler | ArticleWorkspace | 記事正本・不可分保存・operationID重複/競合、障害は対象記事に限定 | Application Support、内部UUID、OS排他、原子的参照、同期 |
| CanonicalFingerprint | ArticleWorkspace | 保存内容と後続投影の一致 | Swift/CryptoKit、共通テストベクトル |
| EditSessionCoordinator | ArticlePresentation | 保存世代・未保存離脱・写真なし再開 | UI/MainActorと非同期I/O境界 |
| LocalArticleImageReader / Converter / ReservationLedger | ArticleImages | 通信禁止・元写真非変更・画像期限/資源、障害は画像操作に限定 | PhotoKit、Image I/O、sRGB、単一実行、OSメモリ計測 |
| DestinationScope / ProbeWriter / RecoveryRecord | ArticleDelivery | 1枚検証の確定/取消/片付け、旧成果物非変更 | Sandbox利用者選択先、排他的新規フォルダ、ローカル未完記録 |
| TypedDiagnostics / MeasurementSink | 各責務の境界 | 私的内容非ログ・数値証拠 | OSLog、合成fixture、通常診断と試験計測の分離 |

## 共通指紋の形式
入力はsourceとcontent。形式版1を先頭に置き、sourceはselectionID/albumID/albumTitle/orderedAssetIDs/confirmedAt/selectionRevision、contentは契約の定義順に固定。各値は型タグ、UTF-8バイト長の符号なし64bit big-endian、payloadの順。集合ではなく配列の順序を保持する。文字はそのままUTF-8、nullは専用タグ/長さ0、整数は符号付き64bit big-endian、配列は要素数と各値、日付は年月日の整数3値。時点はUTCのUnix epochからの整数ミリ秒へ明示的に丸めて保存し、その保存済み値を符号化する。日時の丸めは記事保存時の一度だけで、再計算時に別精度へ変換しない。

digestはSHA256。sourceSelectionIDs/createdAt/updatedAt/savedRevision/projectIDは含めず、別の識別/版照合に使う。操作入力digestはoperation種別/projectID/expectedRevision/入力source/contentを含む別ドメインタグで算出し、本文指紋との混同を防ぐ。空文字/null、CRLF/LF、結合文字/合成済み文字、写真順入替えを異なる入力としてベクトル化する。英数字だけの同じ入力がU1保存とU2投影で同じdigestになることも共有試験にする。

既存の選択時点がミリ秒より細かい場合、記事のsource作成時に丸めた写しを不変保存するが元selection.jsonは変更しない。projectIDが必要な後続投影には明示値で渡し、入力から推定させない。C3への具体化はU2が担当する。

## 設計判断
全文JSON一括再書込より操作ごとの不変記録、全原画像デコードよりURLから用途別縮小、取消後の即時次処理より実資源解放までのゲートを採用する。それぞれディスク記録数、デコーダ差、再試行可能になるまでの待ち時間という代償がある。安全性を性能目標より優先して未達を明示する。

この段階でAPI仕様は確認したが、アプリを動かした証拠はない。Infrastructure Designは実ファイルシステムの同期/排他、Sandbox・署名・CIを具体化。Code Generationは型・全コードと障害注入試験を実装し、承認済み検証コマンドと本人確認で結果を示す。未検証箇所を完了扱いせず、条件が成立しないなら実装計画で解決または本人判断へ戻す。
