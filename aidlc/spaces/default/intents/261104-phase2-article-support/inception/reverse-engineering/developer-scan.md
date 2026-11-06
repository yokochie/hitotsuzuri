## Developer Code Scan Results

### Scan Coverage
- **Analyzed deeply**:
  - `Hitotsuzuri/`: 全Swift 3ファイル、Info.plist、entitlements。
  - `HitotsuzuriCore/`: 全Swift 14ファイル。
  - `HitotsuzuriU1Tests/`、`HitotsuzuriU2Tests/`、`HitotsuzuriU3Tests/`、`HitotsuzuriUITests/`: 全テスト・Fakeを静的読解。
  - `scripts/`: 全6ファイルを静的読解。
  - `Hitotsuzuri.xcodeproj/project.pbxproj`、共有scheme、`.gitignore`、`README.md`。
- **Skimmed only**:
  - `docs/`: 設計資料の位置・提案内容を参照。現行実装の根拠に使わない。
  - `Hitotsuzuri.xcodeproj/project.xcworkspace/`: 設定用ディレクトリ構成のみ確認。
- **Left out**:
  - AI-DLCの導入・記録・生成設定。アプリの構成として文書化しない。
  - `.build/`、`.git/`、`xcuserdata/`、`.DS_Store`、生成されたプロファイルデータ。開かず除外。

### Packages Found
- `Hitotsuzuri` — macOSアプリ — Swift — 依存の生成とウインドウ。
- `HitotsuzuriCore` — framework — Swift — 写真参照、選択、画像、保存、UI、測定。
- U1/U2/U3のunit-test target、UI-testing target — XCTest。

### Build System
- **Type**: Xcode project。SwiftPM packageや外部パッケージの参照はproject設定にない。
- **Config Files**: project.pbxproj、共有Hitotsuzuri.xcscheme、Info.plist、entitlements。
- **Build Dependencies**: App → Core。U1/U2/U3 → Core。UITests → App。
- Swift言語モード6.0、macOS deployment target 27.0、Debug/Release、手動ad-hoc署名、Sandbox有効。実際のインストール済みツール版は調査で実行していない。

### APIs Discovered
- HTTP APIはない。PhotoKitを読むネイティブアダプタと、Swiftプロトコル境界。
- `LibraryAccessing`、`LibrarySource`、`ImageAccessing`、`ImageDriving`、`SelectionStoring`、`ImageClock`。
- `SelectionWorkflow` は状態を公開し、開始・認可要求・フォルダ設定・アルバム選択・画像読込・選択切替・確定・表示範囲更新を受ける。

### Frameworks & Libraries
- Foundation、SwiftUI、AppKit、Observation、Photos、CryptoKit、OSLog、DarwinはApple SDK依存。測定補助のみScreenCaptureKit、Vision、CoreMedia。テストはXCTest。
- 個別frameworkのバージョンは固定されず、macosx SDKを使用する。

### Test Coverage
- **Test Directories**: U1/U2/U3/UITests。
- **Test Frameworks**: XCTest。Swift Testingの実装ではない。
- **Coverage Config**: schemeとverifyスクリプトで有効化、check-coverage.swiftで製品全Swiftの未計測検出と80%判定。
- ビルド・テスト・補助プログラムは今回実行していない。合格件数・現在カバレッジの実測値は出さない。

### Code Quality Indicators
- **Linting**: 独立したformatter/linter設定は確認できない。短い圧縮記法が多い。
- **CI/CD**: rootにCI構成ディレクトリはない。検証用shellスクリプトはあるが、CI実行証拠ではない。
- **Documentation**: READMEは見出しのみ。重要な境界には日本語コメントがある。docsの計画を実装済みと扱わない。

### Technical Debt Signals
- `LocalImageAccess.swift:122` は512px要求、decodeも長辺512以下、要求ごと2 MiB予約。記事用画像取得として再利用するには契約が異なる。
- `Models.swift:13` の確定選択はschemaVersion 1、1つの選択IDと順序4件を持つ。選択リビジョン・記事・撮影情報はない。
- `SelectionPersistence.swift` は単一selection.jsonとsettings.json、1 MiB制限、未知版保護。下書きを同じJSONへ安易に増設すると既存互換性へ影響する。
- `SelectionWorkflow.swift:47` の復元は認可・ライブラリ参照・4枚画像検証成功後だけlastCommittedを公開する。画像が取得不能でも文章を再開するPhase2との責務分離が必要。
- `SelectionWorkflow.swift:139` は再確定ごとに新UUIDを生成する。同じ4枚の再確定と下書き同一性の扱いを要件で決める必要がある。
- 記事画面・記事メニュー・下書き保存・日付解析・Markdown/JPEG出力・保存パネル・本文コピー・Finder操作は未実装。
- MainActor上の画像decodeと複合UI/入力処理は画像高解像度化時の応答性・メモリへの影響点。現在の256 MiB管理は表示用バッファの範囲である。

## Handoff Summary
- **Intent-relevant finding**: Phase2の入力として `CommittedSelection` と `SelectionStoring.loadSelection()` が存在するが、表示専用画像取得は成果物用ではない（Models.swift:13、Ports.swift:111、LocalImageAccess.swift:122）。
- **Risks / follow-up**: 既存選択の保存互換性、再確定UUIDと下書き同一性、取得不能でも文章を失わない再開、記事用画像の実証、Sandboxの利用者指定先アクセスを後続で決める。VoiceOver追加要件は本人指定で設けない。既存の実装を削除する指示ではない。
- **Staged output**: `.aidlc-engine/codekb-stage-hitotsuzuri/` の9文書。公開とlink記録は親が実施する。
