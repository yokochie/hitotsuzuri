# 試験結果

## 対象と証拠

入力は `../code-generation/code-generation-plan.md`、`../code-generation/unit-test-instructions.md`、`../code-generation/code-summary.md`。詳細履歴は `../code-generation/ci-evidence.md`。要件は `../../inception/requirements-analysis/requirements.md`。

[最終PR CI42226898333](https://github.com/yokochie/hitotsuzuri/actions/runs/42226898333)、head **983c60b64f413034259bc7d2498f0c47cbde3e15**、success。現在の対象ソースとの同一性を確認して利用した。

| 実行 | 結果 | 証拠 |
|---|---|---|
| python3 scripts/test-native-runner.py | 28件成功、4.142秒、exit0 | native-core127922551662 |
| bash scripts/verify-native.sh --core | Core480件成功、exit0 | 同job、1分45秒 |
| bash scripts/verify-native.sh --functional | smoke2件、機能558件成功、exit0 | native127923376367、32分11秒 |
| 全製品カバレッジ検査 | 5750/6264行＝91.79%、80%条件成功 | 同native job末尾 |
| 新cloud UI回帰 | 3件成功、105.209秒 | 同native job |
| 既存写真復帰回帰 | 11件成功、351.385秒 | 同native job |
| traceability | pass=true、uncovered=[]、7ID対応あり | sensor-traceability --stage build-and-test |

機能558件はCore480＋UI78。先行Core480を二重加算しない。smoke2は別枠。選択された機能試験にskipはない。既存性能区分は機能実行から除外され、新しい実機性能結果を意味しない。CI内bundleは `.build/Native-functional-20261106-134055-8cdbd2bc965c4e53ae887a46b6160574.xcresult`。ローカル取得/重複試験はしていない。

## Red/Greenと失敗の区別

Core6件の意図Red（通信許可、進捗、長期待機）→17件Green→Session否定回帰を含む20件成功。画面3件の意図Red→選択可能Textの古い値を保持する問題と観測不備の切分け→状態文字更新修正後3件成功。通常CIは一度30分枠で中断したため45分へ変更し、次の全体実行で画像AX要素1件が失敗した。スクロール位置での反映待ちを修復し、当該1件と上記最終全体で成功した。途中実行を全体成功や全体coverageへ代用していない。

## 合格と既知制約

実行した自動試験とcoverage条件は全て成功した。ただし、独立レビューで、取得開始通知/容量照会をawaitする間の取消が要求生成へ引き継がれない経路（R-01、Major）が指摘された。この境界の回帰は今回の成功558件に含まれず、FR3を完全に満たしたとは記録しない。本人はCode Generationの承認a0a6ec0dでこのリスクを受容して続行した。修正済みや検証済みへ変更しない。

実Photos/iCloud・一般clipboard・OS設定は自動操作していない。合成画像と所有UUID領域/試験pasteboard、app内cleanupを使用した。cloud fixtureは記事readerの観測を分離するためPicker adapterを分けており、新UIだけで通常共有構成の実iCloud取得を証明しない。本人確認はDeployment Executionで行う。

手書き対象ソース/試験のdiff-checkは成功。監査ログの自動記録に末尾空白が生じたことがあり、エンジン所有監査は手修正していない。アプリのビルド/試験失敗とは区別する。
