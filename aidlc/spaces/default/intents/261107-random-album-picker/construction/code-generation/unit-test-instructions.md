# ランダム選択の試験手順

Xcodeの既存macOSスキームとXCTestを使う。追加依存やテスト設定の変更は不要。以下はリポジトリのルートで実行する。

```sh
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -derivedDataPath .build/random-album-picker CODE_SIGN_IDENTITY=- -parallel-testing-enabled NO -only-testing:HitotsuzuriU1Tests/U1WorkflowTests test
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -derivedDataPath .build/random-album-picker CODE_SIGN_IDENTITY=- -parallel-testing-enabled NO -only-testing:HitotsuzuriUITests/NativeInputTests test
```

既存の合成写真ライブラリを使い、0件、1件、一覧外候補、同じID、別のIDと確定前の選択、確認の承諾・取消、狭幅の表示を確認する。ランダム値を固定できる境界または1件の候補を使い、偶然に依存する試験を避ける。実写真にはアクセスしない。

製品全体の80%以上の行カバレッジはBuild and Testの全体試験で確認する。実写真ライブラリでの操作は本人Macで別途確認する。
