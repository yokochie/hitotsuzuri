# コード構成

## ターゲット
App、Core framework、U1/U2/U3 unit-test、UITestsの6 target。Xcodeのfilesystem synchronized groupsにより各ディレクトリを対応targetへ登録する。

## ファイル分類
| 場所・ファイル | 分類と責務 |
|---|---|
| Hitotsuzuri/HitotsuzuriApp.swift | Configuration: 実境界の生成、単一Window |
| Hitotsuzuri/PickerView.swift | UI: Core画面を起動しworkflow.startを呼ぶ |
| Hitotsuzuri/DebugFixture.swift | Test support: DEBUG限定のメモリ写真・画像・保存 |
| Hitotsuzuri/Info.plist、Hitotsuzuri.entitlements | Configuration: 表示名・写真説明・Sandbox |
| Core/Models.swift | Model: 編集選択と確定選択、復元・保存状態 |
| Core/Ports.swift | Contract/Model: 境界protocol、写真階層、画像・失敗・保存値 |
| Core/SelectionWorkflow.swift | UseCase: 探索・選択・確定・復元・応答の世代管理 |
| Core/SelectionPersistence.swift | Repository: JSON・版検査・退避回復 |
| Core/PhotoLibraryAccess.swift | Adapter: 写真ライブラリ読取、階層と所属検証 |
| Core/LocalImageAccess.swift | Adapter/Service: ローカル表示画像・期限・枠・LRU |
| Core/PickerContent.swift | UI: 3領域、写真・選択枠・保存状態、キー操作、表示画像変換 |
| Core/NativeFolderBrowser.swift | UI adapter: NSOutlineViewによる階層・複数選択 |
| Core/PickerPresentationState.swift | Presentation: 領域・展開・フォーカスID、compact判定 |
| Core/PickerAccessibility.swift | Presentation/Utility: 写真ラベル・グリッド移動 |
| Core/PresentationSnapshot.swift | Presentation: 状態から日本語表示へ投影 |
| Core/NativeMeasurement.swift、FrameMeasurement.swift | Utility: 任意の入力・表示計測証拠と判定 |
| Core/Diagnostics.swift | Utility: 失敗enumのみOSLog |
| HitotsuzuriU1Tests/ | Test: 基本モデル、写真・画像境界、保存、選択・結合 |
| HitotsuzuriU2Tests/ | Test: 復元・破損退避・競合・再試行 |
| HitotsuzuriU3Tests/ | Test: 表示・キー・資源・計測・保存成功境界 |
| HitotsuzuriUITests/NativeInputTests.swift | Test: synthetic appの実キー・マウス・狭幅操作 |
| scripts/verify-*.sh | Tool: 対象別Xcode試験、カバレッジ検査 |
| scripts/check-coverage.swift | Tool: 製品全体の重み付き行カバレッジ、80%閾値 |
| scripts/measure-native.swift | Tool: 開発者限定の画面照合測定 |

表中Coreは `HitotsuzuriCore/` を指す。データベースmigrationやHTTP controllerはない。

## 命名・配置の慣行
Swift camelCase/PascalCase、public境界と内部の実アダプタ、protocolとFake、MainActorのObservableな状態、actorの保存。小さな処理を同じ行にまとめる記法が多い。U2/U3のFake・helperには重複がある。

## ドキュメントと生成物
READMEは見出しだけ。docsはPhase1設計とPhase2以降の提案2点。設計資料はソースの証拠ではない。ビルド出力・個人Xcode設定は調査対象外。
