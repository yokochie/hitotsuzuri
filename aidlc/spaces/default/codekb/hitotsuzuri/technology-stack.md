# 技術構成

| 技術 | ソース指定と用途 |
|---|---|
| Swift | SWIFT_VERSION=6.0。actor/MainActor、async/await、Sendable |
| macOS / Xcode | deployment target 27.0、LastUpgradeVersion 2720、macosx SDK。install実versionは今回未測定 |
| SwiftUI / Observation | ViewとObservable編集・画像・出力状態 |
| AppKit | window、alert、open panel、native outline、pasteboard、Finder |
| Photos | 認可、階層・写真・表示画像・編集入力の読取 |
| Foundation / Darwin | JSON/URL、nofollow-any/openat/mkdirat/flock/fsync/rename |
| CryptoKit | SHA256 canonical input/output digest |
| ImageIO / CoreImage / UniformTypeIdentifiers | JPEG縮小・向き補正・色空間・metadata制御 |
| OSLog | 分類診断 |
| XCTest / XCUITest / Python unittest | Core/結合/UI/性能、runner選択契約 |
| ScreenCaptureKit / Vision / CoreMedia | native計測補助 |
| bash / Python3 / Swift scripts | xcodebuild選択、実実行確認、coverage |
| GitHub Actions | xcode-27 runnerでCore→smoke→機能UI/coverage |

第三者実行時packageはない。App Sandbox・写真library・user-selected.read-writeを宣言する。表示/出力ともネットワーク取得を許可せず、今回の分析から権限拡張や通信追加を必要と判断しない。
