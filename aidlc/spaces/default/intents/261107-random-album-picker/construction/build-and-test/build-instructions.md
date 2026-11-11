# ビルドと検証手順

Xcode 27系を選択したMacでリポジトリのルートから実行する。追加ライブラリやサービスの起動は不要。

```sh
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -derivedDataPath .build/random-album-picker CODE_SIGN_IDENTITY=- build
bash scripts/verify-native.sh --functional
```

1行目でアプリをビルドする。2行目でCore、UIスモーク、機能テストと製品全体のカバレッジを検証する。対象を絞った再実行には[機能別の試験手順](../code-generation/unit-test-instructions.md)を使う。

UI検証はアプリを前面に出せるmacOSのGUIセッションで実行する。Swiftマクロの起動が制限された環境では、通常のXcode権限で再実行する。
