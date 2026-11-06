# コンポーネント一覧

以下はsource上の責務単位。ファイル分類はcode-structure.md、呼出契約はapi-documentation.md。

## App Composition
HitotsuzuriAppが通常/DEBUG依存を構成。通常Pickerと記事表示は同じLocalImageAccessを共有する。

## Picker Workflow
SelectionWorkflowが認可、フォルダ/アルバム、順序付き4枚、再検証、保存/復元を制御。PhotoLibraryAccess/SystemLibrarySource、SelectionPersistenceに依存。

## Picker UI
PickerContent/PickerView、NativeFolderBrowser、PickerPresentationState、PhotoSemantics/GridNavigation、PresentationSnapshot。SwiftUIとNSOutlineViewで狭幅/focus/文字状態を提供。

## Display Images
LocalImageAccess/SystemImageDriverが512px画像、cache/LRU、validation優先queue、15秒期限、生存buffer予算を管理。ArticlePhotoPreviewsが記事の4状態と番号別retryを持つ。

## Article Domain
ArticleSource/Content/SavedArticle、日付入力/初期候補、ArticleFingerprint。写真順と正確な文字bytes/版のvalidation。

## Article Persistence
ArticleWorkspaceが選択から記事を解決し、ArticlePersistenceがoperation/currentの保存/関連付けを管理。ArticleDirectoryのnofollow/fd相対I/O、lock、fsync、CASに依存。

## Article Editing
ArticleEditSessionが入力/保存snapshot/結果不明を保持。ArticlePresentationが候補/離脱/投影/コピー/出力lockを制御。ArticleProjectionContextがplain/Markdownを生成。

## Article UI Coordinator
ArticleAppCoordinatorと記事各View。AppKit確認/保存先、終了委譲、画像表示の停止/復帰UUID、出力所有期間を接続。

## Export Image Acquisition
ArticleImageAccess、PhotoKitArticleImageReader、ArticleImageConverter/Budget/JPEG。単一要求、content editing input、期限/取消/実終端、縮小/向き/色/metadata非継承。

## Export Orchestration
ArticleExportSession、ArticleOutputActions、ArticleExportOSActions、ArticleExportDelivery。固定保存入力、4枚順次処理、進捗、grant、取消、結果/照合/cleanup詳細を接続。

## Export Storage
ArticleExportWriter、ArticleExportJournal、ArticleExportManifest、ArticleExportFileSystemとrecovery model。所有・digest・phaseに基づく一時生成/非置換公開/復旧。

## Probe Output
ArticleProbeDelivery/JournalとCoordinator.probe。先頭一枚の検証出力で、通常4枚bundleとは記録/命名を分離。

## Diagnostics and Measurement
Diagnostics/ArticleDiagnosticsは分類だけをOSLogへ記録。NativeMeasurement/FrameMeasurementとscripts/measure-native.swiftは入力/描画と資源の計測を補助。

## Test Fixtures
DebugFixture、各TestDoubles、FixtureLaunch。実Photosと通常記事を避け、合成画像と所有UUID領域を使用。restore-*のみPicker adapter分離、通常共有構成は維持。

## Verification Tooling
native-test-runner.py、test-native-runner.py、check-coverage.swift、Bash入口、verify.yml。Core先行、smoke、全機能/coverageと別区分性能。DependabotはActions更新。
