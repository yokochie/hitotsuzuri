# 技術構成

| 技術 | ソースから確認した指定・用途 |
|---|---|
| Swift | SWIFT_VERSION=6.0。actor、MainActor、async/await、Sendable |
| macOS / Xcode | Deployment target 27.0、scheme LastUpgradeVersion 2720。実際のinstall versionは今回未実測 |
| SwiftUI / Observation | window・View・Observable状態 |
| AppKit | NSOpenPanel、NSAlert、NSPasteboard、NSWorkspace、NSOutlineView |
| Photos | システム写真ライブラリの階層・画像・編集入力の参照 |
| Foundation / Darwin | JSON・ファイル・URL、openat/mkdirat/flock/fsync/rename |
| CryptoKit | SHA256入力fingerprintと出力digest |
| ImageIO / CoreImage / UniformTypeIdentifiers | JPEG縮小、向き、色空間、metadata制御 |
| OSLog | 個人文章を含まない分類ログ |
| XCTest / XCUITest | Core・結合・native UI・性能 |
| Python3 / bash / Swift scripts | 試験選択契約、xcodebuild、coverage、計測 |
| ScreenCaptureKit / Vision / CoreMedia | native計測補助スクリプト |
| GitHub Actions | xcode-27 runner上のCore→機能UI・coverage |

外部package managerと第三者実行時ライブラリは見つからない。App Sandbox、写真library、user-selected.read-write entitlementsを宣言する。認可の拡張やSandbox解除は現行構成では行わない。
