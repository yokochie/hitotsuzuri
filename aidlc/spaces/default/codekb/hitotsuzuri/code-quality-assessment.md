# 品質・変更影響

## 検証基盤

4つのXCTest/XCUITest target。runnerはclass/methodを実ファイルから発見し、xcresultで選択試験のPassed/実行を確認、smoke2経路を必須とする。全機能bundleのApp/Core全手書きSwiftを加重集計して80%以上を検査する。実時間/実メモリ性能はCI全機能と別区分。今回試験/build/programは一切実行せず、新しい合否/件数/coverageは取得していない。

## 維持すべき強み

- expected保存版/operation UUID/正確なUTF8 fingerprintにより競合・結果不明・再試行を区別する。
- nofollow/fd相対I/O、directory identity、digest、非置換確定、所有確認cleanupで原本/既存成果物を保護。
- 出力は保存snapshot、4枚順序、2560px/sRGB/向き/GPS非継承を検証する。
- 取消と実処理終端、表示/出力資源、古いsession/request/jobの排除を分離し、前修正は後照会までCoordinatorの所有を維持。
- 合成fixture/専用root/試験pasteboardにより通常写真/データを自動試験で触らない。

## 今回の主要ギャップ

| 場所 | 観測事実と影響 |
|---|---|
| ArticleImageAccess.swift | callerもreader optionsもnetwork=false。readerのnetworkAllowed引数は実optionsへ反映されない。事前取得不要という今回の要求を満たさない |
| ArticleImageReading / ArticleExportImageProviding | completionとcancelだけでdownload progressが渡らない |
| ExportProgress / ExportSession / ExportView | fractionは型にあるが値生成なし。枚数＋indeterminateのみで長い取得の状態を説明できない |
| 取得/Delivery期限 | 30秒/枚、書込込み40秒、全体180秒。downloadに適した時間と変換/書込の既存制限を分けて検討する必要 |
| reader info/error | nil入力/urlやasset不在を同じassetUnavailableへ畳み、「写真アプリで事前取得」へ誘導。取得失敗を全て未ローカルと断定できない |
| 取消/実終端 | readerPendingがcallbackまで残る。通信追加後のPhotoKit cancel/progress stop/遅いcallbackと次要求の関係を契約化すべき |
| 既存tests | network=falseを明示assertする。出力policy変更に応じて更新が必要だが、Picker表示の通信禁止や予算を一律弱めない |
| README/画面説明 | 通信しないという現説明、事前取得手順、前表示修正を修正中とする記載。新実装成立後に現実と揃える候補 |

## 変更範囲と検証候補

主に出力reader/access→Delivery→Session→ExportView、ports/progress/failure、合成reader/testsが中程度の影響。Coordinatorの保存確認/後照会/表示復帰、現在編集結果の変換、Writer/Journalは契約を維持する。iCloud開始/進捗/成功、通信失敗・取消・期限、取消後の旧進捗/旧completion、次の出力・表示復帰、固定本文/順序、所有cleanupをテスト対象にする。

本人は出力時ダウンロードを明示許可した。旧memory/READMEの通信禁止と現在ソースのfalseは歴史的現状であり、本人の今回の指示より優先しない。実iCloud/Sandboxの確認は自動fake成功とは別に最後に本人Macで行う。全面改修、全library事前取得、Photos編集、権限resetの根拠はない。

追加指示330bdddaでは画像サイズによって遅くなってもよいと本人が回答。既存30/40/180秒を新通信へ機械的に適用するのでなく、取得完遂・取消・進捗・停止の扱いを要件化する。具体的な期限値と無期限待機はまだ決定されていない。
