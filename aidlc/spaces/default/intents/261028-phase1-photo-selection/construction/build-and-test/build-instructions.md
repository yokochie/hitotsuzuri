# ビルド手順

## 前提と入力

本人の現行Mac、既存Xcode/Swift6。外部パッケージ・サービスを追加しない。入力は各単位の[U1計画](../u1-integrated-selection/code-generation/code-generation-plan.md)、[U2計画](../u2-session-reliability/code-generation/code-generation-plan.md)、[U3計画](../u3-native-experience/code-generation/code-generation-plan.md)と対応するテスト手順・summary。

## ビルド

リポジトリのルートで実行する。

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -derivedDataPath .build/DerivedData CODE_SIGN_IDENTITY=- build
```

XcodeでHitotsuzuri.xcodeprojを開いて同じschemeで起動できる。署名はローカルad-hoc。実Photosの許可は本人操作とする。XCTest接続権限の失敗を製品の失敗テストと混同しない。

## 自動検証

各単位のunit-test-instructions.mdの専用コマンドを1回ずつ実行する。全体カバレッジは本人承認済みのbash scripts/verify-all.shで全単位を組み合わせて判定する。単位別と全体の件数を加算し重複集計しない。

