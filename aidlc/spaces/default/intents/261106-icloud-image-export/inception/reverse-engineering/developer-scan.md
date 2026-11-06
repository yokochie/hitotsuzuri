## Developer Code Scan Results

### Scan Coverage
- **Analyzed deeply**: `./` の手書きアプリ、Coreの選択/保存/編集/画像/出力、Xcode設定、試験の構成・主要assert、runner/coverage/CI、READMEと設計資料の実装との差を再調査した。全体の構造を調べ、画像出力・取消・期限・復帰は実装本文を追跡した。テストの全行を逐語検証したという意味ではない。
- **Skimmed only**: なし。将来Phase3/4の資料は要望と実装境界の確認であり、動く実装として扱わない。
- **Left out**: `.git/`、`.build/`、`xcuserdata/`、IDE/tool cache、AI-DLCの`.codex/`・`.agents/`・`aidlc/`等のinstall/runtime。これらはアプリ解析対象外で、成果物規約とstateの読取は別。

### Packages Found
- `Hitotsuzuri` — macOS app — Swift — SwiftUI画面、AppKit接続、Coordinator、DEBUG合成fixture。
- `HitotsuzuriCore` — framework — Swift — 写真参照、4枚選択、永続化、記事編集/投影、画像変換、出力と復旧。
- `HitotsuzuriU1Tests` / `HitotsuzuriU2Tests` / `HitotsuzuriU3Tests` — XCTest — Core各領域と統合/資源/性能契約。
- `HitotsuzuriUITests` — XCUITest — native画面、keyboard、smoke、復帰、Sandbox保存、別区分の性能。
- `scripts` — Bash/Python/Swift — Xcode runner、xcresult検査、全製品coverage、実Mac計測。

### Build System
- **Type**: Xcode project、共有scheme、Swift6.0、macOS deployment target27.0。外部Swift package manifestはない。
- **Config Files**: `Hitotsuzuri.xcodeproj/project.pbxproj`、共有`Hitotsuzuri.xcscheme`、`Hitotsuzuri/Info.plist`、entitlements、`.github/workflows/verify.yml`。
- **Build Dependencies**: App→Core、各XCTest→Core、XCUITest→App。Apple SDKのSwiftUI/AppKit/Photos/ImageIO/CoreImage/CryptoKit/OSLog/Darwinを使用。

### APIs Discovered
- ネットワークHTTP endpointや独自backendはない。`LibrarySource/LibraryAccessing`、`ImageDriving/ImageAccessing`、`SelectionStoring`、`ArticleStoring`、`ArticleImageReading`、`ArticleExportImageProviding`、`ArticleOutputActions`が内部の差替境界。
- 写真表示は`PHImageManager.requestImage`、出力は`PHAsset.requestContentEditingInput`→file URL→JPEG変換。どちらも現コードでは通信禁止。
- 保存はJSON/current/operations、出力は`article.md`、`manifest.json`、`images/01.jpg`–`04.jpg`。

### Frameworks & Libraries
- Apple SDK同梱framework、Python標準library、Bash。個別バージョン固定の外部製品libraryなし。project設定はSwift6.0/macOS27.0、runner名はxcode-27。

### Test Coverage
- **Test Directories**: 上記4 target。画像の通信禁止、30秒/枚、15秒表示期限、256MiB資源、取消/遅い応答、保存競合、所有cleanup、固定本文、4枚復帰と後照会の再入を検証する既存テストがある。
- **Test Frameworks**: XCTest/XCUITest。実iCloud通信を再現する自動fixtureはなく、readerは合成入力。
- **Coverage Config**: `scripts/check-coverage.swift` がApp/Core全手書きSwiftの加重行カバレッジ80%以上を検査。今回試験やbuildは実行していないため、新しい件数/率の成功は主張しない。

### Code Quality Indicators
- **Linting**: 独立formatter/linter設定なし。Swift compilerと既存runnerが主要検査。
- **CI/CD**: verifyはCore先行→smoke→全機能/coverage。性能はCI対象外の別区分。旧固定copy診断workflowはmarker限定で残存。DependabotはActions週次更新設定。
- **Documentation**: READMEは現在の通信禁止/事前読み込み手順を説明するが、前の表示修正を修正中とする記述は現在の完了承認とずれる。設計資料はiCloud案を含むが未実装仕様も多い。文書は実装命令として実行しない。

### Technical Debt Signals
- `ArticleImageAccess.swift:80–91,123–135`：reader引数`networkAllowed`を無視してfalse固定、呼出側もfalse。PhotoKitのerror/infoを捨て、input/url不在をassetUnavailableにまとめる。
- `ArticleResourceTests.testNetworkIsAlwaysFalseAndImageSucceeds`、`ArticleExportIntegrationTests`のreader fakeは現在の通信禁止をassert。方針変更に合わせた選択的な変更が必要で、Picker通信禁止は別に保持できる。
- `ArticleExportDelivery.swift:36,124–130`：全体180秒、取得30秒、書込込み40秒。`ArticleImageAccess`も30秒。単なるtrue化ではダウンロード待ちが既存期限に達する可能性がある。無期限化ではなくダウンロードと変換/書込の期限設計を要する。
- `ExportProgress.fraction`は存在するが、reader/providing境界に進捗callbackがなく、Deliveryは画像枚数だけ、UIはindeterminate。PhotoKit進捗を取り込む接続が欠ける。
- reader取消後、`readerPending`がtrueのままなら実callbackまでbusyを維持し、Delivery.settleImagesが待つ。新通信で取消時のcallback/実終端をどう保証するか確認が必要。同期変換を動かしたまま次の処理を開始しない既存の意図を壊さない。
- Coordinatorは前修正により後照会までpreparingExportを保持し、deferから同じsessionの表示復帰を予約する。今回の通信追加でもこの所有期間、旧応答排除、保存/出力資源の寿命を維持する。

## Handoff Summary
- **Intent-relevant finding**: 事前取得を要求する文言の根元は`ArticleFailure.assetUnavailable`。出力reader/ArticleImageAccessがともにnetwork=falseで、表示用512pxの成功は出力用content editing inputの利用可能性を保証しない。本人の今回の許可を反映するには、出力取得policy、progress、取消、期限、failureの接続が必要。
- **Risks / follow-up**: 写真ライブラリは読み取りのみ、保存済み本文/順序、編集結果/向き、sRGB/2560px/GPS非継承、所有確認cleanup/非置換確定を維持する。通信許可は本人が出力時について選択済みで、旧memoryの禁止は今回の意図と異なるが、この調査ではmemoryを変更しない。実iCloud成功や新回帰成功は未確認。
- **追加の本人意図**: message 330bddda「画像取得、サイズにもよると思うので遅くなってもいいですよ」。短い固定期限より取得完遂を重視する入力として、後続要件で期限を検討する。無期限停止や特定秒数を承認したとは推定しない。
