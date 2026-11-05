# U1 GitHub CI 実行記録

## 初回の公開実行

- 本人承認: メッセージ `62872c58`。公開リポジトリへの作業ブランチ送信とCI実行、提供文書のコピーを含む内容を承認。
- ブランチ: `codex/phase2-u1-article-foundation`
- commit: `e9db8a440652fd74de813259954aa732a3d2645e`
- 実行: https://github.com/yokochie/hitotsuzuri/actions/runs/41785896792
- trigger: push。標準 `xcode-27`、Xcode 27.1 / macOS 27 SDK。
- コマンド: `bash scripts/verify-native.sh`
- 結果: exit 65、失敗。Core 262件成功。UI 32件実行、14件失敗（Article 6件、既存NativeInput 8件）。UI失敗により後段の全体coverage検査は未実行。ローカル74.25%をCIの測定値として扱わない。

ArticleFoundationUITestsの全6件は `open` 内の `article-open` Button検索に失敗。ログの入力階層はApplicationのみ。画面起動・準備・fixtureと既存操作への影響を調査する。

NativeInputTestsの失敗は次の8件。既存テストを除外したり期待値を弱めたりせず、実装差分と環境差を切り分ける。

- testAlbumArrowsInCompactAfterMouseSelectionFollowPhotos
- testCompactAlbumTabCanActivateEnabledConfirm
- testCompactConfirmShiftTabReturnsToAlbumRow
- testCompactPhotoTabCanActivateEnabledConfirm
- testCompactPhotoTabConfirmAndShiftTabReturnCanSave
- testPhotoTabWithEnabledConfirmCanSaveBySpace
- testSingleTabFromAlbumOperatesPhotoAndShiftTabReturns
- testTabReentryPreservesMultipleFoldersAlbumAndPhotoDraft

送信はGitHub CLIの既存認証をcredential helperとして使用。資格情報の取得・記録は行っていない。公開pushの承認は成功として記録され、以前の自動承認拒否とは区別される。

## 起動・記事入口の修正後

- commit: `fea90baf4575aee547f04ae4b71344969ca3c569`
- 実行: https://github.com/yokochie/hitotsuzuri/actions/runs/41787840317
- 結果: exit 65。Core 262件成功、UI 32件中14件失敗。Article 6件はwindow待機に失敗し、Application Disabledとメニューバーのみを記録。既存NativeInputの8件も初回と同じ失敗。
- 変更: SwiftUIのアプリdelegate直接置換を標準Adaptorへ変更、記事入口を確定後のみ表示、fixture選択ID/設定の整合、画面/入口待機。
- 解釈: これだけでは失敗を解消していない。後段coverage検査は未実行。起動・ウィンドウ接続・入力focusを追加調査する。
- 保存修正 `d2b4d47` はこのrunに含まれない。ローカルでは修正後Core 269件、Article 90件成功だが、UI認証障害のため全体コマンドはexit65。ローカル全製品カバレッジ2245/3026＝74.19%。

## 起動引数・ウィンドウ接続の追加修正後

- commit: `2d5f13ed9c24faa198c4350207da984d92622607`
- 実行: https://github.com/yokochie/hitotsuzuri/actions/runs/41789820697
- 結果: Core 269件成功、Article UI 6件中5件成功、Native UI 26件中8件失敗。全体exit65。
- 記事windowと入口へ到達し、日本語保存・再起動再開・4本文欄・画像なし編集・1枚出力が成功。残るArticle UIは未保存離脱の確認ボタンに複数matchし、操作対象の限定が必要。
- Nativeの8件は初回と同じ。Keyboard navigation設定差の仮説は未確定。本人MacのAppleKeyboardUIModeは読取確認で0、設定変更なし。
- 次のCIで、変更前commit `0e96d28407dc6b634ef492dcbbf7533e7c665c3a` の全体検証を独立診断jobとして実行する。標準xcode-27、読取権限、追加有料機能/秘密情報/成果物アップロードなし。今回の製品試験を除外・置換しない。
- 次のCIでは製品テスト失敗後にも既存coverage checkerを診断実行する。元の失敗は維持し、成功時のみの測定では見えなかった到達範囲を確認する。

## 変更前との比較・記事UI修正後

- commit: `109a21e0232a36ad15b545d9441744abff0c626b`
- 実行: https://github.com/yokochie/hitotsuzuri/actions/runs/41791281896
- native job: `126445000888`。Core 269件全成功、Article UI 6件全成功、既存Native UI 26件中8件失敗。元のテストstepはexit65を維持。
- baseline-native job: `126445001132`。変更前commit `0e96d28407dc6b634ef492dcbbf7533e7c665c3a` のNative UI 26件中8件失敗。失敗したテスト名・assertionは変更後と同じ8件で、今回追加の回帰とは認定しない。CI環境での継承失敗として未解決のまま記録する。
- native失敗後の既存checker: **製品全体2747/3046行＝90.18%**、80%基準達成。対象ソースや閾値の変更なし。検査stepは成功したが、run全体はfailure。
- 主要到達行: ArticleAppCoordinator 141/206、ArticleView 136/140、DebugFixture 71/80、HitotsuzuriApp 27/37、PickerView 24/28。
- 記事の日本語保存・再起動再開・4本文欄・写真表示不可でも編集・未保存離脱の継続・画像1枚出力がすべて成功。確認sheet/dialogの操作対象を限定し、写真選択画面から記事用AppKit接続viewを除いた。
- KeyboardUIMode: CIでは明示設定なし。本人Macは読取確認で0。原因をこの設定と断定せず、いずれも変更していない。
- 実写真の現在編集/向き/色・元ライブラリ非変更・実機Sandbox・cold起動等の未確認は、自動UIの成功で補完しない。CI全体の成功・統合完了は主張しない。

## 不確定保存の再照合中エラーへの追加修正

- 本人指示: メッセージ `80bd28e1`。残存する保存不具合の修正を優先。
- commit: `a10813469df938a4f193483c996bd300e86beed1`
- 実行: https://github.com/yokochie/hitotsuzuri/actions/runs/41798035585
- 変更: PendingSaveごとに結果不明の状態を保持。照合時の一時I/O失敗では元操作ID・固定入力・基準版を保持し、照合成功後に開始した新しい保存の確定失敗とは区別する。
- ローカル: 追加3経路の実Redを確認後、狭域16件成功・整理後16件成功。専用全試験のArticle Core94件成功。UIはautomation mode開始待ち（XCTFuture Code=1000）で起動できず、コマンドはexit65。
- 今回CIのnative job `126466723519`: Core273件全成功（154+48+71）、Article UI6件全成功。既存Native26件中8件が失敗し、テストstepはexit65。
- 失敗後の既存coverage checkerは **2752/3050行＝90.23%**、80%基準を達成。今回候補の実測値であり、旧候補109a21eの90.18%を流用していない。
- 同じrunのbaseline-native job `126466723018` でも、旧製品のNative26件中同じ8件が失敗。期待値・対象・閾値を緩和せず、run全体のfailureを維持。

## 本人Macでの検証待ち

- メッセージ `82ad3dcf`: 本人はローカル環境へしばらくアクセスできないと回答。認証画面の有無は未確認であり、表示されていないとは推定しない。
- 読取診断 `/usr/sbin/DevToolsSecurity -status` は `Developer mode is currently disabled.`。状態を変更していない。この値だけでUI起動障害の原因を断定しない。
- macOS標準manページでは、このツールはApple署名のデバッガ/性能解析ツールに対する認証方針を変更すると説明される。今回有効化・権限変更・認証の回避は行っていない。
- 本人MacでのUI起動と実写真/Sandboxの確認は未実施のまま。CIと独立して扱い、検証失敗を承認済みに変更しない。
