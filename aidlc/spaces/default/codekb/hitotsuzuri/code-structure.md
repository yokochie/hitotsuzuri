# コード構成

| 場所 | 分類と責務 |
|---|---|
| Hitotsuzuri/HitotsuzuriApp.swift | composition root、App/Window、通常とDEBUG起動の分岐 |
| Hitotsuzuri/ArticleAppCoordinator.swift | 記事開始/終了、AppKit保存先・保存確認、表示資源、probe、出力/復旧 |
| Hitotsuzuri/ArticleView.swift、ArticlePreviewView.swift、ArticleMetadataFields.swift、ArticleExportView.swift | 本文/撮影情報、画像、出力操作と状態、keyboard/focus |
| Hitotsuzuri/PickerView.swift | 選択画面と記事画面の接続、下書き候補sheet |
| Hitotsuzuri/DebugFixture.swift | 合成library/画像/reader、所有UUID領域、障害と遅延の注入 |
| HitotsuzuriCore/Models.swift、Ports.swift、SelectionWorkflow.swift、SelectionPersistence.swift | 4枚選択、保存、復元、認可、画像の抽象境界 |
| HitotsuzuriCore/PhotoLibraryAccess.swift、LocalImageAccess.swift | Photos参照と512px表示queue/cache/budget/期限 |
| HitotsuzuriCore/PickerContent.swift、NativeFolderBrowser.swift、PickerPresentationState.swift、PickerAccessibility.swift、PresentationSnapshot.swift | 選択UI、native outline、focus/狭幅/文字状態 |
| HitotsuzuriCore/ArticleModels.swift、ArticlePorts.swift、ArticleFingerprint.swift、ArticleMetadataInput.swift、ArticleInitialContent.swift | 記事value、入力検証、fingerprint、初期日付候補 |
| HitotsuzuriCore/ArticleWorkspace.swift、ArticlePersistence.swift、ArticleFileSystem.swift | 記事解決、操作履歴/current、fd相対I/O/排他 |
| HitotsuzuriCore/ArticleEditSession.swift、ArticlePresentation.swift、ArticleProjection.swift | 編集と手動保存、離脱確認、候補/関連付け、plain/Markdown投影 |
| HitotsuzuriCore/ArticleImageAccess.swift、ArticleImageConverter.swift | 表示owner、出力reader、単一取得、JPEG変換/予算 |
| HitotsuzuriCore/ArticleProbeDelivery.swift | 一枚の検証出力と独立復旧記録 |
| HitotsuzuriCore/ArticleOutputPorts.swift、ArticleExportModels.swift、ArticleExportManifest.swift | 固定出力契約、進捗/result、所有/phase、manifest |
| HitotsuzuriCore/ArticleExportSession.swift、ArticleExportOSActions.swift、ArticleExportDelivery.swift | UI状態、grant/clipboard/Finder、4枚出力/取消/復旧 |
| HitotsuzuriCore/ArticleExportWriter.swift、ArticleExportJournal.swift、ArticleExportFileSystem.swift | 一時生成、bytes照合、非置換公開、記録、所有cleanup |
| HitotsuzuriCore/Diagnostics.swift、NativeMeasurement.swift、FrameMeasurement.swift | 分類ログ、入力から描画の実測補助 |
| HitotsuzuriU1Tests/、HitotsuzuriU2Tests/、HitotsuzuriU3Tests/、HitotsuzuriUITests/ | Core/統合/資源・nativeUI回帰、実Mac性能を別区分 |
| scripts/、.github/ | runner/xcresult/coverage/実Mac計測、CIとDependabot |
| docs/、README.md | 原点要望、Phase1/将来案、利用/開発の説明。提案と実装を区別 |

Xcodeはsynchronized groupsを使い、新しいSwift test classはrunnerが実ファイルから発見する。外部package/module境界を増やす必要は現時点では見つからない。具体的なAPI/依存は別成果物に集約した。

## アルバム選択で確認した責務

- `PickerContent.swift`が広幅・狭幅共通の一覧と入力を提供し、`PickerPresentationState.swift`が領域と直近のフォーカスを保持する。
- `SelectionWorkflow.swift`が候補・アクティブなアルバム・写真参照・未確定選択を保持し、`PhotoLibraryAccess.swift`がフォルダ階層を候補に変換する。
- `NativeInputTests.swift`が、合成フォルダの絞り込み、通常幅と狭幅、写真グリッドとの連動を検査する。
