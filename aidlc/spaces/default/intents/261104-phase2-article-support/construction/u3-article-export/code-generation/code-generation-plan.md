# U3 四枚と記事の出力 実装計画

## Summary

- Builds: 保存済み記事と画像4枚の安全な一式出力、取消・回復、本文コピーとFinder接続。
- Touches: HitotsuzuriCoreの出力処理、既存記事画面、U3専用試験、共通runnerと専用スクリプト。
- Tests: 単体約55件・統合12件・UI8件・U3性能2件。差替え障害注入、全機能CIと全製品80%を確認。

## Inputs and Scope
同Unitのfunctional-design、nfr-requirements、nfr-design/security-design.mdとlogical-components.md、infrastructure-design/cicd-pipeline.md、inceptionのcomponents.md・contract-summary.md C2/C3・unit-of-work.md・story-map・requirements.mdを入力とする。
本人7877ba2dのR-01修正を必須とし、公開前後の実体/期待一式照合と、不一致時の非成功・所有不明物非削除を実装する。現在は計画だけで、U3のコード・新コマンド・試験は未実装である。

## Baseline and Change Surface
既存候補2337dd6のCI41945323042と本人Mac完了確認が、Core371＋UI55＝426件、別smoke2件、製品全体4207/4673＝90.03%で成功した。U3はまだ含まれない。変わっていない長時間の基準を再実行せず、runner準備のU3契約試験から始める。
現行C3はSavedExportInput/PreparedArticleExport/ArticleOutputActionsを公開し、ArticleDraftSessionが現在入力コピーとprepareSavedExportを持つ。ArticleDirectoryは親descriptor・nofollow・排他・同期・非置換moveを持つ。これらを再利用し、一枚probeを四枚成功へ流用しない。
影響は出力の新規処理と記事画面の接続。既存C1保存原本・選択schemaVersion1・本文投影・画像用途を変えない。共有のArticlePresentationと画面接続は既存回帰で検証する。ユーザーのshared scheme変更、Phase1記録、README、既存成果物は保持する。

## Planned Source Paths
以下だけを作成/変更する。コード生成完了時に実際の変更をsource-manifest.jsonへ記録する。既存型への破壊的変更・無関係なリファクタリング・新しい外部依存は行わない。

| 区分 | パス |
|---|---|
| 新規Core | HitotsuzuriCore/ArticleExportModels.swift、ArticleExportManifest.swift、ArticleExportPorts.swift、ArticleExportFileSystem.swift、ArticleExportJournal.swift、ArticleExportWriter.swift、ArticleExportDelivery.swift、ArticleExportOSActions.swift、ArticleExportSession.swift |
| 既存Core接続 | HitotsuzuriCore/ArticlePresentation.swift |
| 新規画面 | Hitotsuzuri/ArticleExportView.swift |
| 既存アプリ接続 | Hitotsuzuri/ArticleAppCoordinator.swift、ArticleView.swift、DebugFixture.swift、HitotsuzuriApp.swift |
| 新規単体/統合 | HitotsuzuriU3Tests/ArticleExportContractTests.swift、ArticleExportModelTests.swift、ArticleExportJournalTests.swift、ArticleExportWriterTests.swift、ArticleExportDeliveryTests.swift、ArticleExportOSActionTests.swift、ArticleExportSessionTests.swift、ArticleExportIntegrationTests.swift、ArticleExportTestDoubles.swift |
| 新規UI | HitotsuzuriUITests/ArticleExportUITests.swift |
| runner | 新規scripts/verify-article-export.sh、変更scripts/native-test-runner.pyとscripts/test-native-runner.py |

新規Swiftファイルは既存の同期フォルダから既存Core/U3/UIターゲットへ入れる。Xcode projectや共有schemeを新たに変更する計画ではない。AppKitの実OSアダプタはCore既存フレームワーク内へ置き、Core試験から名前付き専用pasteboardと注入workspaceで検証できる形にする。
C3公開値を複製せず、画像/時計/ファイル操作/OS表示を小さな境界で注入する。新規のファイル実体照合はArticleDirectoryを利用する専用拡張に置き、既存C1やprobeの動作を無断変更しない。

## Ordered Implementation
- [x] Step 1 — 構成と準備。上記パスの責務・依存を固定し、既存C2/C3と同期ターゲットを確認。宣言用の最小構成を用意し、既存CI/Mac基準を記録する。機能本体は後続Greenで実装。（US1.4/1.6/1.7/1.8）
- [x] Step 2 — runner準備。U3専用ラッパーと共通runnerのexport区分を短い契約試験でRed/Greenにし、既存C3値の受領/不一致拒否を確認するArticleExportContractTestsの3件を作る。専用コマンドが実行3件・0skipで通るまで次へ進まない。これは新機能のGreenではなく契約/runner準備である。（NFR5.30）
- [x] Step 3 — データモデル Red。ArticleExportModelTests 8件でmanifest版/四枚/順序/指紋/設定/相対参照/自由文字を先に失敗させる。型未存在によるコンパイル失敗だけを機能Redとせず、最小宣言を整えて実アサーション失敗を記録する。（US1.6/1.7）
- [x] Step 4 — 同層 Green。ExportJob/manifest/回復記録の値と検証を最小実装し、PreparedArticleExportとU2投影を利用する。（US1.7）
- [x] Step 5 — 同層 Refactor。重複する検証と生成名を整理し、同じ8件をGreenで確認。記事保存schemaは変更しない。（US1.7、NFR2/6）
- [x] Step 6 — 保存/ファイル境界 Red。Journal 8件、Writer 12件で原子的記録・同ID照合・所有・同期・公開前後・一時名/完成名差替え・symlink・容量/権限・片付け失敗を先に再現する。R-01は検証後/公開直前検査後/rename後の各位置へ注入し、未検証成功と所有不明物の削除を拒否する。（US1.7、NFR2.30〜33）
- [x] Step 7 — 同層 Green。親descriptorと検証済み一時実体を保持し、非置換公開の前後に実体/全digestを照合するWriter、専用ExportJobsと排他/旧値照合のJournalを実装。公開後同期失敗は削除せず同ID照合へ。通常ログに私的値を出さない。（US1.7）
- [x] Step 8 — 同層 Refactor。直列I/Oと記録/Writerを分離し、同じ障害群をGreenで再確認。所有未証明の中断物は保護して案内する。（US1.7、NFR2/6）
- [x] Step 9 — 業務制御 Red。Delivery 8件、Session 8件、Integration 12件で保存済み固定入力・四枚順次処理・二重開始・古い応答・単調期限・取消/確定前後・再起動照合を先に再現する。（US1.4/1.7）
- [x] Step 10 — 同層 Green。C2画像取得と共有予算、制御actor/専用直列I/O、同ID結果照合、進捗と単一終端を実装。取消受理と実収束を区別し、画像を一枚ずつ書込後に解放する。（US1.4/1.7、NFR3.30〜33）
- [x] Step 11 — 同層 Refactor。状態遷移・失敗分類と解放を整理し、同じ業務/統合群をGreenで確認。未完を成功とせず旧記事と完成物を保つ。（US1.7）
- [x] Step 12 — OS操作境界 Red。OSAction 8件で現在入力/固定完了本文、clipboardFailure、Finder不在/失敗、grant不一致・寿命を先に失敗させる。専用の名前付きpasteboardを用い、本人のgeneral pasteboardを読む/上書きする試験を避ける。（US1.6/1.8）
- [x] Step 13 — 同層 Green。ArticleOutputActionsの実装と保存先grant登録を接続。コピーは文字だけ、Finder結果は出力成功と別。テストではworkspace注入を使い、実Finder/実Sandbox/noteは本人確認へ残す。（US1.6/1.8）
- [x] Step 14 — 同層 Refactor。OSアダプタと制御の責務を整理し、同じ境界試験をGreenで再確認。C3契約と既存probe表示を保持する。（US1.6/1.8）
- [x] Step 15 — Frontend Red。ArticleExportUITests 8件で保存前確認/取消、正常一式、写真不能、取消/片付け失敗、固定完了コピー、Finder失敗、幅/キー到達、回復の表示を先に再現する。起動smokeを先行させ、起動障害を機能Redにしない。（US1.4/1.6/1.7/1.8）
- [x] Step 16 — 同層 Green。既存記事画面へコピー/一式出力/進捗/取消/完了/回復を配線し、対象編集・保存・切替を制御。終端で制御と焦点を戻す。既存画像一枚検証は別操作名のまま維持。（US1.6/1.7/1.8）
- [x] Step 17 — 同層 Refactor。薄い画面部品とcoordinatorの配線を整理し、同じUI群をGreenで確認。640×560、959/960/961/1200幅、名称200/本文各10000文字は検証条件で入力上限ではない。（NFR4.30/31）
- [x] Step 18 — 完成候補検証。U3の新規性能2件を本人Macで一回実測し、全機能CIと全製品80%以上を確認。期限/予算の決定論的試験は機能CI、実時間/実メモリはMacのみ。失敗時は代表群で切り分け、長い全体と成功済みの無関係な性能を反復しない。（NFR1〜7）
- [x] Step 19 — 記録。実変更全パスのsource-manifest、全18AC/16詳細NFRの対応表、Red/Green/整理/未実施、環境と戻し方、本人の実写真/保存先/note確認を記録する。その後、独立レビューと既存正式コマンドの完了確認へ渡す。（全US、NFR5/7）

HTTP API、DB移行、クラウド/IaC、公開配布は非該当。OS操作ポートをAPI境界に相当する試験可能層として扱う。各層はRed→Green→Refactorの順を維持する。

## Verification and Limits
- 画像1件30秒・書込込み40秒、全体180秒で新規工程/確定開始を止める。確定開始済みは成否の照合を優先し、取消を成功と偽らない。
- 一件変換、共有直接画像256MiB/プロセス増分512MiB、取消受理0.5秒・画像論理終端2秒を維持。FS片付けp95≤5秒、正常四枚p95≤10秒を本人Macで計測。元条件の詳細はNFR要件を正本とする。
- 新しい性能ケースはArticleExportIntegrationTests内のtestFourImageExportThirtyTrialsPerformanceとtestExportMemoryAndCancellationThirtyTrials。CI/通常機能から両方を除き、専用--performanceで両メソッドの実行成功を検査する。
- 現在のCIの2jobと正式機能/全製品80%を維持する。共有runnerの短い契約にU3選択、性能除外、未実行拒否を追加し、率の平均・ソース除外で基準を変えない。
- 実写真の現在編集/回転/色/GPS除去、実保存先Sandbox、Finderの実表示、note貼付けと画像順は本人確認。Fake成功を実OS操作成功や実機完了へ広げない。
- 新しい外部依存、有料追加、保存先権限の永続化、写真/下書きの送信、認証/TCC/キーボード設定変更は行わない。既存の作業ブランチで進め、main統合や配布はこの計画で実施しない。

## Testing Contract

```json
{
  "version": 1,
  "methodology": "tdd",
  "source": "team",
  "ordering": "各テスト可能な層で、先にテストを書いて意図した失敗を確認し、最小限の実装で成功させ、成功を保ちながら整理するred-green-refactorの順序で進める。",
  "scope": "mvp",
  "test_strategy": "standard",
  "project_type": "brownfield",
  "applicable_notes": [
    {
      "layer": "org",
      "text": "We treat tests as a first-class deliverable in every Bolt. The specific\nmethodology (TDD, BDD, ATDD, or classic test-after) is affirmed at\npractices-discovery and recorded in `team.md` under this heading with explicit\n`Methodology` and `Ordering` fields; Code Generation resolves those fields\nindependently from coverage, tooling, and scope notes.\n\nWhen no posture has been affirmed, our default per scope is:\n- **Methodology**: test-after\n- **Ordering**: implement each applicable testable layer, then write and run\n  that layer's tests.\n- `mvp`, `enterprise`, `feature`, `infra`, `classic` add an 80% line-coverage\n  floor and CI execution before merge.\n- `bugfix`, `security-patch` add a targeted regression for the specific\n  bug/vulnerability and require the existing suite to remain green.\n- `express` uses the Minimal strategy: requirement-driven unit tests (one per\n  requirement, with a happy-path floor per component); existing tests remain\n  green.\n- `poc`, `refactor`, `workshop` add no extra new-test floor and require the\n  existing suite to remain green.\n\nThe active `Test Strategy` still applies in every scope and determines test\nvolume/types. Scope floors are additive; they never reduce or replace the\nselected strategy.\n\nBuild and Test verifies defined coverage floors and affirmed quality targets;\nthey may not be weakened to make a step pass.\n\nAffirm a stricter posture in `team.md` if the team commits to one."
    },
    {
      "layer": "team",
      "text": "- **Methodology**: tdd\n- **Methodology evidence**: 現行の`memory/team.md`で本人確認済み。Phase2でも維持する。テストファイルの存在だけからTDDと推定したものではない。\n- **Ordering**: 各テスト可能な層で、先にテストを書いて意図した失敗を確認し、最小限の実装で成功させ、成功を保ちながら整理するred-green-refactorの順序で進める。\n- 製品全体の80%以上の行カバレッジと統合前CIを維持する。既存のXCTest・Xcode・カバレッジ検査スクリプトを出発点とし、Phase2の計測対象と必要な追加を計画で明示する。\n- CI構成は現行リポジトリで確認できず、本人も実行環境はまだ用意できないと回答した。今は実行先を決めず要件・設計を進め、実装計画でCI実行先・設定・費用の有無を具体化して本人確認する。実行元・権限・隔離・実行条件もその計画で扱う。\n- Phase1のCI省略の個別決定を、Phase2の免除として引き継がない。統合前CIの条件を満たすまでは統合完了と扱わず、ローカルで手動実行したテストをCI実行済みと記録しない。\n- 保存・復元・順序・日付候補・出力・失敗・取消等の自動試験と、実写真・写真アプリの編集結果・Sandbox・noteへの手動受渡しを確かめる本人の実機確認を区別する。未確認を自動試験の成功で補完しない。\n- 本人指定によりVoiceOverの追加設計・検証は要求しない。既存実装を削除する方針にはしない。キーボード・狭幅・長文・状態の文字表示は今回の確認対象に残す。"
    }
  ],
  "obligations": {
    "strategy": "standard",
    "strategy_volume": [
      "Five to eight tests per component.",
      "Unit tests plus integration tests for key boundaries.",
      "Add E2E, performance, or security tests when requirements demand them."
    ],
    "scope_floor": [
      "Meet an 80% line-coverage floor.",
      "Run the selected tests in CI before merge."
    ],
    "combination_rule": "Apply every selected-strategy obligation and every scope-floor obligation; neither replaces the other, and a targeted scope regression may add the narrowest necessary test type beyond the strategy default."
  },
  "plan_profile": {
    "methodology": "tdd",
    "runner_step": "Verify the existing test runner/configuration and record the exact unit-scoped command.",
    "runner_ready_before_first_test": true,
    "testable_layers": [
      "Data model / database behavior",
      "Repository / data access",
      "Business logic",
      "API / endpoint",
      "Frontend behavior"
    ],
    "steps": [
      "Project structure and production configuration skeleton.",
      "Verify the existing test runner/configuration and record the exact unit-scoped command.",
      "Data model / database behavior - Red: write the failing tests and record the failing command output.",
      "Data model / database behavior - Green: implement only enough behavior to pass.",
      "Data model / database behavior - Refactor: improve the implementation while tests stay green.",
      "Repository / data access - Red: write the failing tests and record the failing command output.",
      "Repository / data access - Green: implement only enough behavior to pass.",
      "Repository / data access - Refactor: improve the implementation while tests stay green.",
      "Business logic - Red: write the failing tests and record the failing command output.",
      "Business logic - Green: implement only enough behavior to pass.",
      "Business logic - Refactor: improve the implementation while tests stay green.",
      "API / endpoint - Red: write the failing tests and record the failing command output.",
      "API / endpoint - Green: implement only enough behavior to pass.",
      "API / endpoint - Refactor: improve the implementation while tests stay green.",
      "Frontend behavior - Red: write the failing tests and record the failing command output.",
      "Frontend behavior - Green: implement only enough behavior to pass.",
      "Frontend behavior - Refactor: improve the implementation while tests stay green.",
      "Environment/build configuration.",
      "Documentation and traceability."
    ]
  },
  "input_sha256": "sha256:223f5f4129ef7c18f089e6a163ce0beb00752af714824e099f72cfb9407813ef",
  "contract_sha256": "sha256:ed23923bbd3a0ced40caa5d9c39ecd8231ea03d2ce756ee4d6dc65537c72c960"
}
```

