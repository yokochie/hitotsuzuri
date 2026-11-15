# 記事編集の実装計画

## Summary

- Builds: 入力欄を簡素化し、プレビューと新規出力にダミー文を表示する。
- Touches: 記事編集・プレビューのSwiftUI、本文変換と出力準備、既存記事テスト。
- Tests: 本文変換、日付、旧下書き・出力復旧のCore試験と記事編集のUI試験。

## 実装手順

- [x] Step 1. 既存のXcode設定と対象テストコマンドを確認し、変更前の試験結果を記録する（NFR1）。
- [x] Step 2. CoreのRed。旧文章・撮影メモのある下書きと空の下書きから同じダミー本文を生成する試験を先に追加する。確認済み日付、写真順、開始済み出力の照合も検証する（FR2–FR4）。
- [x] Step 3. CoreのGreen。本文変換で固定のダミー文を供給し、コピー・Markdown・プレビューで再利用できるようにする。新規出力と開始済み出力の復旧を分け、保存形式と整合性を維持する（FR2–FR4）。
- [x] Step 4. CoreのRefactor。対象試験が通る状態で変換・復旧の重複を整理する（FR2–FR4）。
- [x] Step 5. UIのRed。記事編集の対象欄が消え、タイトル、日付候補、保存とダミー文のプレビューが動くことを既存fixtureで検証する（FR1–FR3）。
- [x] Step 6. UIのGreen。記事編集から導入文・写真ごとの文章・締め・撮影メモの各欄を外し、プレビューを共通の表示用本文に切り替える（FR1–FR3）。
- [x] Step 7. UIのRefactor。対象試験を通して古い入力欄を前提にする試験を更新する（FR1–FR3）。
- [x] Step 8. XCTestの既存設定を使用し、変更の要約・要件との対応・試験結果を記録する（NFR1）。

## 影響範囲

- `ArticleView`、`ArticleMetadataFields`、`ArticlePreviewView`。記事画面内で完結する表示変更。
- `ArticleProjection` と出力準備。編集時と保存済みの変換を含む。開始済みジョブは記録された出力と照合する仕様を維持する。
- 下書きの保存用モデルと旧データの整合性を維持する。写真選択の経路は現在のまま利用する。

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
