# ビルド・試験の判定

## 入力と検証範囲

`../code-generation/code-generation-plan.md`、`../code-generation/unit-test-instructions.md`、`../code-generation/code-summary.md` を入力とする。要件は `../../inception/requirements-analysis/requirements.md` のFR1–FR3/NFR1–NFR3、測定条件は計画のTesting Contractと既存CI。個別のnfr-requirements/nfr-design成果物やUnitはこのbugfixにはない。

Minimalのため追加の統合・性能・security手順ファイルは生成しない。既存Core単体/統合と追加したネイティブUI回帰は最終CIで検証済み。ビルド手順はbuild-instructions.md、実行結果はtest-results.md、6要件の対応はcross-unit-traceability.md。

## Target Verification Matrix

| Target ID | Source | Expected | Actual | Evidence | Owning Stage | Verdict |
|---|---|---|---|---|---|---|
| FR1-display | requirements FR1、計画T1/T9 | fresh再開の4枚と順序、取得不能の文字状態、利用可能後の回復 | T1/T9成功 | CI42179866652、新11件、test-results.md | build-and-test | Met |
| FR2-return | requirements FR2、計画T2–T8/T10/T11 | 全出力終端後に同じ記事だけ復帰、旧応答排除、後照会まで排他 | 各ケース成功 | 同CI、旧応答/保持/連続出力の実要求と画像要素 | build-and-test | Met |
| FR3-retry | requirements FR3、計画T9 | mouse/keyで対象要求が増え実画像を表示、他番号/入力保持 | T9成功 | 同CI、新UI回帰 | build-and-test | Met |
| NFR1-preservation | requirements NFR1 | 本文/順序保持、合成データ専用、保存/権限/通信方針維持 | 新11件＋既存保存/出力回帰成功、関連方針変更なし | test-results.md、code-summary.md、ソース差分確認 | build-and-test | Met |
| NFR2-limits | requirements NFR2 | 15秒期限、256MiB予算、旧応答排除、実終端待ちと直列化 | 既存ArticleImage/PreviewRetry/ResourceとT4/T10/T11成功 | CI42179866652 Core460＋UI75 | build-and-test | Met |
| NFR3-tdd | requirements NFR3、Testing Contract | 意図したRed→Green、既存機能維持、CI優先 | 有効な表示欠落5件/再受理1件のRed→Green、機能535件成功 | ci-evidence.md、test-results.md | build-and-test | Met |
| TC-coverage | Testing Contract applicable_notes.team | 全手書きApp/Core行カバレッジ80%以上 | 5527/6041＝91.49% | CI42179866652の全機能coverage検査exit0 | build-and-test | Met |
| TC-runner | Testing Contract plan_profile | 既存runnerを先に確認、試験を発見・実行 | runner28成功、新11件を全機能へ収録 | native-core127766730191、native127767229796 | build-and-test | Met |

CI Pipelineはこのbugfixの計画にないため、その段階が新たに構築するCI義務はN/A（the plan runs no CI Pipeline）。これとは独立して要件NFR3が求める統合前CIは既存workflowで実際に満たしており、上表ではMetとした。

## 判定と引継ぎ

自動ビルド/試験の判定は成功。現在の製品/試験/runner/CIソースは検証済みf272e3dと一致し、同じ試験をローカルで繰り返していない。追加の閾値緩和、coverage除外、無関係な変更はない。

本人Macで「下書き再開→4枚表示→出力または取消→復帰→必要時の再試行→本文/順序保持」を行う受入確認は、要件NFR3の定める最終段階Deployment Executionで記録する。今回の自動検証成功はその代用ではなく、実機解消済みやPhase2統合完了とは扱わない。配布・公開・mergeは行わずPRはDraftを維持する。
