# ビルド・試験結果

## 対象と入力

`../code-generation/code-generation-plan.md`、`../code-generation/unit-test-instructions.md`、`../code-generation/code-summary.md`、`../../inception/requirements-analysis/requirements.md` を照合した。個別NFR設計やUnitは今回のbugfixにはない。Red/Greenの詳細正本は `../code-generation/ci-evidence.md`。

## 最終CI

[通常PR CI42179866652](https://github.com/yokochie/hitotsuzuri/actions/runs/42179866652)、head **f272e3d4fb9783f38acc7745a1d3bcd8ac2b60b9**、success。製品/試験は対象限定Green c9a4d00と同一で、一時診断workflowは削除済み。

| 実行 | 結果 | 証拠 |
|---|---|---|
| python3 scripts/test-native-runner.py | 28件成功、4.031秒、exit0 | native-core job127766730191 |
| bash scripts/verify-native.sh --core | Core460件成功、exit0 | 同job、1分22秒 |
| bash scripts/verify-native.sh --functional | smoke2件と機能535件成功、exit0 | native job127767229796、25分30秒 |
| 全製品カバレッジ | 5527/6041行＝91.49%、80%検査成功 | 同native job末尾、check-coverage.swift |
| git diff --check | exit0 | 現在の作業領域 |
| git diff f272e3d -- Hitotsuzuri HitotsuzuriCore HitotsuzuriUITests scripts .github | 差分なし、exit0 | 現在の作業領域と検証済みheadの同一性 |

機能535件はCore460＋UI75で、Core先行460件を合算して995件とは数えない。smoke2件は別枠。新画像復帰11件を含み、選択された機能試験のskipは0。既存の性能区分は機能選択から除外されており、新しい実機性能測定の成功を意味しない。

環境はmacOS27.0.1 (26A434)、Xcode27.1 (27A9275)、arm64。CI内の主結果は `.build/Native-functional-20261106-072000-f6a6a6e0021a454eaf87ed5a9af5384d.xcresult`。ダウンロードやローカル重複実行はしていない。既存coverage対象/除外を変更せず、今回coverage-ignoreを導入していない。

## 回帰とTDD

- 表示欠落: d45acb7、CI42171059895のT2/T5/T6/T7/T8でownerなし・画像なしを確認。初回の観測不備、T3/T4のAX/手順不備は有効Redから除外した。8173d90、CI42172183678で10件成功。
- 連続出力: f160e52、CI42178316595のT11は、照会保留中の実入口で受理回数2（期待1）となり失敗。c9a4d00、CI42178850429では11件成功（315.966秒）。通常のbusy/復帰をfixtureで代行せず、実Coordinatorの受付と表示要求を検証した。
- 最終通常CIは修正前の534件結果へ代用せず、上記535件の新結果で判定した。失敗の原因・修復・SHAの詳細は上流ci-evidence参照。

## 範囲と未確認

自動試験はXCTest/XCUITestによるmacOSネイティブアプリで、ブラウザ試験ではない。合成画像・所有UUID領域・試験用pasteboardだけを使う。restore-* fixtureはPicker adapterを分けて記事driverを観測するため、新11件だけで通常の共有Pickerの相互作用や本人環境の解消を証明しない。既存の通常共有構成UI/Core試験も最終CIで成功した。

ローカルの同じbuild/native/UI/performance再実行、実Photos操作、一般clipboard、OS設定変更は行っていない。本人Macの実写真での表示解消はDeployment Executionで確認する。写真が通信せずローカル取得できることは前提であり、自動ダウンロードを追加していない。
