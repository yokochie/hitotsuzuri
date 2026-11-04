# 結合検証

## 実行と範囲

XCTestの各単位専用コマンドでU1IntegrationTests、U2IntegrationTests、U3IntegrationTestsを含めて実行する。全体検証は `bash scripts/verify-all.sh`。同じ選択→保存→新セッション復元、失敗保持、狭幅→領域復帰→確定を合成データと隔離保存先で検証する。

## 対象と限界

実ファイル境界とSwiftUI描画を含むが、実Photos/VoiceOver/キーボード全経路の本人確認を代替しない。保存原本、個人画像、Application Supportをテストデータにしない。全製品行80%以上は全単位の組合せだけで判定する。

