# コード構成

| 場所 | 役割 |
| --- | --- |
| `Hitotsuzuri/HitotsuzuriApp.swift`、`PickerView.swift` | アプリの構成、写真選択画面と下書き一覧への入口 |
| `Hitotsuzuri/ArticleAppCoordinator.swift`、`ArticleView.swift`、`ArticleMetadataFields.swift`、`ArticlePreviewView.swift`、`ArticleExportView.swift` | 記事の画面・入力・プレビュー・システム操作の窓口 |
| `Hitotsuzuri/DebugFixture.swift`、`Info.plist`、`Hitotsuzuri.entitlements` | 合成写真による試験用構成、アプリ情報と権限 |
| `HitotsuzuriCore/` | ドメイン値、状態遷移、純粋変換、I/O契約と実装。機能とファイルの対応は `component-inventory.md` を参照 |
| `Hitotsuzuri.xcodeproj/` | アプリ、Coreと4試験ターゲット、共有スキーム |
| `HitotsuzuriU1Tests/` | 初期写真選択・画像・記事モデル、保存、関連・復旧・検証出力 |
| `HitotsuzuriU2Tests/` | 選択復元・状態表示、記事編集と日付・初期内容・変換、移動と出力準備 |
| `HitotsuzuriU3Tests/` | レイアウト・操作・計測、記事完成出力の契約・書込み・検証・復旧 |
| `HitotsuzuriUITests/` | fixture起動、キーボード、下書き、保存先、画像復帰、記事出力と性能計測 |
| `scripts/`、`.github/` | ローカル・CI検証、カバレッジ、計測、診断とActions依存更新 |
| `README.md`、`docs/` | 利用・検証手順、元の要望と設計資料 |

本番アプリはSwiftUIの画面構成、Core内に状態とデータ処理を置く。選択UIの `PickerContent` とネイティブのフォルダリストもCoreにある。試験では各層のポートを差し替える。
