# コード構成と分類

| 領域 | 主な責務 |
|---|---|
| HitotsuzuriApp、Info.plist、entitlements、Xcode project | 起動/依存生成、Sandbox、署名、target構成 |
| PickerView、ArticleView、ArticleMetadataFields、ArticlePreviewView、ArticleExportView | View、記事候補、編集、本文/写真表示、出力操作 |
| ArticleAppCoordinator | Controller。sessionと表示要求の同期、window終了、パネル、出力/回復の接続 |
| DebugFixture | 合成Photos・画像・選択・遅延、temporary/Application Supportの所有UUID領域 |
| Core Models、Ports、SelectionWorkflow、PhotoLibraryAccess、LocalImageAccess、SelectionPersistence | 選択モデル・use case・Photos/image adapter・設定/選択JSON |
| PickerContent、PickerPresentationState、PresentationSnapshot、PickerAccessibility、NativeFolderBrowser | 選択画面、階層、焦点、キーボード、表示状態 |
| ArticleModels、Ports、Fingerprint、Workspace、Persistence、FileSystem | 記事値・保存契約・canonical bytes・関連付け・operation/current・安全なI/O |
| ArticleEditSession、Presentation、MetadataInput、InitialContent、Projection、OutputPorts | 編集・手動保存・遷移・日付候補・本文/Markdown・出力契約 |
| ArticleImageAccess、ArticleImageConverter | 同一ファイル内の表示Previewsと、出力reader/要求/変換・memory budget |
| ArticleProbeDelivery、ArticleExport系 | 1枚検証、4枚の契約/実体/journal/Writer/Delivery/OSActions/Session |
| Diagnostics、FrameMeasurement、NativeMeasurement | 型付き診断、native入力/表示計測 |
| 4つのTests領域、scripts、.github/workflows | model/結合/UI/性能、選択契約、coverage、CI |
| docs | 設計提案・依頼資料 |

App→Coreのmodule依存。CoreからAppへのimportはない。外部package依存はない。詳細なcomponent区分は `component-inventory.md` に集約する。
