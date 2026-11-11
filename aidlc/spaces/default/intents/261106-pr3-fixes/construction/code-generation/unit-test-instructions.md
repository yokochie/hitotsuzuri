# CI契約試験の検証手順

## Runnerと実行コマンド

既存のPython3 unittestとRuby YAML/JSONを使う。追加インストールなし。PR #3の作業ディレクトリから、対象ファイルを明示して実行する。

```sh
python3 scripts/test-native-runner.py
```

最初に変更前の28件を実行し旧SHA不整合を記録する。新しい参照判定の正常・異常試験を先に追加してRed、最小実装でGreen、整理後に再実行する。

## 要件別の検証

- FR1: PR更新済みworkflowに対する既存診断試験と全契約試験が成功。
- FR2: 新旧40桁commit SHAを許可し、tag・短いSHA・別action・末尾余分文字を拒否。既存の診断実行条件・権限・対象1件・保存制約assertionを保持。
- FR3: push後の対象headとCI run URLを照合し、通常CIが成功した証拠を保存。
- NFR1: Red/Greenの実出力を記録。製品全体80%は後続Build and Testで通常CIの全体計測を確認し、Python試験だけで達成を主張しない。
- NFR2: git diffでCI契約試験以外の製品ソース変更や権限拡大がないことを確認。

## データと隔離

既存runner試験の一時fixtureと偽装Xcodeを使う。実写真や本人の保存データを使わない。通常CIの実行経路・カバレッジ対象・合格基準は変更しない。
