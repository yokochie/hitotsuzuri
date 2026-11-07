# ビルドと検証の再現

## 入力
[実装計画](../code-generation/code-generation-plan.md)、[試験手順](../code-generation/unit-test-instructions.md)、[修正概要](../code-generation/code-summary.md)に従う。

## 環境
PR #3のhead `1209e298f6b32b71299c3762b93ee6180f8a9e43` が対象。専用作業ディレクトリ `.worktrees/pr3-ci-fix` の変更ファイルblobは同一。ローカルはPython3とRubyを使用し、追加依存は不要。実アプリのビルド・試験は既存のGitHub Actions xcode-27 runnerで行う。

## コマンド
対象ディレクトリで契約試験を実行する。

```sh
python3 scripts/test-native-runner.py
```

通常CIでは次の2コマンドを順に別jobで実行する。後者はCore成功後に `HZS_CORE_PREFLIGHT_DONE=1` を設定した既存CI環境で実行する。試験内でxcodebuildによるビルドを実行する。

```sh
bash scripts/verify-native.sh --core
```

```sh
bash scripts/verify-native.sh --functional
```

## 判定と問題調査
契約試験32件成功、Core/UI回帰成功、既存 `scripts/check-coverage.swift` による製品全体80%以上を確認する。CI runと対象headを照合し、未実行・中断を成功と扱わない。失敗はGitHub Actionsのjobログから試験名と失敗箇所を調べる。認証情報保存や権限、対象試験、カバレッジ閾値は変更しない。
