# ビルド・試験判定

## 入力と対象

`../code-generation/code-generation-plan.md`、`../code-generation/unit-test-instructions.md`、`../code-generation/code-summary.md` と、承認済みrequirementsの7IDを確認した。個別NFR設計/Unitは今回のbugfixにはない。Minimalのため追加の統合/性能/security手順ファイルは作成しない。既存Core単体/統合と最小のnative UI回帰を通常CIで検証した。

## Target Verification Matrix

| Target ID | Source | Expected | Actual | Evidence | Owning Stage | Verdict |
|---|---|---|---|---|---|---|
| FR1-acquisition | requirements FR1、plan T1/T2/U1/U3 | 出力のみPhotoKit取得許可、4枚順序付き出力 | optionsと実出力経路の回帰成功 | CI42226898333、test-results.md | build-and-test | Met |
| FR2-progress | requirements FR2、T3/T4/U1 | 番号/進捗、旧通知拒否、100%と一式成功の区別 | Core/実画面回帰成功 | 同CI、新Core20/UI3 | build-and-test | Met |
| FR3-cancel-active | requirements FR3、T7/T8/U2 | 取得中取消、実終端待ち、復帰 | 対象取消回帰成功 | 同CI | build-and-test | Met |
| FR3-cancel-start | requirements FR3、取得開始前の取消 | 取消を取得生成へ引き継ぐ | 進捗通知/容量await中の取消の抜けが残る。本人受容済み | code-generation/reviews/review-01.md、承認a0a6ec0d | code-generation | Not Met |
| FR4-retry | requirements FR4、T9/T10/U3 | 番号/理由/アプリ内再試行、一式成功を偽らない | 写真2失敗後の再出力成功 | CI42226898333 | build-and-test | Met |
| NFR1-wait | requirements NFR1、T5/T6/T12 | 旧30/40/180秒超過の取得待ちを許容、UIを塞がない | 仮想301秒待機/変換書込期限/進捗なし取消回帰成功 | 同CI、Core回帰 | build-and-test | Met |
| NFR2-protection | requirements NFR2 | 固定入力/本文/順序、資源/世代/所有/旧成果物維持 | 新旧Core480/画面78の回帰成功、関連方針の差分確認 | 同CI、code-summary.md | build-and-test | Met |
| NFR3-tdd | requirements NFR3、Testing Contract | 意図Red→Green、既存機能とCI成功 | 意図した失敗と修正後成功を記録、558機能/2smoke成功 | ci-evidence.md、test-results.md | build-and-test | Met |
| TC-coverage | Testing Contract team notes | 全手書きApp/Core行カバレッジ80%以上 | 5750/6264＝91.79% | 全機能coverage exit0 | build-and-test | Met |
| TC-runner | Testing Contract plan_profile | runner準備、新classを発見・実行 | runner28成功、新Core20/UI3を収録 | native-core127922551662/native127923376367 | build-and-test | Met |

CI Pipeline段階の構築義務はthe plan runs no CI PipelineのためN/A。ただし要件NFR3の既存統合前CIは実際に満たしている。実iCloudの本人確認は要件が指定した最終段階Deployment Executionへ引き継ぎ、自動回帰の成功で代用しない。

## 判定と受容済みリスク

自動ビルド/全機能/coverageは成功。全要件を無条件に満たす成功判定ではなく、FR3の取得開始境界にNot Metが1行残る。本人はCode Generationの承認a0a6ec0dでR-01を受容して続行した。同じリスクへの修正指示や再承認を推定せず、ここでも未修正の制約として引き継ぐ。取消開始境界を自動試験成功で補完しない。

配布/公開/mergeは行っていない。PRはDraft。本人Macで写真アプリの事前取得なしの出力、取得状態/進捗、成功後の4枚と本文/順序を確認する。取得開始直前の取消は受容済みの制約があり、いつでも確実に取消完了できると案内しない。
