## Developer Code Scan Results

### Scan Coverage

- **Analyzed deeply**: リポジトリ全体を対象に、製品ターゲット・写真選択・記事編集と保存・画像取得・出力の責務を追跡した。
  - `Hitotsuzuri/`
  - `HitotsuzuriCore/`
  - `Hitotsuzuri.xcodeproj/` の共有プロジェクトとスキーム
  - `HitotsuzuriU1Tests/`、`HitotsuzuriU2Tests/`、`HitotsuzuriU3Tests/`、`HitotsuzuriUITests/` の試験構成と主要な回帰条件
  - `scripts/`、`.github/workflows/`、`.github/dependabot.yml` の検証・保守構成
- **Skimmed only**: `README.md` と `docs/` の要望・過去の設計資料は、現行実装と記載を照合するために参照した。
- **Left out**: `.build/`、`.worktrees/`、`.git/`、`xcuserdata/`、OSの生成ファイル、AI-DLCの導入物と作業記録。

### Packages Found

- `Hitotsuzuri` はSwiftUI/AppKitのmacOSアプリ。初期化、画面、OSアダプターの結線を担当する。
- `HitotsuzuriCore` はSwiftフレームワーク。写真選択、下書き、記事の表示内容と出力の生成、入出力を担当する。
- `HitotsuzuriU1Tests`、`HitotsuzuriU2Tests`、`HitotsuzuriU3Tests`、`HitotsuzuriUITests` はXCTestの4ターゲット。配備・検証用の独立したサービスは見当たらない。

### Build System

- **Type**: Xcodeの共有 `Hitotsuzuri` スキーム。Swift言語設定6.0、macOS Deployment Target 27.0。
- **Config Files**: `Hitotsuzuri.xcodeproj/project.pbxproj`、共有 `Hitotsuzuri.xcscheme`、`Hitotsuzuri/Info.plist`、`Hitotsuzuri/Hitotsuzuri.entitlements`。
- **Build Dependencies**: アプリとCore試験は `HitotsuzuriCore` に依存し、UI試験はアプリを起動する。外部Swiftパッケージ宣言は見当たらない。

### APIs Discovered

- 写真ライブラリ・画像取得・選択保存の契約は `Ports.swift`。記事保存は `ArticlePorts.swift`。コピーと完成出力は `ArticleOutputPorts.swift`。
- OS境界はPhotoKit、AppKitのペーストボード・フォルダ選択・Finder、ユーザーが選択したファイルシステム。アプリ独自のHTTPエンドポイントは見当たらない。
- 選択・下書き・出力ジョブはローカルで管理する。完成出力は `article.md`、`manifest.json` と4枚のJPEG。

### Frameworks & Libraries

- SwiftUI、AppKit、Observation、Photos、Foundation、OSLog、CryptoKit、ImageIO、CoreGraphics、CoreImage、UniformTypeIdentifiers、Darwin、XCTest。各フレームワークはOSまたはXcode SDKに付属。

### Test Coverage

- **Test Directories**: Coreの3ターゲットとUI試験ターゲット。本文・メタデータは `ArticleProjectionTests.swift`、`ArticleMetadataInputTests.swift`、`ArticleDraftUITests.swift`、出力は `ArticleExportContractTests.swift`、`ArticleExportWriterTests.swift`、`ArticleExportUITests.swift` が代表例。
- **Test Frameworks**: XCTest。Pythonの `test-native-runner.py` は試験実行処理を検証する。
- **Coverage Config**: `verify-native.sh`、`native-test-runner.py`、`check-coverage.swift`。CIは製品全体の行カバレッジ80%以上を検査する。この調査ではコードと構成の読取りを行った。

### Code Quality Indicators

- **Linting**: 独立したSwiftLint/SwiftFormatの実行設定は確認できなかった。
- **CI/CD**: `.github/workflows/verify.yml` は `xcode-27` 上で `native-core` 後に `native` を実行する。別ワークフローに出力コピーの診断がある。
- **Documentation**: READMEに起動・検証手順、`docs/` に元の要望と設計。READMEのランダム選択と出力時のネットワーク可否には現行コードとの差がある。

### Technical Debt Signals

- 編集時の入力欄と手動キーボード順が `ArticleView.swift` に重複して記述される。
- `ArticlePreviewView` は本文を `ArticleContent` から個別に表示し、コピー・出力は `ArticleProjectionContext` の変換結果を使う。本文の差替えを片側に行うと表示と出力に差が出る。
- `ArticleAppCoordinator.swift` は画面遷移、ウィンドウ、写真、OS出力、試験計測を統括する。各機能の変更点は境界ごとに追う必要がある。

## Handoff Summary

- **Intent-relevant finding**: `Hitotsuzuri/ArticleView.swift:168` 付近で導入文・写真ごとの4欄・締めの文章を編集する。`Hitotsuzuri/ArticleMetadataFields.swift:9` 付近に日付候補の操作があり、同ファイル18行付近で場所・機材・フィルム・人物名を入力する。プレビューは `ArticlePreviewView.swift:13` 付近、コピーとMarkdownは `ArticleProjection.swift:16` 付近を通る。
- **Risks / follow-up**: `SavedArticle` v1と `ArticleFingerprint` は、今回画面から外す項目も保存・照合する。さらに `ArticleExportRecoveryRecord.validate` は記録済みのプレーンテキスト・Markdownと再変換結果をバイト単位で比較する。出力形式の変更を既存下書きと未完了出力にどう適用するか、分けて検証する必要がある。記事タイトルは別項目で、日付候補は新規記事作成時にアルバム名の末尾から抽出される。
