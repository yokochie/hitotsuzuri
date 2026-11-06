# コンポーネント一覧

## App Composition
HitotsuzuriAppが通常adapterとCoordinatorを生成し、DEBUG時に合成fixtureへ分岐。Coordinatorがsessionと画像owner、OSパネル・window終了・出力を接続する。

## Selection Models and Ports
4枚・順序・認可・設定・保存状態・型付き失敗と、library/image/storage境界。

## Selection Workflow
復元/参照検証/確定をdeadlineとgeneration/operation IDで管理。全4枚検証後に一括反映し、確定後の取消/認可変化と保存成功を区別。

## Photo Library
PhotoLibraryAccess/SystemLibrarySource。フォルダ再帰・重複/循環排除・アルバム所属・写真参照。読取用途のみ。

## Local Images
LocalImageAccess/SystemImageDriver。表示512px、queue/cache、同時枠、返却bufferを含む予算、取消とdeadline。

## Selection Persistence
settings/selection JSONを独立処理。破損選択の明示再確定だけで原本digest付き退避を作成し、未知版/破損設定は保護。

## Picker UI
PickerContent/PresentationSnapshot/PickerPresentationState/PickerAccessibility/NativeFolderBrowser。階層選択、native outline、狭幅領域切替、焦点、4枠。PickerViewが記事画面へ切替える。

## Article Domain and Editing
Models/Ports/Fingerprint/Workspace/EditSession/Presentation/InitialContent/MetadataInput/Projection/OutputPorts。確定選択との関連、手動保存、日付候補、未保存遷移、本文生成。

## Article Persistence and File Access
ArticlePersistenceのoperation/current、再試行・競合。ArticleDirectoryは対象の全成分nofollow直接open、ENOENT時のみ不足部分生成、fd相対I/O・排他・同期を提供する。

## Article Images
ArticlePhotoPreviewsは表示状態と世代、ArticleImageAccess/PhotoKitArticleImageReader/Converter/Budgetは出力要求・入力owner・縮小・向き/sRGB JPEGとmemory予算。表示と出力を混同しない。

## Probe and Export
1枚のProbeDelivery/Journal、4枚のExportModels/Manifest/FileSystem/Journal/Writer/Delivery/OSActions/Session。所有/実体/digest、固定入力、進行・期限・取消・回復、pasteboard/Finder。

## Measurement and Diagnostics
分類のみのDiagnostics/ArticleDiagnostics。NativeMeasurement/FrameMeasurement/measure-native.swiftは採用入力と同frame表示を照合し、欠測を成功にしない。

## Verification Suite
4 XCTest targets、DebugFixture、runner/coverage/選択契約、GitHub workflows。合成画像・専用pasteboard・所有UUID rootを利用する。App Support隔離再開試験も存在するが、画像実表示の回帰範囲は品質評価に記す。
