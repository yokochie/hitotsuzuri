## Developer Code Scan Results

### Scan Coverage
- **Analyzed deeply**: `./` の手書きコード。App/Core、4つのTests領域、scripts、GitHub workflows、Xcode project/workspace/共有scheme、Info.plist/entitlements、READMEと手書きgitignoreについて、module・依存・呼出関係・試験境界を全体再調査した。同会話内で本文を読取済みの領域も、現在HEADまでの製品/構成差分を照合し、変化した保存helper・fixture・Sandbox試験を再読した。今回はCoordinator、表示用Previews、ImageAccess、UI binding、記事再開と出力の経路・関連試験を特に再読した。全assertionの個別監査や実行検証を意味しない。
- **Skimmed only**: `docs/`。現行Phase2と提案・将来Phase3/4の境界を把握した。参考コードや古い自動保存/通信の提案を現行仕様と扱わない。
- **Left out**: AI-DLCのinstall/workspace/generated領域、`.git/`、無視対象のbuild・依存・IDE/cache領域、`.DS_Store`。実Photos、本人の保存記事、一般pasteboard、OS設定、削除済み結果bundleは開いていない。

### Packages Found
- `Hitotsuzuri` — SwiftUI/AppKitアプリ。選択、記事、OSパネル、window/application終了調整。
- `HitotsuzuriCore` — Swift framework。選択と記事のモデル、保存、PhotoKit、表示/変換、本文生成、出力。
- `HitotsuzuriU1Tests`、`HitotsuzuriU2Tests`、`HitotsuzuriU3Tests` — Core XCTest。旧写真選択とPhase2の記事試験が併存。
- `HitotsuzuriUITests` — 合成adapterでappを操作するXCUITest。temporaryとApplication Support隔離rootを使用。

### Build System
- **Type**: Xcode project / xcodebuild。
- **Config Files**: `Hitotsuzuri.xcodeproj/project.pbxproj`、共有scheme、Info.plist、entitlements。
- **Build Dependencies**: App→Core、3つのunit target→Core、UI target→App起動。filesystem synchronized groups。第三者package manifestはない。

### APIs Discovered
- HTTP等の通信APIなし。主要Swift境界はLibraryAccessing/ImageAccessing/SelectionStoring/ArticleStoring/ArticleImageReading/ArticleOutputActions。
- 表示画像はLocalImageAccess、出力画像はArticleImageAccessとPhotoKitArticleImageReaderを使用し、要求・所有を分離する。

### Frameworks & Libraries
- Swift 6.0、macOS deployment target 27.0。SwiftUI、Observation、AppKit、Photos、Foundation、Darwin、CryptoKit、ImageIO、CoreImage、UniformTypeIdentifiers、OSLog。
- 計測補助にScreenCaptureKit/Vision/CoreMedia。実行時の第三者ライブラリはない。現在installされたSDKの実versionは測定していない。

### Test Coverage
- **Test Directories**: 上記4target。
- **Test Frameworks**: XCTest/XCUITest、Python unittestによるrunner選択契約。
- **Coverage Config**: 全手書きApp/Core Swiftが計測対象に含まれることと加重80%以上をcoverage scriptが判定。部分実行の率を全体へ代用しない。
- 表示部品の成功・期限・取消・番号別再試行は試験済みの構成だが、Coordinatorの出力による表示解放後、同一sessionの画像再取得は確認されていない。詳細は品質評価へ集約。

### Code Quality Indicators
- **Linting**: 独立formatter/linter構成なし。
- **CI/CD**: Core成功依存でsmoke→全機能/coverage。checkout SHA固定、contents read、credential非保持。性能は本人Mac用の別区分。
- **Documentation**: READMEは最小。日本語設計提案と実装を区別する必要がある。

### Technical Debt Signals
- Coordinatorは表示画像の破棄と出力を接続する一方、出力終端に対応した表示復旧の所有者がない。
- optional欠落/取消済み状態/未要求状態を同じ「取得待ち」に投影し、押せる再試行が処理へ届かない条件がある。
- 既存保存helperは前回修正により対象直接open＋全成分nofollowと不足部分だけ作成する構成になっており、今回の表示問題と区別する。

## Handoff Summary
- **Intent-relevant finding**: 出力前の `ArticleAppCoordinator.swift:374` はpreviewTask取消、Previews.cancel、previews=nilを実行するが、成功・画像取得失敗・出力取消・保存先取消・解放後容量拒否の終端で再生成しない。189行の同一session判定もnilを復旧しない。`ArticleView.swift:164/252` はnilを全番号waitingと表示し、再試行は即returnする。これが今回の表示と一致する強いコード上の成立経路。ただし本人の操作順・実機状態は未観測であり、直接原因と断定しない。
- **Risks / follow-up**: freshな下書き再開は新sessionを生成しPreviews.loadへ進む別経路。Observationが欠けているとは現段階で断定できない。cancel世代/遅い応答防御、共有ImageAccessの解放順序、出力中のmemory予算と直列化を維持する。本人申告の「写真アプリで読込後に出力成功」は出力用画像取得の事実であり、表示owner欠落を解消した証拠ではない。仮説と試験不足の詳細は `code-quality-assessment.md`。
