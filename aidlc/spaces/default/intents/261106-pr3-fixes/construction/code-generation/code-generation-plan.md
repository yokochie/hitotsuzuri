## Summary

- Builds: PR #3の依存更新に対応するCI契約試験の修正
- Touches: scripts/test-native-runner.py、PR #3の既存workflow更新、作業記録
- Tests: 既存28件と固定参照検査の正常・異常回帰試験

## 目的と変更範囲

[要件](../../inception/requirements-analysis/requirements.md) FR1〜FR3、NFR1〜NFR2に対応する。旧SHAの完全一致を、正しいaction名と40桁小文字16進commit SHAであることの検査へ変更する。更新するSHA自体の正当性はPR差分とActions実行で確認する。これによりDependabotの次回更新にも対応し、branch/tagへの置換や別actionへの差替えを引き続き拒否する。

影響はCIのPython契約試験のみ。アプリ/API/保存形式の変更はない。既存の診断安全条件を検査するassertionを保持する。データモデル、DB、API、UI層の実装は対象外。

## 実装手順

- [x] Step 1 — PR headの最新状態と差分を確認し、PRブランチを別の作業ディレクトリで開く。現在の未コミット変更は移動・破棄しない。既存PRの依存更新を保持する。（FR1、FR3、NFR2）
- [x] Step 2 — 既存runnerの準備を確認し、PR headで `python3 scripts/test-native-runner.py` を実行する。既知のSHA不整合の失敗を記録する。既存のCIログを基準としてCore/UI未到達と区別する。（FR1、NFR1）
- [x] Step 3 — Red: 同じテストファイルにaction参照判定の回帰試験を先に追加する。新旧の40桁SHAで正常、tag・短いSHA・別action名・末尾余分文字で異常になることを検査し、判定未実装による意図した失敗を確認する。（FR2、NFR1）
- [x] Step 4 — Green: 小さな判定関数を実装し、旧SHA完全一致2か所を正しいaction名＋完全な40桁SHA検査へ変更する。診断branch/marker・権限・1件の対象・保存先・保持設定の既存検査は保持する。全Python契約試験を成功させる。（FR1、FR2、NFR2）
- [x] Step 5 — Refactor: 重複を整理し、同じ契約試験を再実行して成功を維持する。テスト構成は既存Python unittest/Ruby YAMLを使い、新規依存を入れない。（FR2、NFR1）
- [ ] Step 6 — 差分と要件対応をcode-summary.md、traceability.jsonへ記録する。修正コードをPR #3の既存headへコミット・pushし、後続検証で通常CIのCore/UI・製品全体80%カバレッジを確認する。実際のマージは後続の明示承認後に行う。（FR3、NFR1、NFR2）

## 検証と反映

ローカルの対象コマンドは `python3 scripts/test-native-runner.py`。Python3、Ruby、Gitを既存環境で利用する。Xcodeビルドは既存GitHub Actionsのxcode-27で行い、PRイベント、contents:read、persist-credentials:falseを維持する。CI実行先や有料サービスは追加しない。既存CI枠の消費が発生する。

差分の主要変更は2つのassertEqual(old SHA)をaction名と完全SHAの検査へ置換し、その検査の回帰を追加すること。更新版actionのSHAはPRにあるcheckout 3d3c42e5aac5ba805825da76410c181273ba90b1、upload-artifact cf430e030ddbb5b0abf93d22962f4752f3646cd9を保持する。戻す場合は修正コミットをrevertし、PR未マージならmainに影響させず再修正する。

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
