# ビルドと試験の手順

## 入力と前提

`../code-generation/code-generation-plan.md`、`../code-generation/unit-test-instructions.md`、`../code-generation/code-summary.md` を使用する。SwiftUI macOSアプリ、Zero Unit、Minimal。既存Xcode project/共有schemeとXCTest/XCUITestを使い、追加依存・外部サービス・署名設定は不要。

## 通常の検証

既存 `.github/workflows/verify.yml` のxcode-27 runnerで、次を順番に実行する。xcodebuild testがアプリをビルドするため、別のローカルbuildを重ねない。

```bash
python3 scripts/test-native-runner.py
```

```bash
bash scripts/verify-native.sh --core
```

Core成功後、native jobはHZS_CORE_PREFLIGHT_DONE=1で次を実行する。

```bash
bash scripts/verify-native.sh --functional
```

起動smoke、全機能、全手書きApp/Core Swiftの80%行カバレッジを検査する。native job実行枠は、実測の30分上限による中断を受け45分へ修正した。試験選択・順序・除外・合格基準は維持する。

## 対象限定の再現

今回の取得/進捗/取消の対象コマンドは上流unit-test-instructionsに記載済み。全機能CIで同じ対象が成功した後の重複実行は不要。一時診断workflowは削除済み。失敗したAX要素の修復は当該1件のonly-testingと、その後の通常全機能CIの両方で確認した。

## 結果と本人向け起動

最終証拠はtest-results.mdのCI42226898333、head983c60b64f413034259bc7d2498f0c47cbde3e15。現在の対象製品/試験/scripts/CIは同headと差分なし。本人Macの通常起動はXcodeでHitotsuzuri.xcodeproj、Hitotsuzuri scheme、My Macを選んでRunする。fixture引数を付けない。実iCloud取得は最終段階で本人が確認する。

問題時は失敗job/写真番号/文言を確認し、記事や権限を削除しない。取得開始直前の取消の既知制約はsummaryに記載する。現在の作業をreset/clean/restoreしない。
