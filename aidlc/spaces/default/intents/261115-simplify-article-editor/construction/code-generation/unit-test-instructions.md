# 対象テスト手順

既存のXcodeスキーム `Hitotsuzuri` と XCTest を使用する。追加の依存は不要。

```sh
xcodebuild test -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -parallel-testing-enabled NO -only-testing:HitotsuzuriU2Tests/ArticleProjectionTests -only-testing:HitotsuzuriU2Tests/ArticleMetadataInputTests -only-testing:HitotsuzuriU2Tests/ArticleOutputPreparationTests -only-testing:HitotsuzuriU2Tests/ArticleDraftIntegrationTests -only-testing:HitotsuzuriU3Tests/ArticleExportSessionTests -only-testing:HitotsuzuriU3Tests/ArticleExportIntegrationTests
```

```sh
xcodebuild test -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -parallel-testing-enabled NO -only-testing:HitotsuzuriUITests/ArticleDraftUITests -only-testing:HitotsuzuriUITests/ArticleExportUITests
```

既存の合成写真・一時ストレージと既存のテストダブルを使用する。旧下書きはダミー文と区別できる文字列を保存したfixtureで検証する。日付候補あり・なし、旧文章あり・なし、中断出力の再開を含める。製品全体の行カバレッジ80%以上は、Build and Testで全体の試験結果から確認する。
