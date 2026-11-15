# コンポーネント一覧

## App Composition

`HitotsuzuriApp`、`PickerView`、plist、entitlements。アプリ、画面、実機用I/Oを構成する。

## Picker Workflow

`SelectionWorkflow`、`Models`、`Ports`、`SelectionPersistence`、`PhotoLibraryAccess`。PhotoKitの階層探索、表示対象のアルバムからのランダム選択、写真4枚の確定と復元を担当する。

## Picker UI

`PickerContent`、`PickerPresentationState`、`NativeFolderBrowser`、`PickerAccessibility`、`PresentationSnapshot`。フォルダ・アルバム・写真の操作、コンパクト表示、フォーカスや選択順を扱う。

## Display Images

`LocalImageAccess` と `ArticleImageAccess.swift` の `ArticlePhotoPreviews`。表示・選択用のローカル画像、再試行、要求とキャッシュの寿命を扱う。

## Article Domain

`ArticleModels`、`ArticleInitialContent`、`ArticleMetadataInput`、`ArticleFingerprint`、`ArticleProjection`。記事・候補日の値、初期本文、検証・識別、テキスト変換を扱う。

## Article Persistence

`ArticleWorkspace`、`ArticlePorts`、`ArticlePersistence`、`ArticleFileSystem`。確定選択と記事の対応を解決し、記事の作成・版管理・復旧とファイル操作を担当する。

## Article Editing

`ArticleEditSession`、`ArticlePresentation`。編集中の値、保存、未保存の移動確認、プレビュー・コピー・保存済み出力への移行を扱う。

## Article UI Coordinator

`ArticleAppCoordinator`、`ArticleView`、`ArticleMetadataFields`、`ArticlePreviewView`、`ArticleExportView`。入力からOSの保存先選択までをつなぐ。

## Export Image Acquisition

`ArticleImageAccess`、`PhotoKitArticleImageReader`、`ArticleImageConverter`。PhotoKit画像を取得して、向きを反映した長辺2560px以下のJPEGに変換する。

## Export Orchestration

`ArticleExportSession`、`ArticleOutputPorts`、`ArticleExportDelivery`、`ArticleExportOSActions`。保存版の準備、進捗と取消し、出力時のApple OS連携、完了時の本文を扱う。

## Export Storage

`ArticleExportModels`、`ArticleExportManifest`、`ArticleExportFileSystem`、`ArticleExportJournal`、`ArticleExportWriter`。ファイル一式の検査、一時ディレクトリからの公開、復旧・所有確認を担当する。

## Probe Output

`ArticleProbeDelivery` と `ArticleProbeJournal`。画像1枚の検証出力とその復旧を担当する。

## Diagnostics and Measurement

`Diagnostics`、`FrameMeasurement`、`NativeMeasurement`。OSLog、フレーム計測、入力と表示の計測データを扱う。

## Test Fixtures

`DebugFixture`、Core試験のTestDoubles、UI試験の `FixtureLaunch`。合成画像や専用保存領域で再現条件を作る。

## Verification Tooling

`verify-native.sh`、`native-test-runner.py`、`check-coverage.swift`、用途別の検証・計測スクリプト、GitHub Actions。Core・UI試験の起動と結果の検査を行う。
