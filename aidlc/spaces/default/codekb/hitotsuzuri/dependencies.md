# 依存関係

## ビルド依存
Hitotsuzuri.app → HitotsuzuriCore.framework（embed）。U1/U2/U3 unit-test → Core。UITests → Hitotsuzuri.app。全体は単一Xcode project/shared scheme。SwiftPM・CocoaPods等の外部依存はprojectにない。

## ソース依存
| ソース群 | import・主な依存 |
|---|---|
| App/PickerView | SwiftUI、Core。DebugFixtureはFoundation、Core |
| Workflow | Foundation、Observation、Ports、Models、Diagnostics |
| PhotoLibraryAccess | Foundation、Photos、LibrarySource |
| LocalImageAccess | Foundation、AppKit、Photos、ImageDriving/ImageClock |
| SelectionPersistence | Foundation、CryptoKit、SelectionStoringと保存値 |
| PickerContent/NativeFolderBrowser | SwiftUI、AppKit、Workflow・Presentation・Images |
| Models/Ports/PresentationSnapshot/PickerAccessibility/FrameMeasurement | FoundationとCoreの値 |
| PickerPresentationState | Foundation、Observation |
| NativeMeasurement | Foundation、AppKit、Observation、Darwin |
| Diagnostics | OSLog |
| 検証scripts | xcodebuild、xcrun xccov、swift。任意測定はCoreとApple画面/OCR framework |

Core内は同一モジュール参照で、相互importを持つ別packageの循環はない。ただし画面とWorkflow・OS adapterが同じframeworkに集まり、UIから画像の表示変換も扱う。純粋ドメイン限定のCoreではない。

## ランタイム依存
写真ライブラリの許可、ローカル画像、アプリ専用保存領域。任意の画面計測だけ既存の画面収録許可を確認し、通常製品から起動しない。インターネット・外部DB・クラウドアカウントには依存しない。

## Phase2で新たに検証が必要な境界
記事用の高解像度画像、JPEG/Markdown、利用者指定先への書込、クリップボード、Finder、下書き保存は未実装。現在のentitlementsには利用者選択ファイルの書込権限設定は見当たらず、保存先のSandboxアクセスを実証する必要がある。これは追加方式の確定ではない。
