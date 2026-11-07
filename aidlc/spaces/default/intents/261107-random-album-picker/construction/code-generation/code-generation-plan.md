# アルバムのランダム選択 実装計画

## 変更範囲と動作

- `SelectionWorkflow.swift` で、表示中の候補から等確率で1件を取得する。既存の選択処理を使い、現在と同じIDなら写真状態を保持する。確定前の選択がある場合の判定には写真選択と保存済み状態の差を使う。
- `PickerContent.swift` のアルバム欄に「ランダムに選ぶ」ボタンを置く。抽選できない場合は無効にする。別のアルバムへ切り替える前に必要なら確認し、取消時は状態を保持する。確認中に候補や選択状態が変わった場合は古い結果を適用しない。狭幅では一覧に残り、当選した行が見えるようにする。
- 影響はアルバム選択画面とワークフローに限る。手動選択、写真ライブラリの読み取り、保存形式、記事画面、CI設定を既存の経路で維持する。

## 実施手順

- [ ] Step 1. 既存のXCTest設定と対象コマンドを確認し、変更前のCoreおよびUIのベースラインを取る。
- [x] Step 2. Core Red。U1WorkflowTestsに候補の境界、同じID、未確定選択と既存の読み取り経路を検証するテストを先に加え、意図した失敗を記録する。US1.1、US1.2。
- [x] Step 3. Core Green。候補の抽選と切り替えの判定を最小限の変更で実装し、対象テストを通す。US1.1、US1.2。
- [x] Step 4. Core Refactor。既存処理との重複を整理して再実行する。US1.1、US1.2。
- [ ] Step 5. UI Red。NativeInputTestsにボタン操作、確認の取消と承諾、狭幅で一覧に残るケースを追加し、意図した失敗を記録する。必要な場合はDEBUGの合成データで当選条件を固定する。US1.1〜US1.3。
- [ ] Step 6. UI Green。ボタンと確認を既存UIにつなぎ、選択状態と写真領域を更新する。テスト用識別子を設定し、対象テストを通す。US1.1〜US1.3。
- [ ] Step 7. UI Refactor。既存の手動選択やフォーカス挙動を確認し、対象テストを再実行する。US1.1〜US1.3。
- [x] Step 8. 実装と試験の対応、結果、実機確認の手順を記録する。全体の80%行カバレッジと統合前CIはBuild and Test以降で確認する。NFR2。

## Testing Contract

```json
{
  "version": 1,
  "methodology": "tdd",
  "source": "team",
  "ordering": "各テスト可能な層で、変更を表すテストの意図した失敗を先に確認し、最小の変更で成功させ、成功を維持しながら整理する。",
  "scope": "express",
  "test_strategy": "minimal",
  "project_type": "brownfield",
  "applicable_notes": [
    {
      "layer": "org",
      "text": "We treat tests as a first-class deliverable in every Bolt. The specific\nmethodology (TDD, BDD, ATDD, or classic test-after) is affirmed at\npractices-discovery and recorded in `team.md` under this heading with explicit\n`Methodology` and `Ordering` fields; Code Generation resolves those fields\nindependently from coverage, tooling, and scope notes.\n\nWhen no posture has been affirmed, our default per scope is:\n- **Methodology**: test-after\n- **Ordering**: implement each applicable testable layer, then write and run\n  that layer's tests.\n- `mvp`, `enterprise`, `feature`, `infra`, `classic` add an 80% line-coverage\n  floor and CI execution before merge.\n- `bugfix`, `security-patch` add a targeted regression for the specific\n  bug/vulnerability and require the existing suite to remain green.\n- `express` uses the Minimal strategy: requirement-driven unit tests (one per\n  requirement, with a happy-path floor per component); existing tests remain\n  green.\n- `poc`, `refactor`, `workshop` add no extra new-test floor and require the\n  existing suite to remain green.\n\nThe active `Test Strategy` still applies in every scope and determines test\nvolume/types. Scope floors are additive; they never reduce or replace the\nselected strategy.\n\nBuild and Test verifies defined coverage floors and affirmed quality targets;\nthey may not be weakened to make a step pass.\n\nAffirm a stricter posture in `team.md` if the team commits to one."
    },
    {
      "layer": "team",
      "text": "- **Methodology**: tdd\n- **Methodology evidence**: 既存の`aidlc/spaces/default/memory/team.md`で本人確認済み。CI高速化の依頼を試験削減の許可とは解釈しない。\n- **Ordering**: 各テスト可能な層で、変更を表すテストの意図した失敗を先に確認し、最小の変更で成功させ、成功を維持しながら整理する。\n- 製品全体の80%以上の行カバレッジと統合前CIを維持する。Core、必須smoke、機能UI、試験実行の実在確認を維持し、性能測定は本人Macの別区分で扱う。\n- 現在はGitHub Actionsの`xcode-27` runnerを使用している。旧記録の「CI未用意」は過去の状態であり、現状の説明には使用しない。\n- ローカル試験とGitHub Actionsでの成功を区別する。実行時間・待機時間・環境・対象commitを記録して比較する。\n- 実写真やSandbox等の本人Macでの確認を自動試験の成功で代替しない。VoiceOverの追加設計・検証は要求しない。"
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
      "Keep the existing test suite green.",
      "This scope adds no extra new-test floor beyond the selected test strategy."
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
  "input_sha256": "sha256:5043fbaedf810b87f0c23a768d46db7a0b60f85e2adffbc5daae0270d37d2157",
  "contract_sha256": "sha256:d6a4fb20a50408e25e8dc05b65a7a53b3e4ef2851c013defbe53ebb45876cc07"
}
```
