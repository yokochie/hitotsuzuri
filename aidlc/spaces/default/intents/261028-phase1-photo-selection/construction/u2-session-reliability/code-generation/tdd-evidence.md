# U2 TDD実行証跡

契約: sha256:4ba63934ae5f6408d359e3811f73cf0232b97ecb35978a9430d5b1189d83d14f。指定のU2専用xcodebuildコマンドを使用。XCTest実行権限を拡張して実行し、権限エラーをRedに数えない。

- 既存基準: U1 60件成功。結果 .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.01_11-05-01-+0900.xcresult。
- runner準備: U2 1件成功。結果 .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.01_11-05-39-+0900.xcresult。
- モデルRed: testInvalidDateRejectedのXCTAssertFalseが実際に失敗（6件中1失敗、11-06-04）。Green: 有限日時の意味検証を追加して6件成功（11-06-39）。Refactor: 復元と2種の保存状態を独立値にし8件へ拡張、後続実行でも成功。
- 保存Red: 退避未実装によるcorruptData（正常回復2件、衝突分類1件の計3失敗、11-07-07）。Green途中でprotocol extensionの非同期既定実装が選ばれたため、明示回復実装をasyncで適合させた。Refactor後17件すべて成功（11-08-05）。退避前/検証後/置換前の注入失敗、原本変更、再利用、衝突、未知版、過大、symlink、設定保護を検証。
- 業務Red: 復元未実装で31件中24アサーション失敗（11-08-33）。正常4枚、全破棄、有効フォルダ保持、再試行、凍結と重複拒否の期待を固定してから実装。

上記時刻はすべて .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.01_<時刻>-+0900.xcresult を指す。

## 後半のRed・Green・Refactor

- 業務Green: 31件成功（11-09-58）。復元と確定で同じ画像検証を返却型まで共有し、全4枚の画像を内部で保持して成功時だけ公開するよう整理した。
- 境界拡張: 重複起動、権限喪失、共通期限ちょうど、古いアルバム応答、再試行の画像再検証を追加。Fakeのラッチが2回目の階層取得で再待機した2実行は停止した。これはRedと数えない。ラッチを一度開いたら再待機しないよう修正した。重複起動の最終階層件数は、起動1回+現在参照検証1回の計2回という正しい境界期待に訂正した。
- 表示Red: 43件中、表示の4失敗（復元中、破損後の次操作、設定保存失敗の独立案内、権限優先）。結果11-12-08。上記の階層件数期待の失敗は製品Redから除外する。
- 表示Green/Refactor: 文言投影と再試行ラベルをPresentationSnapshotへまとめ、全編集UIをisEditingFrozenに接続。43件成功（11-12-48）。正常復元をログへ出さず画面だけへ表示する。
- 結合Red: 保存→新Workflow→復元、未保存非復元、破損退避後の明示確定、置換失敗→明示再試行、未知版拒否、過大原本を実ファイルで検証。48件中、過大原本の案内2アサーションが失敗（11-13-21）。他4境界は既存実装で初回からGreen。
- 結合Green/Refactor: 過大原本をoversizedDataへ分け、回復可能な破損と案内を分離。48件成功（11-13-47）。既存check-coverage.swift、verify-u1.shの内容は変更していない。

## 全体回帰とカバレッジ

実行:

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriU1Tests -only-testing:HitotsuzuriU2Tests -enableCodeCoverage YES -derivedDataPath .build/DerivedData CODE_SIGN_IDENTITY=- test
swift scripts/check-coverage.swift .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.01_11-13-56-+0900.xcresult
```

U1 60件、U2 48件、全108件成功。テストとカバレッジはそれぞれ終了コード0。
結果の絶対パス: /Users/yokochie/works/yokochie/hitotsuzuri/.build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.01_11-13-56-+0900.xcresult。

| 製品ファイル | 被覆/実行行 |
|---|---|
| HitotsuzuriApp.swift | 0/7 |
| PickerView.swift | 0/2 |
| Diagnostics.swift | 2/2 |
| LocalImageAccess.swift | 135/162 |
| Models.swift | 27/27 |
| PhotoLibraryAccess.swift | 38/131 |
| PickerContent.swift | 288/300 |
| Ports.swift | 36/36 |
| PresentationSnapshot.swift | 27/28 |
| SelectionPersistence.swift | 116/120 |
| SelectionWorkflow.swift | 185/187 |
| 全体 | **854/1002 = 85.23%** |

全App/Core Swiftを分母に含め、View・アダプタ・入口を除外していない。個人Photos/OS許可UIを実行しないため入口と実ライブラリアダプタの未被覆が残る。Fakeでの成功を実機成功としない。既存CoreSimulatorの版警告とNSHostingView内のautoShortcut接続警告は出るが、macOS XCTestは成功した。

bash scripts/verify-phase1.shは新しい最終検証候補として追加しただけで未実行。最終検証指定の変更は本人承認待ち。CI省略は既承認の変更決定を適用した。
