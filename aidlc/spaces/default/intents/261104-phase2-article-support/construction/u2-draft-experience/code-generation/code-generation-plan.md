# U2 下書き編集の実装計画

## Summary

- Builds: 実装済みU2を保持し、起動確認先行・通常回帰/詳細性能分離・試験データ回収へ検証を改訂
- Touches: U2のUI試験と共有fixture、専用/正式検証スクリプト、CIの実行区分と検証記録
- Tests: 機能保証と性能の回数/閾値を維持。起動失敗時の後続停止を短く検証し、全製品80%以上・統合前CIを維持

## 入力・現在地

同Unitのfunctional-design/functional-spec.md、frontend-components.md、nfr-requirementsの3文書、nfr-designの3文書、inception/requirements-analysis/requirements.md、user-stories/stories.md、domain-design/components.md、contract-design/contract-summary.md、units-generation/unit-of-work.mdとunit-of-work-story-map.mdを実装根拠とする。U2のInfrastructure Designは新しい基盤/権限/実行先がなく、既存を継続するため適用外。アプリの対応macOS 27・Swift 6・Sandboxを維持する。

U1のローカル全検証は2026-11-04の認証画面解消後に成功（UI32件、全製品2758/3050=90.43%）。最新a108134のCIはCore273件とArticle UI6件が成功した一方、既存Native UI8件が失敗し、旧baselineでも同じ8件が失敗した。CI全体は失敗のままで、統合前の成功条件を免除しない。この計画の追加試験は未作成/未実行。実写真・Sandbox・note手動受渡しは本人確認を別に残す。

## 変更対象と責務

| 対象 | 変更内容 |
|---|---|
| HitotsuzuriCore/ArticleInitialContent.swift（新規） | 新規に限る絶対末尾ASCII@6桁・暦解析、タイトル候補と空本文 |
| HitotsuzuriCore/ArticleMetadataInput.swift（新規） | raw年月日、年1〜9999、候補/確認/削除、検証とraw差分 |
| HitotsuzuriCore/ArticleProjection.swift（新規） | 記事ID付き不変文脈、plainText/Markdown、固定4参照、共通指紋、文字エスケープ |
| HitotsuzuriCore/ArticleOutputPorts.swift（新規） | C3の値/操作ポート/能力、保存済み出力準備の境界。実OS/四枚書込はU3 |
| HitotsuzuriCore/ArticlePresentation.swift（新規） | 開始/候補/一覧/部分失敗/離脱/投影要求の単一状態調整。永続contentはEditSessionだけ |
| HitotsuzuriCore/ArticleWorkspace.swift | C1の選択読取・照合・開く/一覧・関連付け接続。既存resolveも回帰維持 |
| HitotsuzuriCore/ArticlePorts.swift | C1関連付け操作、編集状態の公開境界、必要な固定分類診断。必須の既存意味を保持 |
| HitotsuzuriCore/ArticlePersistence.swift | 既存current/operations形式のまま関連付けを同じlock/照合/原子的確定へ追加 |
| HitotsuzuriCore/ArticleFingerprint.swift | 既存content指紋は不変。関連付け操作のkind/新選択/期待版を区別する操作指紋 |
| HitotsuzuriCore/ArticleEditSession.swift | 新規初期content注入、pending不確定の読取専用状態、raw日付検証との保存/離脱接続。R-01回帰維持 |
| HitotsuzuriCore/ArticleImageAccess.swift | 表示用の番号別再試行、要求世代/取消。既存高解像度成果物経路の意味を変えない |
| Hitotsuzuri/ArticleAppCoordinator.swift | Core調整側の注入と画面接続。単一候補/離脱シート、閉鎖/終了の一回の応答、元delegate復帰 |
| Hitotsuzuri/ArticleView.swift | 960pt切替、全本文欄・撮影情報、保存状態、編集/プレビュー、可視ラベル/キー/焦点 |
| Hitotsuzuri/ArticleMetadataFields.swift、ArticlePreviewView.swift（新規） | 日付raw入力/確認と自由撮影情報、同じ作業値のネイティブプレビュー |
| Hitotsuzuri/HitotsuzuriApp.swift、PickerView.swift | 記事メニュー/既存入口を同じ開始要求へ接続。既存Picker状態/焦点を保護 |
| Hitotsuzuri/DebugFixture.swift | 再確定/複数候補/不正日付/写真不能/遅延/失敗/長文の独立DEBUG fixture |
| HitotsuzuriU2Tests/ArticleDraftTestDoubles.swift（新規） | C1/画像/時計/C3/診断の固定・遅延・失敗Fake。実OS成功の代用にしない |
| HitotsuzuriU2Tests/ArticleInitialContentTests.swift、ArticleMetadataInputTests.swift、ArticleProjectionTests.swift（新規） | 入力/投影の各8件を目安 |
| HitotsuzuriU2Tests/ArticleAssociationTests.swift、ArticleEntryTests.swift、ArticleNavigationTests.swift（新規） | 関連付け・入口・離脱の各8件を目安 |
| HitotsuzuriU2Tests/ArticleDraftSessionTests.swift、ArticleOutputPreparationTests.swift、ArticlePreviewRetryTests.swift、ArticleDraftIntegrationTests.swift（新規） | 保存状態・C3準備・表示画像・境界接続の各8件を目安 |
| HitotsuzuriU1Tests/ArticleSessionTests.swift | ArticleStoring拡張で必要となる既存Fakeの適合。既存不確定/容量/保存中編集の試験を削除・弱化しない |
| HitotsuzuriUITests/ArticleDraftUITests.swift（新規） | 約12件の実UIフロー、配置/文字/キー/閉鎖/再開。U3未実装操作は成功扱いしない |
| scripts/verify-draft-experience.sh（新規） | 上記クラスの厳密な選択・実行済み検査、任意の狭域クラス引数、固有xcresult |
| 本Unitのcode-generation記録 | 完了時code-summary/traceability/source-manifest/TDD証拠/本人確認手順/CI証拠 |

Xcodeの既存同期フォルダ/試験targetを用いる。pbxprojやshared scheme・entitlement・workflow・coverage checkerの変更は予定しない。本人の未コミットscheme変更や他の既存ファイルは保持する。新たなパッケージ/formatter/linter/有料runnerは導入しない。

## 実装手順

- [x] Step 1 — 構成/試験準備。既存の限定コマンドでrunnerを確認し、専用verify-draft-experience.shと試験fixtureの準備を行う。試験targetへの新ファイル自動所属と実行クラス照合を確認。最初のRedより前に実行可能なコマンドを確立する。（US1.1〜US1.7、NFR5）
- [x] Step 2 — データ/入力層 Red。InitialContent/MetadataInput各8件を先に書き、絶対末尾・末尾改行・全角・閏日・不正日・空タイトル・年境界・確認/変更/削除・raw保持の意図した失敗を記録。（US1.5）
- [x] Step 3 — 同層 Green。新規専用factoryとraw日付状態を最小実装。既存ArticleContentの保存形式/旧記事の初期値を勝手に変更せず、日付不正もdirtyへ反映する。（US1.2/1.5）
- [x] Step 4 — 同層 Refactor。元文字列の保持と暦検証を共通化し、同じ試験Greenを再確認。（US1.5）
- [x] Step 5 — 永続境界 Red。Association8件で同写真再確定、順序違い拒否、期待版競合、同操作反復、入力違いID再利用拒否、不確定後照合、旧source/本文/候補保持、部分失敗を先に再現。（US1.1/1.2）
- [x] Step 6 — 同層 Green。C1の不足する読取/関連付け接続を完成し、永続化の既存操作鎖へ追加。関連付けは新選択IDだけを集合へ追加し、変更時のみ保存版/更新日時を進め、元source/content/内容指紋は不変。同操作は原結果へ照合し、別入力再利用を拒否。schemaVersion1の既存形式を維持。（US1.1/1.2）
- [x] Step 7 — 同層 Refactor。create/save/関連付けのlock/確定/照合を重複させず整理し、U1保存/旧形式/未知版保護の回帰を維持。（US1.1/1.2）
- [x] Step 8 — 業務/状態層 Red。Projection、Entry、Navigation、DraftSession、OutputPreparation、PreviewRetry各8件を先に書く。候補複数/全体・部分失敗/連打、現在入力投影、保存中追加入力、不確定照合の連続I/O失敗、全離脱先、写真不能/古い結果、U3 Fakeとの境界を失敗で示す。（US1.1〜US1.7のU2担当）
- [x] Step 9 — 同層 Green。純粋投影と単一Presentation状態機械を実装。記事ID付き文脈、raw検証、save/discard/continue、固定入力/世代、保存前出力準備、番号別再試行を接続。OSポート未接続は無効。保存結果不明をfailed表示の最新分類から独立して保持する。（US1.1〜US1.7）
- [x] Step 10 — 同層 Refactor。入力/正本/画面状態の所有を整理し、画像/本文投影の重複保持や大域active article依存を除き、同じ試験をGreenで維持。（US1.2/1.4/1.6）
- [x] Step 11 — 境界統合 Red。DraftIntegration8件で実C1保存/再開・新旧選択の関連付け・不正日付・遅延/別記事・同指紋別記事・固定出力準備・ログcanaryを先に再現。OS出力はFake。（US1.1〜US1.7）
- [x] Step 12 — 同層 Green。Coordinator/Workspace/EditSession/Projectionの実接続と依存注入を完成。閉鎖/終了は一つの保留先と一回のreplyを持つbridgeへ。切替先準備失敗時は旧作業を残す。（US1.1〜US1.7）
- [x] Step 13 — 同層 Refactor。状態採用/失敗表示と匿名診断を整理し、統合Greenと既存Article回帰を確認。（US1.2/1.3/1.4）
- [x] Step 14 — Frontend Red。ArticleDraftUITests約12件とDEBUG fixtureを先に追加し、入口2か所、候補/再確定、全欄保存/再起動、raw不正/離脱、取得不能、幅/長文/キーボード、プレビュー切替、閉じる/終了の保留を失敗で確認。（US1.1〜US1.6）
- [ ] Step 15 — 同層 Green。ArticleView/MetadataFields/PreviewViewを実装してアプリへ接続。640/959/960/961/1200pt、見えるラベル・状態文字・焦点復帰を満たす。記事用UI識別子を付け、既存PickerのTab/Shift-Tab回帰を維持。（US1.1〜US1.6）
- [ ] Step 16 — 同層 Refactor。画面部品とOS bridgeを整理し、同じUI試験をGreenで再確認。U1画像1枚検証は別操作名のまま保持。（US1.3/1.4/1.6）
- [ ] Step 17 — 全体検証/性能/安全性。専用試験、既存Article回帰、正式な全体検証を実行。保存/再開2秒p95・投影100ms p95・文字切替0.5秒、表示15秒/取消2秒、256MiB直接保持/512MiB増分、ログcanaryを定めた条件で計測。全製品80%以上を確認。承認済み公開ブランチへコード/試験をpushして同じCIを実行し、未達/失敗は隠さず停止・報告する。（NFR1〜NFR7）
- [ ] Step 18 — 記録/対応表。作成変更削除の全パスをsource-manifestへ、全AC/NFRと対象外U3をtraceabilityへ、Red/Green/整理と未実行理由・本人未確認項目をcode-summary等へ記録する。Xcode起動/戻し方を日本語で用意し、その後に独立レビューを受ける。（US1.1〜US1.7、NFR5/6/7）

API/HTTPエンドポイント・DB移行・コンテナ/IaC・公開デプロイは適用外。C3の操作ポートは業務/境界統合層で試験する。各層のRedは対象機能のアサーション失敗を確認し、runner未設定・未実行・認証待ちをRedの証拠にしない。

## 実装時に明示する境界

- プレビュー投影中に入力が変わった場合、旧結果を不採用にした後で待機状態を必ず解除し、編集モードを維持して「内容が変わったため再表示」を案内する。最新入力での再要求を明示操作で可能にし、古い要求がloadingを永久保持しない試験を追加する。コピーは操作時の固定値と明示し、別記事の成功表示へ転用しない。
- 純粋投影は現在入力、出力準備は保存済み固定値。記事IDと内容指紋を別々に検証可能にする。日付raw不正なら旧有効値の投影/保存で置き換えない。
- U2はC3型/ポート/Fakeと保存前調整を作る。OSクリップボード/Finder、四枚JPEG/manifest/確定/取消/回復の実装はu3-article-exportで行う。製品で未接続操作を成功表示しない。
- Functional Designのtraceabilityにある担当先文字列u3-output-deliveryは正式名u3-article-exportを指す。実装の対応表は正式名に統一する。上流のレビュー済み文書自体はこの計画で無断編集しない。

## 検証・費用・変更管理

runner準備の既存限定コマンドは `bash scripts/verify-article-foundation.sh ArticleSessionTests ArticleWorkspaceTests`。新しい主コマンドは `bash scripts/verify-draft-experience.sh`。全体の正式検証は `bash scripts/verify-native.sh` を単独で実行する。全体の行カバレッジは既存check-coverage.swiftの加重集計で判定し、U2専用試験の部分カバレッジと混同しない。新規ソースも全体計測へ含め、除外で合格を作らない。

既存公開リポジトリの標準macOS CI（承認済みxcode-27、読み取り権限、固定checkout、追加有料runner/成果物upload/秘密情報なし）を継続する。新しいクラウド費用/公開配布は追加しない。既知Native UI8件のCI失敗は環境差の証拠と分け、再実行で成功するまで統合完了にはしない。OS認証画面が再表示された場合は本人操作が必要な状況を報告し、認証設定/TCC/グローバル環境を勝手に変更しない。

U1のローカル成功は今回のU2成功を意味しない。本人の未コミット変更を保持し、差分のあるコード/試験と必要な記録だけを対象としてコミット/公開する。mainへの統合や配布はこのコード計画の実施だけで完了扱いにしない。

## 本人指定によるテスト実行の改訂（2026-11-05）

本人承認5d3fcfa7、実施指示5a49178aにより、実装済みの機能と合格閾値を維持して以下を先に行う。

- fixture方式ごとの起動smokeを独立させる。Windowと入口を検査し、一つでも失敗したら通常UIと性能UIへ進まず非0終了する。共通前提の失敗を多数の機能失敗として繰り返さない。
- ArticleDraftUITestsの詳細反復3件（loading各30回、cold10起動、長文表示各30回）を性能クラスへ移す。通常UIにはloadingの入口/一覧各1回と保存中・画像取得中の入力保持を残す。性能クラスは元の回数・閾値・timeout検知を維持する。
- Coreの純粋条件と境界試験は維持する。既存Native入力・日付・保存・閉鎖・幅境界のアサーションを削らない。性能試験の除外を全体成功と呼ばない。
- 専用スクリプトと正式スクリプトにsmoke、通常回帰、性能、全体の明示的な実行区分を設ける。無引数は全体。CIの通常回帰と詳細性能を分け、最終全体の製品加重カバレッジ80%以上を維持する。分割bundleの率を単純平均しない。
- 長時間再実行の前に、引数検証・区分の選択・smoke失敗時の後続停止を短い代替実行で検査する。起動確認が通った後に関連ケース、通常回帰、性能の順で必要なものだけ実行する。
- UI fixtureの保存rootは各テスト固有とし、同一テスト内の再起動では保持、終了時には当該テストのrootだけを回収する。過去bundleや本人データを削除しない。

変更対象にHitotsuzuriUITestsの起動smokeクラス・性能クラス・共有起動補助、scriptsの区分/実行結果検査、既存2方式の起動前提、.github/workflows/verify.ymlの検証区分を追加する。追加パッケージ/有料runner/OS設定変更は行わない。既存の旧版比較ジョブは無断で取り除かない。詳細はtest-execution-revision.mdに記録する。

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
