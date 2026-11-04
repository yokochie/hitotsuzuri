# 共通指紋 v1

所有: `HitotsuzuriCore/ArticleFingerprint.swift`。後続Unitは`ArticleFingerprint.content(source:content:)`を利用し、別実装を作らない。

各値は1 byte型タグ（null=0、UTF-8文字列=1、符号付き整数=2）、8 byte unsigned big endianのpayload長、payloadの順。整数payloadは8 byte signed big endian。名前も文字列として書く。配列は固定フィールド名、整数件数、順序付き要素。文字列の正規化/trim/改行変換なし。UTC時点は1970年起点のmillisecondへ丸めた整数。SHA-256を小文字hexで返す。

先頭domainは`hitotsuzuri.article.content.v1`。source順序は`selectionID, albumID, albumTitle, orderedAssetIDs, confirmedAtUTCms, selectionRevision`。content順序は`title, introduction, photoTexts, closing, shootingDate, dateCandidateState, location, equipment, film, people`。写真本文は`assetID,text`。日付はnullか`year,month,day`の整数。projectID/保存版/保存日時/追加選択関連は含めない。

基準source: selectionID=`11111111-1111-1111-1111-111111111111`、albumID=`album`、albumTitle=`記事`、orderedAssetIDs=`[a,b,c,d]`、confirmedAt=`1970-01-01T00:00:00Z`、selectionRevision=1。

基準content: title=`記事`、導入/各写真本文/結び/撮影情報は空文字、shootingDate=null、dateCandidateState=`absent`。

- canonical長: 848 bytes
- SHA-256: `c371afcd1918af5e9d37c02cc94c6dfbd059aeee0aa0e26ea8b86aa1e5af26a3`
- 独立したPython struct/hashlib符号化と`ArticleModelTests.testPublishedReferenceVectorMatchesIndependentEncoding`で照合。
- null/空文字/改行/Unicode正規化前後/配列順序は既存ArticleModelTestsで差を確認。

初回候補commitの未公開指紋にはフィールド名が不足していたため、本Unit実装中に是正した。正式利用前の合成データのみであり、旧候補のテスト下書きを互換保存形式とは扱わない。
