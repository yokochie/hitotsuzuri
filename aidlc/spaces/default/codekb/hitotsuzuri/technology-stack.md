# 技術構成

| 技術 | 確認した用途 |
| --- | --- |
| Xcode / Swift | `Hitotsuzuri.xcodeproj` と共有 `Hitotsuzuri` スキーム。Swift言語設定6.0、対象macOS 27.0。CIラベルは `xcode-27` |
| SwiftUI / AppKit / Observation | 画面、動的状態、フォーカス、保存先選択、ペーストボード、Finder |
| Photos / PhotoKit | フォルダ・アルバム・写真の参照、表示画像・出力画像の取得 |
| Foundation / Darwin / CryptoKit | CodableによるJSON、ファイルの安全な更新、SHA-256による整合性検査 |
| ImageIO / CoreImage / CoreGraphics / UniformTypeIdentifiers | 画像処理とJPEG化、試験用画像の生成 |
| OSLog | 写真選択、保存・出力の診断 |
| XCTest / xcodebuild / xcresulttool / xccov | CoreとUIのテスト実行、実行確認、カバレッジ |
| Bash / Python 3 / Swiftスクリプト / GitHub Actions | 検証実行、検証処理の自己試験、計測・CI |

第三者のSwiftパッケージはXcodeプロジェクトの構成に見当たらない。アプリのバージョンは `Info.plist` で1.0と設定されている。
