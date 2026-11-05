# コンポーネント一覧

## App Composition
HitotsuzuriAppがSelectionPersistenceと写真adapter、ArticleAppCoordinatorを生成する。Coordinatorはwindow/application終了応答、保存先パネル、プレビュー開始、回復を接続する。通常起動とDEBUG合成fixtureはApp.initで分岐する。

## Selection Models and Ports
Models/Portsは確定4枚・順序・設定・認可・型付き失敗と、library/image/storage境界を定義する。

## Selection Workflow
SelectionWorkflowは復元/確定を共通deadlineとoperation/generationで管理する。全4枚の検証後に一括反映し、保存応答後の取消や認可変化から実保存の成功を分ける。

## Photo Library
PhotoLibraryAccessとSystemLibrarySourceはフォルダ再帰・アルバム・写真の読み取りと所属検証を担う。階層の重複・循環を除き、ライブラリ変更要求はしない。

## Local Images
LocalImageAccess/SystemImageDriverは表示用512px画像、queue/cache、同時枠、返却済みbufferまで含むmemory予算、deadlineと取消を管理する。

## Selection Persistence
SelectionPersistenceは設定/選択JSONを独立読込し、破損した確定選択の明示再確定だけで原本digest付き退避を作る。未知版と破損設定は保護する。

## Picker UI
PickerContent、PresentationSnapshot、PickerPresentationState、PickerAccessibility、NativeFolderBrowserが選択操作と画面状態を支える。幅820以下で領域切替、native outlineの複数選択/展開、焦点と写真順序を扱う。PickerViewは選択画面と記事画面を切替え、ArticleView群は編集・プレビュー・出力操作を表示する。

## Article Domain and Editing
ArticleModels/Ports/Fingerprint、Workspace、EditSession、Presentation、InitialContent、MetadataInput、Projection、OutputPorts。確定選択との関連付け、文章のbyte保持、手動保存、日付入力、未保存遷移、本文とMarkdown、保存済み出力入力を担う。

## Article Persistence and File Access
ArticlePersistenceは操作ログ/currentと競合・再試行を担う。ArticleDirectory（ArticleFileSystem.swift）はfd相対の安全なI/O・排他・同期・renameを提供する。記事読込に加え出力・journal・Finder前検査の共通依存である。

## Article Images
ArticlePhotoPreviews、ArticleImageAccess、PhotoKitArticleImageReader、ArticleImageConverter、ArticleImageBudget。表示と書出しを分離し、編集入力を保持して縮小・向き補正・sRGB JPEG化を行う。

## Probe and Export
ArticleProbeDelivery/Journalは1枚検証。4枚はExportModels/Manifest/FileSystem/Journal/Writer/Delivery/OSActions/Sessionで進める。OSActionsはgrant・pasteboard・Finder、Writerはfolder所有・digest・排他的公開、Deliveryは進行・期限・取消・回復、Sessionは表示状態を担う。

## Measurement and Diagnostics
Diagnostics/ArticleDiagnosticsは分類のみ記録する。NativeMeasurement/FrameMeasurementとmeasure-native.swiftは採用された選択変化・入力時刻・同frameの表示を照合する。画像/OCR全文を保存せず、通常動作では計測無効。時刻系/許可の不成立を成功へ丸めない。

## Verification Suite
4つのXCTest target、DebugFixture、scripts、GitHub workflows。旧選択と記事のmodel・永続化・回復・UI・性能を分け、runnerが実実行/skipを検査する。fixture写真・pasteboard・rootは通常データから分離する。計測の合否は機能CIと分ける。
