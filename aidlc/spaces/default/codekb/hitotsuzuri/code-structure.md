# コード構成

| 領域 | 分類と責務 |
|---|---|
| Hitotsuzuri/HitotsuzuriApp.swift、Info.plist、entitlements | 構成・依存生成・通常起動とDEBUG fixture分岐 |
| PickerView、ArticleView、ArticleMetadataFields、ArticlePreviewView、ArticleExportView | View。記事候補、入力、プレビュー、出力進捗・回復 |
| ArticleAppCoordinator | Controller。OSパネル・window終了確認・プレビューと出力の接続 |
| DebugFixture | DEBUG専用の合成ライブラリ・画像・保存root・遅延注入 |
| Core/Models、Ports | 選択モデル・型付き失敗・library/image/storage境界 |
| SelectionWorkflow、PhotoLibraryAccess、LocalImageAccess、SelectionPersistence | 選択UseCase・PhotoKit adapter・画像queue/cache・JSON repository |
| PickerContent、PickerPresentationState、PresentationSnapshot、PickerAccessibility、NativeFolderBrowser | 選択UIと状態・キーボード操作・NSOutlineView adapter |
| ArticleModels、ArticlePorts、ArticleFingerprint | 記事モデル・保存protocol・canonical digest |
| ArticleWorkspace、ArticlePersistence、ArticleFileSystem | 選択から記事への関連付け・操作ログ保存・POSIX fd相対I/O |
| ArticleEditSession、ArticlePresentation、ArticleMetadataInput、ArticleInitialContent、ArticleProjection、ArticleOutputPorts | 手動保存・遷移・日付候補・本文/Markdown生成・出力契約 |
| ArticleImageAccess、ArticleImageConverter | PhotoKit編集入力・要求寿命・縮小JPEG変換とmemory budget |
| ArticleProbeDelivery | 1枚の検証出力と専用回復journal |
| ArticleExportModels、Manifest、FileSystem、Journal、Writer、Delivery、OSActions、Session | 4枚出力の値・形式・実体照合・保存・生成・進行・OS操作・画面状態 |
| Diagnostics、NativeMeasurement、FrameMeasurement | 分類のみのログとnative計測値 |
| 4つのTests領域 | model/unit/integration/UI/性能のXCTestとtest doubles |
| scripts/ | bash入口、Python試験選択、Swift coverage/画面計測 |
| .github/workflows/ | 機能CIと限定診断 |
| docs/ | 設計資料。現行契約と区別して参照 |

AppはCoreをimportし、CoreからAppへの依存はない。Core内部は同一moduleのprotocolで実装を注入する。外部package依存や循環するpackage graphは見つからない。詳細なコンポーネント責務は `component-inventory.md` に集約する。
