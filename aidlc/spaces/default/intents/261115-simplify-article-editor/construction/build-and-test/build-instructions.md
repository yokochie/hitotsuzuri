# ビルド手順

macOSでXcodeを選択し、リポジトリのルートで実行する。外部依存や環境変数は不要。

```sh
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -derivedDataPath .build/ArticleEditorVerification CODE_SIGN_IDENTITY=- build
```

終了コード0と `.build/ArticleEditorVerification/Build/Products/Debug/Hitotsuzuri.app` を確認する。UI試験にはアプリが前面化できるmacOSログインセッションが必要。Xcodeの選択状況は `xcodebuild -version` で確認する。

対象テストは実装時の対象テスト手順を使用する。全Core試験は `bash scripts/verify-all.sh` で実行する。製品の行カバレッジの判定は、UIとCoreを含むCIと同じ `bash scripts/verify-native.sh --functional` で行う。
