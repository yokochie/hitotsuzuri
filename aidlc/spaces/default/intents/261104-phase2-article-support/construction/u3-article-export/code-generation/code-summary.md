# U3 記事と四枚の出力 実装記録

## 現在地
候補 `4a3b71d1e15795fedcba4e8a808addfff3ef2308` の正式CIが成功した。計画19項目の実装・検証・記録を完了した。実写真/Sandbox/Finder/noteの本人確認は未確認として分離し、main統合や配布は行っていない。

## 作成・変更
実変更29パスはsource-manifest.jsonに記載した（現存28パス＋U3で作成後に削除したArticleExportPorts.swiftの履歴）。

- Core8ファイル：固定入力/manifest、ファイル境界、Journal、Writer、Delivery、OSActions、Sessionを追加。既存ArticlePresentationへ出力中の差替え防止とコピー時の現在入力再照合を接続した。
- アプリ：ArticleExportViewと既存coordinator/ArticleView/DEBUG fixtureを接続。現在本文コピー、一式出力、保存判断、進捗・取消、固定完了本文コピー、Finder、再起動後の照合/明示片付けを提供する。
- 試験：U3 Core83件（Contract3/Model8/Journal8/Writer21/Delivery8/Session8/OSAction8/Integration19）、UI8件、別実行の性能2件。既存ArticleDraftUITestsのコピーdisabled期待1箇所だけをU3の有効化に合わせ変更した。
- runner：U3ラッパーと共通runnerを追加/更新。短い契約28件。診断workflowは作業branch＋明示commit markerで単一ケースだけを実行し、所有する合成fixtureのxcresultを1日保存する。

## 主要な実装判断
C2/C3のSavedExportInput/PreparedArticleExport/ArticleOutputActions、U2投影、ArticleDirectoryを再利用した。記事保存schemaや選択原本を変更する移行はない。

manifest版1はISO8601日時、固定した順序/指紋/相対パス、sRGB/JPEG0.9/長辺2560/非拡大を保持する。親/stage/imagesの実体識別と生成済み各ファイルのdigestを保持し、公開前後に全一式を照合する。非置換公開、同ID照合、結果不明時の回復を実装し、差替え物や旧完成物を削除しない。

片付けはreceiptだけを各ファイルの所有証明に広げず、実在する全ファイルが記録済みパス/digestと一致することを要求する。未生成の既知名・部分bytes・外部変更・seal conflictは保護する。同一親でstage/finalが不在の中断は削除なしで記録を終端化でき、途中片付けでは残る記録済みbytesだけを照合して再開する。生成前/片付け完了後の中断から新しい出力を開始でき、成功成果物を捏造しない。

制御actorとWriter/JournalのI/O actorを分離し、四枚を取得→変換→書込→解放の順で一枚ずつ処理する。単調時計の30秒/40秒/180秒、取消受理と実処理収束、表示と変換を合わせた256MiB予約を扱う。出力前に表示プレビューを解放し、出力中の再取得を抑止する。

コピー/Finder結果は出力成功と別表示にする。現在入力と固定完了本文を区別し、古い記事の結果操作を抑止する。固定コピーボタンは通常マウス時activate、独立したキーボード要求を有効化した更新後に実FocusStateを要求する。実マウスと未設定環境のTab/Spaceの両方を確認した。専用pasteboard/注入Finderを自動試験に使い、本人のgeneral clipboardや実Finderを試験で操作しない。

## 検証結果
[正式CI41994393925 attempt2](https://github.com/yokochie/hitotsuzuri/actions/runs/41994393925/attempts/2) は同一候補で成功した。

| 検証 | 実結果 |
|---|---|
| runner契約 | 28件成功 |
| Core前提 | 454件成功・0skip |
| 起動smoke | 2件成功・0skip、`.build/Smoke-20261105-083111-a2676144b5ab43af9078f84e0406b6ca.xcresult` |
| 単一主bundleの全機能 | 517件成功・0skip、`.build/Native-functional-20261105-083248-9aaa1089704348aeb6e60aee5962f25e.xcresult` |
| 製品全体の加重行coverage | 5227/5739＝91.08%。全製品の同一主bundleで判定し、checkerと80%条件は変更していない |
| CI-host固定コピー診断 | 1件成功・0skip。macOS27.0.1/Xcode27.1、AppleKeyboardUIMode未設定で実マウス/22Tab focus/Space/固定/dirty成立 |
| 本人承認後の同一ローカルUI | 1件成功・0skip・exit0、39.816秒、`.build/U3-fixed-copy-local-authorized-retry-4a3b71d.xcresult` |

実アサーションRed→Green→整理と途中の失敗/環境停止はtdd-evidence.md、CI-hostの原因切り分けはdiagnostic-evidence.mdに保持した。以前の504/505や計測失敗を成功へ読み替えていない。

新規性能2件は実Macで成功した。通常四枚30回p95は1.001353625秒。片付け変更に関係するメモリ/取消ケースは候補4a3b71dで更新し、プロセス増分153322216bytes、直接画像112197632bytes、最大観測間隔0.031540209秒、取消30回の受理最大0.000571459秒、画像論理終端最大0.000258292秒、cleanup p95 0.168357959秒で各基準内。全試行と環境はperformance-evidence.md。正常p95専用ケースを無関係に反復していない。

## 計画との差分と運用
宣言だけのArticleExportPorts.swiftはコンパイルに含まれていたが手書き実行行がなく、初回CIの全ファイル計測検査で欠落になった。全宣言を所有元Delivery/OSActionsへそのまま統合し、作成したPortsだけ削除した。公開API・実行行・checker・80%条件は保持し、dummy行や除外は追加していない。不要なHitotsuzuriApp.swift変更は行わなかった。診断workflowと既存コピー期待1箇所の更新は必要な実変更としてmanifestへ含めた。承認済み計画本文/テスト指示は変更していない。

本人e97e172fの方針に従い、通常自動試験はCI優先とし、同じ目的のローカル全体検証を重複させない。ローカルUIは本人の明示依頼/承認時だけとし、実機専用性能/実写真確認は必要な機会をまとめる。直近のローカルUIは本人5fc4a689の明示依頼によるものだった。今回の正式全機能/coverageはCIのみで実行した。

## 残る本人確認と戻し方
traceability.jsonはtool由来46ID（18AC/16詳細NFR/12BR）を保持する。NFR5.30は正式CI/coverageで確認済み。U2所有2ACはN/A。AC1.8.4/NFR7.30/BR3.12は本人の実写真・編集/回転/色/GPS除去・実Sandbox保存先・実Finder・note受渡しの未確認GAPを保持する。user-verification.mdへ条件/手順/未確認を日本語で記録した。実装/合成試験のOK対応を手動確認成功へ広げない。生成した自動試験に未実行ケースはない。

環境はローカルmacOS27.2/Xcode27.2/Mac15,3 arm64、CI macOS27.0.1/Xcode27.1。本人のscheme/README/既存記録は保持した。戻す際はアプリを終了し、既存下書き・成果物・未完記録を保護したまま以前の候補を別checkoutからビルドする。今回のmanifestを変更範囲の基準とし、未知版/所有不明物を一括削除しない。
