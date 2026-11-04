# コンポーネント一覧

## App Composition
HitotsuzuriAppとPickerView。実境界を生成しCore UIを単一Windowで表示。DEBUG fixture切替は試験用。依存: Selection Workflow、Picker UI、Photo Library、Local Images、Selection Persistence。

## Selection Models and Ports
Models.swift、Ports.swift。編集順序配列、確定選択、写真階層・画像・失敗値と注入protocol。依存: Foundation。

## Selection Workflow
SelectionWorkflow.swift。選択・探索・4枚検証・確定・復元を調整。世代、revision、操作UUIDで遅延応答を防ぐ。依存: Models and Ports、Photo Library、Local Images、Selection Persistence、Diagnostics。

## Photo Library
PhotoLibraryAccessと内部SystemLibrarySource。階層・写真ID、フォルダ集約と所属検証。依存: Photos、Models and Ports。

## Local Images
LocalImageAccessと内部SystemImageDriver、ImageBuffer/ImageStorage。表示用512px、通信禁止、15秒期限、LRUと256 MiB管理、2 MiB予約、必要画像保持。依存: Photos、AppKit、Models and Ports。

## Selection Persistence
SelectionPersistence actor。設定と確定JSON、原子的保存、版・サイズ・ファイル種別検証、明示的破損退避回復。依存: Foundation、CryptoKit、Models and Ports。

## Picker UI
PickerContent、NativeFolderBrowser、PickerPresentationState、PresentationSnapshot、PhotoSemantics/GridNavigation。広幅3領域・820以下の領域切替・最小640×560、NSOutlineViewの入力、写真4枠と状態。依存: SwiftUI、AppKit、Workflow、Images。

## Measurement and Diagnostics
NativeMeasurement、FrameMeasurement、Diagnosticsと任意のmeasure-native.swift。入力前後の選択差、表示フレームの照合、資源件数、失敗enum。測定ツールのみScreenCaptureKit/Visionを使う。通常のアプリ動作とは分離。

## Verification Suite
U1/U2/U3/UITestsとverify/check-coverage scripts。プロトコルFake、実ファイル一時保存、合成UI操作、資源・期限・競合検証。依存: XCTest、Core、App。今回は静的読解のみ。
