# 下書き写真表示の実装計画

## Summary

- Builds: 下書き再開・出力終了後の4枚表示、番号別再試行、出力後の記録確認まで含む連続出力の排他。
- Touches: ArticleAppCoordinator、ArticleView、必要なArticlePreviewView表示、DEBUG fixture、新しい画像復帰UIテスト。
- Tests: UI回帰11シナリオ（既存10件＋連続出力1件）をCIで検証し、通常の全機能・80%条件も維持。

## 対象と判断

承認済み `../../inception/requirements-analysis/requirements.md` のFR1–FR3、NFR1–NFR3を実装する。Zero Unitの1回の実装。User StoriesやUnit定義はスコープ上なく、要件IDを直接対応付ける。

コード上の原因候補は、出力前の表示資源破棄と、終了後の表示復旧の欠落。同一セッション判定とUIのnil早期returnが復旧を妨げる。本人のfresh再開で同じ原因かは未確定なので、両経路を回帰対象とする。

出力Sessionの終了後もCoordinatorは未完出力記録を非同期に確認する。この期間を含めて出力の所有を維持し、前の出力の後処理が次の出力中に表示を復帰しないようにする。2026-11-06の本人の変更依頼に従い、この制御と回帰1件を追加する。文書・README・Dependabot/GitHub基本設定の並行依頼は完了済みで、この修正のために再実行しない。

### 方針と比較

- 採用: Coordinatorに表示資源の停止・再生成・番号別再試行の責務をまとめる。現在のsession IDと表示ownerの存在/有効性を照合する。出力終端の全returnを覆う後処理から、画像処理の実際の終了後に同じ記事の表示を再開する。
- 不採用: 出力前の解放を取り除き、表示画像を保持し続ける。出力変換との同時保持を抑える既存の意図と予算を損なう。
- 不採用: Viewでnilを待ち表示にしたまま、再試行だけ無効化する。原因を残し、記事へ戻って写真を見る目的を満たさない。
- 保存形式・写真参照・PhotoKit通信・権限を変更する根拠はない。

## 影響範囲と変更予定

| パス | 変更と依存 | 影響 |
| --- | --- | --- |
| Hitotsuzuri/ArticleAppCoordinator.swift | synchronizeSession、出力前停止/全終端後復帰、退場/新記事時の復帰Task取消、番号別再試行の入口を一元化。ArticleView/PreviewViewと共有LocalImageAccessが消費 | 中 |
| Hitotsuzuri/ArticleView.swift | 再試行をCoordinator経由にし、マウス/キーボード同条件。出力処理終了待ち等の実状態と操作可否を表示 | 中 |
| Hitotsuzuri/ArticlePreviewView.swift | 必要な場合のみ、表示資源停止中の明示状態を編集画面と揃える | 低 |
| Hitotsuzuri/DebugFixture.swift | 合成画像の一部失敗→利用可能への切替、保存先取消・容量/保存/入力失敗・遅い応答等の決定的注入。通常データへfallbackしない | 試験専用 |
| HitotsuzuriUITests/ArticlePhotoRestorationUITests.swift（新規） | 実Coordinator/Viewを通る表示復帰・実画像要素・要求回数の回帰 | 試験 |
| HitotsuzuriUITests/FixtureLaunch.swift | 新fixture設定の起動/再起動保持や所有cleanupに必要な場合のみ拡張 | 試験 |

Coreの保存・出力の正本処理とPhotos adapterは原則変更しない。既存のArticleImageAccess.isBusy、予算、取消/世代で実処理中を判定し、まだ処理中なら取消可能な復帰待ちを保持する。表示復帰待ちは画面に表し、出力busy終了だけで画像取得を重ねない。退場/新session時は待ちTaskを取り消し、待ちが解けた時にもsessionを再照合する。画像部品の契約変更が必要と判明した場合は、その層でも失敗試験を先に用意する。

連続出力は、Coordinator側の出力中フラグを入口から後照会・表示復帰の準備まで保持して防ぐ。保存確認を取り消した場合や早期失敗でもdeferで確実に解放する。解放と同じ記事への復帰の順序を揃え、次の出力を先に受け付ける隙間を作らない。UIの無効化とCoordinator入口の拒否の両方を検証する。DEBUG専用の照会待ち注入は既存awaitと等価な位置に置き、通常のbusyや復帰動作をfixtureで代行しない。

Xcode設定、entitlements、共有scheme、保存形式、CI閾値は変更しない。runnerは新テストclassを発見する既存構成を使用する。既存の作業中scheme変更、旧intent監査、未追跡setup/docsは混ぜない。

## 実行順

- [ ] Step 1: 既存runner/設定と変更前CIを確認し、ソース同一性・既存成功を記録する。手書きApp/Coreはd3feef4から未変更、記録のみe6111da。CI42030797393のCore/native両job成功を読み取って利用する。ローカルビルド/native/UIは実行しない。（NFR3）
- [ ] Step 2: Frontend/接続層 Red。新しい10シナリオと必要なDEBUG注入を追加し、通常の復帰ロジックを変えず既存PRへpushする。CIで出力後4枚表示/要求発行に関する意図した失敗を観測する。compile/設定/fixture失敗をRed根拠にしない。新sessionと正常再試行は対照とする。（FR1–FR3、NFR1–NFR3）
- [ ] Step 3: Green。Coordinatorで資源停止と再開を対にし、全出力終端、同一sessionでowner欠落、番号別再試行を修正する。Viewのnil直接returnを取り除き、開始できない状態を明示する。旧応答/旧復帰Taskを排除し、実出力終了まで表示取得を待つ。（FR1–FR3、NFR1–NFR2）
- [ ] Step 4: 修正をpushし、既存CIのCore→起動smoke→全機能/全製品coverageを通す。必要な失敗修正を行い、同じ目的のローカル再実行はしない。各ケースが実画像要素/要求発行を検証していることをログと試験実装で確認する。（全要件）
- [ ] Step 5: Refactor。greenの根拠を保ちながら停止/復帰/再試行の共通責務を整える。新しい意味変更を加えた場合に限り該当CIを再検証する。不要な抽象化や全面整形はしない。（NFR1–NFR3）
- [x] Step 6: 連続出力 Red。出力後の記録確認を決定的に保留するDEBUG注入とT11を追加し、通常のbusy制御を変えずCIで再要求が受理される意図した失敗を確認する。未観測の競合を再現済みと扱わず、実Coordinatorの受理回数と表示要求を根拠にする。（FR2、NFR2–NFR3）
- [ ] Step 7: 連続出力 Green。Coordinatorの出力所有期間を後照会まで維持し、deferで確実に解放してから同じ記事の表示を復帰する。保存確認取消・失敗等の既存終端を維持し、T11と既存10件を対象限定CIで確認する。（FR2、NFR1–NFR2）
- [ ] Step 8: 通常全機能CIで新11件と既存機能、全製品80%以上を再検証する。Greenを保ちながら最少の責務整理を確認し、一時診断workflowを片付ける。同じ目的のローカル試験は実行しない。（全要件）
- [ ] Step 9: code-summary、要件traceability、Red/Green CIのSHA/結果を記録し、独立レビューとBuild and Testへ渡す。本人の実機確認手順をまとめ、実機解消は未確認と区別する。各フェーズの記録をcommitし既存PRへ反映、Draft/未マージを維持する。（NFR3）

model/DB、repository、外部API層の変更は今回不要で、該当しない層のTDDや架空のUnitを追加しない。

## 回帰シナリオと要件対応

| 番号 | 新UIシナリオ | 要件 |
| --- | --- | --- |
| T1 | 保存→終了/再起動→下書き再開で4枚の実画像、本文/順序一致 | FR1、NFR1 |
| T2 | 正常4枚出力後の4枚復帰・編集/プレビューでの表示 | FR2、NFR1 |
| T3 | 出力画像取得失敗後も表示4枚と本文が戻る | FR2、NFR1 |
| T4 | 遅い出力の取消後に復帰。処理中は表示取得しない | FR2、NFR2 |
| T5 | 保存先選択取消後に4枚復帰 | FR2 |
| T6 | 表示解放後の容量拒否でも表示再開 | FR2、NFR2 |
| T7 | 保存失敗による出力中止でも表示再開、本文保持 | FR2、NFR1 |
| T8 | 入力検証失敗による出力中止でも表示再開、入力保持 | FR2、NFR1 |
| T9 | 一部表示失敗→利用可能へ切替→番号別再試行で実要求と画像表示。マウスとキーボードの経路を確認 | FR1、FR3 |
| T10 | 復帰待ち/遅い応答中に退場・別sessionへ移行。旧画像/要求が新記事へ混入せず不要保持を解放 | FR2、NFR2 |
| T11 | 最初の出力後照会を保留して再要求。実入口でも次の出力を受理せず表示要求は増えない。照会解除・表示復帰後には次の出力が受理され、その終了後も4枚が戻る | FR2、NFR2 |

既存ArticleImageTests/ArticlePreviewRetryTests/ArticleResourceTestsで部品の成功、15秒期限、世代/遅い応答、取消、番号別直列化、資源予算を併せて検証する。既存部品テストをCoordinator接続の代用にしない。新UI11シナリオはfixture都合で最少の独立テストへ構成してよいが、全シナリオの根拠と対応を残す。新回帰と既存全スイートの成功、全体80%がNFR3の合格条件。

## 検証・データ・戻し方

対象コマンドと前提はunit-test-instructions.md。TDDのRed/Greenは承認後にCIで観測し、まだ成功と記録しない。実写真、一般pasteboard、OS設定は自動操作しない。所有UUID fixtureをapp内でcleanupし、未知のデータは削除しない。

本人確認は最後に一度にまとめる。問題が残れば失敗操作/状態を聞き、文章と写真データを保持して再調査する。変更前基準はd3feef4（e6111daは記録のみ）。比較が必要なら別作業領域を使用し、現在の作業中変更をreset/clean/restoreで上書きしない。

## Testing Contract

```json
{
  "version": 1,
  "methodology": "tdd",
  "source": "team",
  "ordering": "各テスト可能な層で、先にテストを書いて意図した失敗を確認し、最小限の実装で成功させ、成功を保ちながら整理するred-green-refactorの順序で進める。",
  "scope": "bugfix",
  "test_strategy": "minimal",
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
    "strategy": "minimal",
    "strategy_volume": [
      "One verifiable test per requirement at the narrowest effective level.",
      "At least one happy-path unit test per component.",
      "Unit tests are the default; a bugfix/security scope floor may require an integration or E2E regression when that is the narrowest level that reproduces the defect."
    ],
    "scope_floor": [
      "Include a targeted regression for the bug or vulnerability.",
      "Keep the existing test suite green."
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
  "input_sha256": "sha256:b4ce7be039ab8b1fffd4ae982567ed3d9a633a5c95ae384e4078b24716f83d29",
  "contract_sha256": "sha256:02e880216f822f2f68029581ce26cea7250bd911a18675cdc550b27d9b586232"
}
```
