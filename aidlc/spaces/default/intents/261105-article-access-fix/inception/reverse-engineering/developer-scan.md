## Developer Code Scan Results

### Scan Coverage
- **Analyzed deeply**: `./` の手書きコード全体を再調査した。`Hitotsuzuri/`、`HitotsuzuriCore/`、4つのTests領域の本文、`scripts/`、`.github/workflows/`、Xcode project・workspace・共有scheme、Info.plist・entitlements、README・手書き.gitignoreを読み、module・呼出関係・保存/出力・OS境界・試験接続を確認した。最初の19パスから追加読取し、選択Workflow、native階層/焦点UI、画像driver、計測本体、全試験群/test doubles、runner契約も含めFull rescanを完了した。Minimalの構造分析であり、全assertionの正しさの個別監査や実行検証ではない。
- **Skimmed only**: `docs/` の設計資料。Phase2の目的・機能・提案と実装の境界を確認し、将来Phase3/4とPhase1参考コードは現行動作の根拠にしない。現行動作の根拠にはコードを優先した。
- **Left out**: `.git/`、`xcuserdata/`、`.DS_Store`、無視対象の生成物・依存・キャッシュ。AI-DLCの `.agents/`、`.codex/`、`aidlc/`、設定、AGENTS.mdの管理ブロックを製品分析対象から除いた。削除済み `.build/` と実写真・利用者の保存領域は開いていない。

### Packages Found
- `Hitotsuzuri` — macOS SwiftUIアプリ。写真選択・記事編集・保存先選択・OS操作の接続。
- `HitotsuzuriCore` — Swift framework。選択と記事のモデル、保存、PhotoKit、画像変換、本文生成、出力。
- `HitotsuzuriU1Tests`、`HitotsuzuriU2Tests`、`HitotsuzuriU3Tests`、`HitotsuzuriUITests` — XCTest。番号はPhase2の新機能だけでなく旧写真選択試験も含む。

### Build System
- **Type**: Xcode project / xcodebuild。Swift Package、第三者package manifestはない。
- **Config Files**: `Hitotsuzuri.xcodeproj/project.pbxproj`、共有scheme、appのInfo.plistとentitlements。
- **Build Dependencies**: App → Core、各Core試験 → Core、UI試験 → App起動。プロジェクトはSwift 6.0、macOS 27.0を宣言する。

### APIs Discovered
- HTTP APIなし。主要境界は `SelectionStoring`、`LibraryAccessing`、`ImageAccessing`、`ArticleStoring`、`ArticleImageReading`、`ArticleOutputActions`。
- 保存形式と外部OS接続は候補の `api-documentation.md`、ファイル分類は `code-structure.md` に集約。

### Frameworks & Libraries
- Apple SDK: SwiftUI、AppKit、Observation、Foundation、Photos、CryptoKit、ImageIO、CoreImage、UniformTypeIdentifiers、OSLog、Darwin。計測ツールはScreenCaptureKit・Vision・CoreMediaも参照する。
- 第三者実行時依存なし。SDK実versionの実測はしていない。

### Test Coverage
- **Test Directories**: 上記4ターゲット。
- **Test Frameworks**: XCTest/XCUITest、runner選択契約はPython unittest。
- **Coverage Config**: schemeとrunnerがcode coverageを有効化し、全手書きApp/Core Swiftが計測対象にあることと合計80%以上を `scripts/check-coverage.swift` が判定する。本調査でテストやbuildは実行していない。

### Code Quality Indicators
- **Linting**: 専用formatter/linter構成は確認できない。
- **CI/CD**: `.github/workflows/verify.yml` がCore成功依存で機能UIと製品全体coverageを実行。固定action SHA、contents read、資格情報を保存しないcheckout。性能は本人Mac用。別workflowは特定commit marker時の固定本文コピー診断。
- **Documentation**: READMEは名前のみ。日本語設計資料はあるが、実装との相違（例: 下書きは手動保存）に注意。

### Technical Debt Signals
- `ArticleDirectory.open` が `/` を開き、保存先までの全祖先を `O_RDONLY|O_DIRECTORY|O_NOFOLLOW` でたどる。`create:true` では既存祖先にも `mkdirat` を試す。許可された末端へのアクセスと祖先の列挙・作成権限を結び付けている（`ArticleFileSystem.swift:11–26`）。
- permissionDeniedは写真・保存先共通文言で、失敗段階が画面から分からない。`ArticlePersistence.list` のFoundation列挙失敗は全てioFailureへ丸められる。安全な段階別分類の余地がある。
- AppCoordinatorはDEBUGの計測・fixture接続込みで大きい。今回の修正で無関係な分割は不要。

## Handoff Summary
- **Intent-relevant finding**: スクリーンショットは `ArticleFailure.permissionDenied.message` と完全一致。通常入口は `ArticlePresentation.loadCurrent`（86行）→確定選択読込→ `workspace.listDrafts`（93行）→ `ArticlePersistence.list`（32行）→ `ArticleDirectory.open(create:false)`。ここは写真プレビュー開始前である。`ArticleFileSystem.swift:115` はEACCES/EPERMを同失敗へ変換する。許可済みApplication Support末端を使う通常起動と、全祖先を読取openする実装の不整合が強い原因候補。実機の失敗syscall・errno・保存先そのものは未観測であり、発生原因の確定や修正成功は主張しない。
- **Risks / follow-up**: 同じhelperを記事保存、1枚検証出力、4枚出力、回復journal、Finder前検査も使用する。祖先読取openと既存祖先mkdiratを避ける場合も、symlink拒否・差替え防御・排他・atomic確定・結果不明照合を維持する。回帰候補と既存試験の不足は `code-quality-assessment.md` に記録。本調査は製品変更・テスト実行なし。
