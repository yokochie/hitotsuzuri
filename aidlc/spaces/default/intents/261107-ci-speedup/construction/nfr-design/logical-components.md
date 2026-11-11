# CIの構成と責務

`../nfr-requirements/tech-stack-decisions.md`、`scalability-design.md`、`reliability-design.md`を参照。

| 構成 | 責務と障害の境界 |
|---|---|
| GitHub Actionsの検証ワークフロー | PRとcommitを結び付け、Core完了後に機能ジョブを実行する。失敗・取消をCI結果へ反映 |
| xcode-27 runnerとXcode | ビルド・試験を実行。共有GUI環境と作業領域の隔離が並列化の前提 |
| テスト実行スクリプト | 試験の選択、結果照合、カバレッジ検査。欠損・不一致を失敗として扱う |
| UI試験とfixture | 合成データとケース固有の領域で画面状態を観測する。起動や準備の変更は検証内容を維持する範囲 |
| 比較記録 | run・attempt・commitと所要時間・結果を関連付け、改善の判定に使う |
