# U2 実装計画

## Summary

- Builds: 前回の4枚の一括復元、破損確定データの退避、保存の再試行。
- Touches: HitotsuzuriCore、PickerView、Xcodeのテスト構成、HitotsuzuriU2Tests、検証手順。
- Tests: 5構成要素で各5〜8件、境界の結合テストを含む約35件。U1の60件も回帰確認。

## 対象と根拠

[機能仕様](../functional-design/functional-spec.md)、[ルール](../functional-design/rules.md)、[NFR設計](../nfr-design/reliability-design.md)、[実行環境](../infrastructure-design/infrastructure-specification.md)、共有の[契約](../../../inception/contract-design/contract-summary.md)に従う。US1.1、US1.3、US1.5〜US1.8のU2寄与を実装する。
U1の動作を基礎とし、U3の最終アクセシビリティ・性能測定は別単位で検証する。

## 実装順序

- [x] Step 1: 現状の差分とU1の正常動作を確認し、既存変更を保持する。既存のApp/Core構成を利用し、外部依存は追加しない。（全ストーリー）
- [x] Step 2: Xcodeプロジェクトと共有schemeへhostlessのHitotsuzuriU2Testsターゲットを追加。U2専用コマンドが実行可能なことを最初のRedより先に確認する。テストデータとFakeをU2内へ配置。（全ストーリー）
- [x] Step 3: モデル層Red。復元状態・設定保存と確定保存の独立状態、保存順と日時、候補の不正値をU2ModelTestsで検証し、意図した失敗を記録。（US1.5〜1.8）
- [x] Step 4: モデル層Green。Ports/Modelsへ必要最小限の状態型を追加。保存形式schemaVersion 1と既存IDの不透明性を維持。（US1.5〜1.8）
- [x] Step 5: モデル層Refactor。重複した検証を整理し成功を再確認。（US1.5〜1.8）
- [x] Step 6: 保存層Red。U2PersistenceTestsで破損の同一bytes退避、既存退避再利用、未知版拒否、退避失敗、原本変更、symlink・過大ファイル拒否を検証。（US1.6、1.8）
- [x] Step 7: 保存層Green。SelectionPersistenceへ明示確定時だけの回復経路を実装。専用quarantine内のSHA256固定名、排他作成、読戻し一致確認、置換前の原本再確認、atomic保存を実施。設定破損は自動置換しない。1MiB上限を維持。（US1.6、1.8）
- [x] Step 8: 保存層Refactor。失敗を注入できるファイル操作境界を必要な範囲だけ整理し、原本保護を再確認。（US1.6、1.8）
- [x] Step 9: 業務層Red。U2RestoreTestsとU2RecoveryTestsで認可優先、正常全件復元、1枚欠損・対象外・画像失敗時の全クリア、有効フォルダ保持、古い応答、編集凍結、保存失敗と再試行を検証。（US1.1、1.3、1.5〜1.8）
- [x] Step 10: 業務層Green。SelectionWorkflowで候補を非公開に検証後、4枚・アルバム・画像・確定日時を一括公開。復元と保存の操作ID/世代を管理し、多重起動・重複保存・古い応答を拒否。再試行も現在認可・参照・画像を再検証する。最後の確定と編集を分離。（US1.1、1.3、1.5〜1.8）
- [x] Step 11: 業務層Refactor。共通の画像検証を整理。全4枚15秒の絶対期限、取消、256MiB生存画像と予約の合算、最大8要求を維持。失敗候補の保持を解放し、復元画像は共有参照で公開。（US1.5〜1.8）
- [x] Step 12: 表示層Red。U2PresentationTestsで復元中、未保存、保存済み、設定失敗と確定失敗、破損・未知版の原因と次の操作を検証。（US1.5〜1.8）
- [x] Step 13: 表示層Green。PresentationSnapshotとPickerViewへ状態案内と明示再試行を反映。検証・保存・復元中の編集を禁止し、操作を後から再生しない。追加の確定前ダイアログは作らない。（US1.5〜1.8）
- [x] Step 14: 表示層Refactor。状態文言を整理。通常診断は最小限の失敗分類だけとし、正常復元状態・写真ID・名称・画像・原本bytesを記録しない。（US1.8）
- [x] Step 15: U2IntegrationTestsで保存→新しいWorkflow→復元、未保存編集非復元、失敗→明示再試行、破損退避→新規確定を結合検証。境界ごとにRed→Green→Refactorを記録し、不足する振る舞いだけ修正。（US1.5〜1.8）
- [x] Step 16: U1全件とU2全件をローカル実行し、全製品Swiftソースの加重行カバレッジ80%以上を既存check-coverage.swiftで確認。必要なら新たな振る舞いテストで補う。verify-phase1.shを追加し、verify-u1.shの承認済み意味は変更しない。（全ストーリー）
- [x] Step 17: code-summary、traceability、source-manifest、TDD実行結果、本人向け再起動・削除・権限・破損時手動復旧手順を日本語で作成。自動結果と本人未確認を区別し、完成コードの独立レビューへ渡す。（全ストーリー）

## 変更範囲と責任

既存HitotsuzuriCoreのPorts.swift、Models.swift、SelectionPersistence.swift、SelectionWorkflow.swift、PresentationSnapshot.swiftを中心に変更する。LocalImageAccess.swiftは共通期限・保持の接続に必要な場合のみ変更し既存上限を守る。Hitotsuzuri/PickerView.swiftと必要な起動配線、Hitotsuzuri.xcodeproj/project.pbxprojと共有schemeを更新する。新規テストはHitotsuzuriU2Tests内、最終ローカル検証はscripts/verify-phase1.sh。既存U1テストは互換変更に伴うFake更新だけ許容し、保証を削除しない。README、入力設計書、AI-DLC設定には変更を加えない。

API/endpoint、サーバー、DBマイグレーション、外部配置は対象外。永続JSONのschemaVersionは維持し、破損退避だけを追加する。Foundation/CryptoKitとXCTestを利用する。

## 品質と完了条件

各構成要素5〜8件を基準とし、追加の保護条件は件数より優先する。U1の既存60件、U2単体と主要境界が成功し、全製品コードの行カバレッジ80%以上。テスト専用コードは分母から除外するが、App/CoreのUI・Photosアダプタは除外しない。
[CI省略の承認](../../../change-decisions/2026-10-31-local-verification.md)が本作業へ適用される。以下の契約に残るCI記述に対して、この本人の変更決定を適用し、統合前のローカル検証を維持する。
新しい最終検証コマンドは実装後に本人へ提示し、承認前に最終検証の指定を置換しない。実ライブラリでの終了再起動、外部写真削除、権限変更は本人確認として記録する。

## Testing Contract

```json
{
  "version": 1,
  "methodology": "tdd",
  "source": "team",
  "ordering": "各テスト可能な層で、先にテストを書いて意図した失敗を確認し、最小限の実装で成功させ、成功を保ちながら整理するred-green-refactorの順序で進める。",
  "scope": "mvp",
  "test_strategy": "standard",
  "project_type": "greenfield",
  "applicable_notes": [
    {
      "layer": "org",
      "text": "We treat tests as a first-class deliverable in every Bolt. The specific\nmethodology (TDD, BDD, ATDD, or classic test-after) is affirmed at\npractices-discovery and recorded in `team.md` under this heading with explicit\n`Methodology` and `Ordering` fields; Code Generation resolves those fields\nindependently from coverage, tooling, and scope notes.\n\nWhen no posture has been affirmed, our default per scope is:\n- **Methodology**: test-after\n- **Ordering**: implement each applicable testable layer, then write and run\n  that layer's tests.\n- `mvp`, `enterprise`, `feature`, `infra`, `classic` add an 80% line-coverage\n  floor and CI execution before merge.\n- `bugfix`, `security-patch` add a targeted regression for the specific\n  bug/vulnerability and require the existing suite to remain green.\n- `express` uses the Minimal strategy: requirement-driven unit tests (one per\n  requirement, with a happy-path floor per component); existing tests remain\n  green.\n- `poc`, `refactor`, `workshop` add no extra new-test floor and require the\n  existing suite to remain green.\n\nThe active `Test Strategy` still applies in every scope and determines test\nvolume/types. Scope floors are additive; they never reduce or replace the\nselected strategy.\n\nBuild and Test verifies defined coverage floors and affirmed quality targets;\nthey may not be weakened to make a step pass.\n\nAffirm a stricter posture in `team.md` if the team commits to one."
    },
    {
      "layer": "team",
      "text": "- **Methodology**: tdd\n- **Methodology evidence**: 確認回答Q3で、テストを先に書き、失敗を確認してから実装する方式を本人が選択し、要約も確認した。既存コードの慣行からの推定ではない。\n- **Ordering**: 各テスト可能な層で、先にテストを書いて意図した失敗を確認し、最小限の実装で成功させ、成功を保ちながら整理するred-green-refactorの順序で進める。\n- `mvp`に適用される既定の80%以上の行カバレッジと統合前のCI実行を維持する。計測対象・除外の根拠・CI実行環境は要件と実装計画で具体化し、通すために基準を下げない。\n- テスト用のデータで探索・選択・保存・復元・失敗条件を自動検証し、Photosの権限・実データ・100枚以上での操作等は本人による実機確認と区別する。\n- TDDの順序とカバレッジ・CIの条件は独立した品質条件として扱う。自動化できない権限や実ライブラリの操作を、自動テストで検証済みと表示しない。"
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
    "runner_step": "Bootstrap the minimal test runner/configuration and record the exact unit-scoped command.",
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
      "Bootstrap the minimal test runner/configuration and record the exact unit-scoped command.",
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
  "input_sha256": "sha256:bd61b3953f7f40831b9fc47003d105855b637abc9a4961e5688ab9f880ad5c2a",
  "contract_sha256": "sha256:4ba63934ae5f6408d359e3811f73cf0232b97ecb35978a9430d5b1189d83d14f"
}
```

