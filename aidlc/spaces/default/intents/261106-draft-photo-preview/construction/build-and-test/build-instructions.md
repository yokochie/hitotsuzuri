# ビルドと検証の手順

## 入力と前提

同じintentの `../code-generation/code-generation-plan.md`、`../code-generation/unit-test-instructions.md`、`../code-generation/code-summary.md` を使用する。Minimal、Zero UnitのSwiftUI macOSアプリで、追加依存・サービス・環境変数は不要。Xcode projectと共有schemeは既存のものを使う。

## 通常の検証先

既存GitHub Actions `.github/workflows/verify.yml` のxcode-27 runnerで、次を順番に実行する。テストに必要なアプリのビルドも同じxcodebuild testで行うため、独立したローカルビルドは追加しない。

```bash
python3 scripts/test-native-runner.py
```

```bash
bash scripts/verify-native.sh --core
```

Core成功後のnative jobは `HZS_CORE_PREFLIGHT_DONE=1` で次を実行する。

```bash
bash scripts/verify-native.sh --functional
```

最後のコマンドは起動smoke、全機能、全製品の行カバレッジ検査を含む。全体の80%条件を部分実行の数値で代用しない。対象限定コマンドは上流unit-test-instructionsに記載済みで、同じ対象が全機能CIで成功した後に再実行する必要はない。

## 今回の実行証拠

CI42179866652、head f272e3d4fb9783f38acc7745a1d3bcd8ac2b60b9の両job成功を利用する。現在のApp/Core/UITests/scripts/.githubはそのheadと差分なし。ローカルの既存作業中scheme差分は今回の変更に含めず、CIの設定や実行結果へ代用しない。

macOS27.0.1 (26A434)、Xcode27.1 (27A9275)、arm64。署名は既存runnerのad-hoc設定を使用し、署名証明書やOS権限を追加操作しない。

## 本人向け起動と問題時の扱い

XcodeでHitotsuzuri.xcodeprojを開き、通常のHitotsuzuri schemeでRunする。今回の自動試験fixture引数を加えない。下書き再開と出力後の実写真確認はDeployment Executionでまとめる。

CI失敗時は最初に失敗したjobのassert/ビルドログを確認する。compile・fixture・AX観測の失敗を製品不具合のRedと混同しない。記事データ・写真・権限を削除して回避せず、現在の作業をreset/clean/restoreしない。
