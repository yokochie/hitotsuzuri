# 依存関係

## Target依存

App `Hitotsuzuri` → `HitotsuzuriCore`。U1/U2/U3 unit-test target → Core、UI-test target → App。Xcode project/共有schemeが6targetを定義し、filesystem synchronized groupsで手書きファイルを収録する。

## Framework依存

- SwiftUI/AppKit/Observation: native UI、観測状態、保存先・確認・clipboard・Finder。
- Photos: 認可/階層/asset参照と画像取得。ライブラリ編集APIは使わない。
- ImageIO/CoreImage/CoreGraphics/UniformTypeIdentifiers: URLから縮小JPEGを生成、向き/色、metadata非継承。
- Foundation/CryptoKit/Darwin/OSLog: JSON、fingerprint、fd相対I/Oと排他、分類ログ。

## 内部依存

選択workflowはLibraryAccessing/ImageAccessing/SelectionStoringを注入する。記事workspace/edit/presentationはArticleStoringとprojection/output境界を注入する。出力DeliveryはArticleExportImageProviding、Journal、WriterFactoryに依存し、OSActionsが一時grantを所有する。Coordinatorは表示と出力の別資源を接続する。責務詳細はcomponent-inventory.md。

## ビルド・運用依存

外部package lock/manifestなし。既存Bash入口はPython runnerを呼び、Xcode/xcresult/xccovを利用する。CI checkoutは`d23441a48e516b6c34aea4fa41551a30e30af803`、旧診断upload-artifactは`ea165f8d65b6e75b540449e92b4886f43607fa02`固定。DependabotはActionsのみ。

出力時のiCloud取得はPhotoKitの既存境界で扱える候補で、独自download server・SDK・有料サービスの新設を必要とする根拠はない。Sandbox entitlementは現在app-sandbox/photos-library/user-selected.read-write。通信追加時の実Sandbox動作は未検証で、今回の調査で権限を追加していない。

## アルバム一覧の依存経路

`HitotsuzuriApp` → `PickerView` → `PickerContent` → `SelectionWorkflow`。候補は`LibraryAccessing.albums(in:hierarchy:)`の戻り値で、画面での追加フィルターはない。標準起動は`PhotoLibraryAccess`、合成UI試験は同じ型に注入した`FixtureLibrary`を使う。
