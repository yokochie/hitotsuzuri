# 技術スタック

| 項目 | 観測値・根拠 |
|---|---|
| 言語 | Swift、projectのSWIFT_VERSION=6.0。スクリプトはBashとSwift |
| 対応OS設定 | MACOSX_DEPLOYMENT_TARGET=27.0、SDKROOT=macosx |
| ビルド | Xcode project、objectVersion 71、compatibilityVersion Xcode 16.0、LastUpgradeCheck 2720。これらはファイル値で、インストール済みXcode版を証明しない |
| UI | SwiftUI、AppKit。写真フォルダはNSOutlineViewを包む |
| 状態・並行処理 | Observation、MainActor、Task/task group、actor、Sendable、ContinuousClock |
| 写真 | Photos/PhotoKit。読取、非通信の表示画像要求 |
| 永続化 | Codable JSON、Foundation FileManager、CryptoKit SHA256 |
| 診断 | OSLog。通常ログは失敗種別のみ |
| テスト | XCTest。shared schemeの4 testables、カバレッジ有効 |
| 補助測定 | ScreenCaptureKit、Vision、CoreMedia、Darwin。開発者用任意ツール |
| 署名とSandbox | Manual/ad-hoc設定、アプリSandbox、写真ライブラリentitlement |
| 外部パッケージ | projectに登録された第三者パッケージ参照なし |

Apple frameworkの個別版は固定されずSDKに従う。ビルド・OS・実機の動作版確認は今回行っていない。CI設定・formatter/linter設定・パッケージロックは調査した製品構成にない。
