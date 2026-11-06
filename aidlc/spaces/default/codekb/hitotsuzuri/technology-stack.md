# 技術構成

| 層 | 技術と確認根拠 |
|---|---|
| App/runtime | Swift6.0、macOS Deployment Target27.0（project.pbxproj）。プロジェクトのSDK設定はmacosx |
| UI | SwiftUI、AppKit、Observation。単一Window、NSOutlineView/NSOpenPanel/NSAlert、keyboard/focus接続 |
| 写真 | Photos/PhotoKit。PHPhotoLibrary認可、PHAssetCollection/PHAsset読取、PHImageManager表示、content editing input出力 |
| 画像 | ImageIO、CoreImage、CoreGraphics、UniformTypeIdentifiers。software CIContext、JPEG/sRGB、長辺2560 |
| 保存 | Foundation JSON/Data/FileManager、CryptoKit SHA256、Darwin fd/openat/flock/fsync/renameatx_np |
| 並行処理 | Swift concurrency、MainActor、actor、Task/Task.detached、取消/UUID/continuation |
| 診断 | OSLog、mach時刻、資源計測補助 |
| 検証 | XCTest/XCUITest、xcodebuild、xcresulttool/xccov、Python3標準library、Bash |
| CI | GitHub Actions xcode-27 runner、commit固定のcheckout/upload-artifact、Dependabot Actions週次更新 |

Apple frameworkの独立バージョンやローカルXcodeの版をsource設定から捏造しない。今回build/runtime照会や試験は実行していない。外部Swift package、Web frontend、DB server、AWS、独自APIは発見していない。
