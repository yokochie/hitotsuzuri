# U1 実装計画

## Summary

- Builds: 実写真ライブラリから複数フォルダ探索・1アルバム閲覧・順序付き4枚選択・検証後の保存まで動く最初のmacOSアプリ。
- Touches: Hitotsuzuri.xcodeproj、Hitotsuzuri/、HitotsuzuriCore/、HitotsuzuriU1Tests/、scripts/、この単位の実装・検証記録。
- Tests: 5責務に各5〜8件の単体テストと境界の統合テスト、合計35〜45件を計画。TDDと統合前ローカルビルド・自動テスト・行カバレッジ80%以上。

## 入力・本人による変更

[機能仕様](../functional-design/functional-spec.md)、[ルール](../functional-design/rules.md)、[モデル](../functional-design/entities.md)、[内部契約](../../../inception/contract-design/contract-summary.md)、[性能設計](../nfr-design/performance-design.md)、[保護設計](../nfr-design/security-design.md)、[実行環境](../infrastructure-design/infrastructure-specification.md)、[実装単位](../../../inception/units-generation/unit-of-work.md)、[要件](../../../inception/requirements-analysis/requirements.md)を実装へ対応づける。

[本人承認のCI省略](../../../change-decisions/2026-10-31-local-verification.md)を適用する。下の自動生成されたTesting Contractには旧共有規約由来のCI文言が残るが、今回のCI工程は省略済みであり、本人の明示指示に従って統合前ローカル検証へ置き換える。TDDの順序・Standardのテスト範囲・80%の条件は変更しない。ブロック自体は生成結果を改変せず保持する。

## 構成と変更範囲

- アプリ: Hitotsuzuri/HitotsuzuriApp.swift、PickerView.swift、Info.plist、Hitotsuzuri.entitlements。表示名ひとつづり、bundle IDはcom.yokochie.Hitotsuzuriに固定する。SwiftUI、Sandbox、写真の利用目的、ローカルad-hoc署名。
- テスト可能な製品層: HitotsuzuriCore/Models.swift、Ports.swift、SelectionWorkflow.swift、PhotoLibraryAccess.swift、LocalImageAccess.swift、SelectionPersistence.swift、PresentationSnapshot.swift、Diagnostics.swift。ドメインと境界は5所有者を保ち、画像・認可・ファイルをFakeに置換できるようにする。
- Xcodeプロジェクト: アプリ、Coreフレームワーク、ホスト不要のHitotsuzuriU1Testsターゲット、共有Hitotsuzuri scheme。macOS27.0、Swift6、既存Xcodeで動作する形式。外部生成ツールやパッケージのインストールは不要。
- テスト: HitotsuzuriU1Tests/U1ModelTests.swift、U1LibraryTests.swift、U1ImageTests.swift、U1PersistenceTests.swift、U1WorkflowTests.swift、U1PresentationTests.swift、U1IntegrationTests.swift、TestDoubles.swift。
- 検証補助: scripts/verify-u1.shとscripts/check-coverage.swift。実行対象をU1に固定し、ビルド/テスト/カバレッジ失敗を非ゼロで返す。結果は.build内へ保存し、元画像・個人の保存JSON・IDを記録へ取り込まない。
- 既存のREADME.md、AGENTS.md、docs/ひとつづり_Phase1_設計.md、AI-DLCの実装・設定を変更しない。.gitignoreは.build/とXcodeの個人用ファイルの除外に必要な追記だけを行い、既存ルールを削除しない。

## 実行手順と追跡

- [x] Step 1: 短いcodex/u1-integrated-selectionブランチを用意する。Xcodeプロジェクト・最小の製品ターゲット・共有scheme・U1テストターゲットを作り、テストランナーを先に動かす。テストが発見・実行されることを確認してからRedへ進む。名称と構成の基礎: US1.1、US1.8。
- [x] Step 2: モデル層Red。U1ModelTests.swiftに0〜5枚・重複・選択順・不透明ID・保存版/日時の検証を先に書き、上記単位用コマンドで意図した失敗を記録する。US1.4、US1.6。
- [x] Step 3: モデル層Green。Models.swiftとPorts.swiftに最小の値型・結果型・境界を実装する。C3はimage/unavailable/cancelled/failureを明示し、上流の画像結果表現の不足を実装へ持ち込まない。US1.3、US1.4、US1.6。
- [x] Step 4: モデル層Refactor。成功を維持して不変条件と失敗分類を整理し、テストを再実行する。
- [x] Step 5: データアクセス層Red。U1LibraryTests/U1ImageTests/U1PersistenceTestsに許可前取得禁止、複数/深い階層・循環・重複、順序保持、取消・古い応答・期限、JSON往復・書込失敗・未知版保護の失敗テストを書く。実際の個人ライブラリは使わない。US1.1〜US1.3、US1.6、US1.8。
- [x] Step 6: データアクセス層Green。PhotoLibraryAccess/LocalImageAccess/SelectionPersistenceを実装する。通信false、画像最大8件・通常4/検証4、512pixel基準の管理バッファ、予約を含む256 MiB、単調時計の15秒、固定JSON名と直列atomic保存を実装する。
- [x] Step 7: データアクセス層Refactor。PhotoKitコールバック・取消の二重終端とSwift6の隔離を整理する。unchecked Sendableで根拠なく警告を隠さない。成功テストを維持。
- [x] Step 8: 進行層Red。U1WorkflowTestsに4枚制限・解除番号・アルバム/フォルダ切替・確定内容固定・現参照検証・保存失敗保持・重複確定拒否の失敗テストを書く。US1.4〜US1.6、US1.8。
- [x] Step 9: 進行層Green。SelectionWorkflowをMainActorで実装し、UIへ一貫した読取り状態を公開する。別の所有者へ選択ルールを複製しない。
- [x] Step 10: 進行層Refactor。世代・操作ID・編集revisionを分離し、遅延結果で別の選択を上書きしない。成功を維持。
- [x] Step 11: 表示層Red。U1PresentationTestsに権限/読込/空/失敗、4枠の順序、canConfirm、保存進行・未保存・再試行案内の失敗テストを書く。US1.1〜US1.6、US1.8。
- [x] Step 12: 表示層Green。PresentationSnapshotと薄いPickerViewを実装し、フォルダ複数選択・アルバム一覧・写真グリッド・常設4枠の画像と番号を接続する。アプリの日本語表示と操作用accessibilityIdentifierを設定する。
- [x] Step 13: 表示層Refactor。画面の派生状態・不要画像要求の寿命・エラー案内を整理して再実行する。最終レイアウト/狭幅/VoiceOver全受け入れはU3へ残す。
- [x] Step 14: 結合TDD。U1IntegrationTestsでFake認可→階層→画像→4枚→保存読戻しの一通りと、外部削除・書込失敗の失敗テストを先に書き、実装を接続して成功させ整理する。実アダプターは専用一時領域の保存とAPI設定の検証を含める。US1.1〜US1.6、US1.8。
- [x] Step 15: ビルド・署名・品質条件を確認する。統合前のローカルビルド・全テストと80%以上の行カバレッジを実行し、結果を記録。アプリ全体の計測対象を除外して通さない。未達なら対象のテストを補い、基準を下げない。
- [x] Step 16: 日本語の起動/実機確認手順と実装要約・source-manifest・ID追跡を記録する。本人の確認が必要な許可・実並び・画像・保存は未確認欄を残す。確認前に実機成立性を合格にしない。

各Red/Greenはunit-test-instructions.mdの単位用コマンドで実行し、失敗理由と対象テストを記録する。API/HTTP層・DB移行・クラウド配置は構成上非該当。テスト手順に空の統合テストだけを残さない。

## 品質と本人確認

製品Swiftソース全体（アプリとCore）を計測対象とする。Xcode自動生成コードとテストコードは分母から除くが、手書きのViewや実アダプターは一律除外しない。U1の手動確認は許可/拒否、2対象以上・3階層以上、親子重複、手動アルバム順と動画除外、ローカル画像と不可写真、4枚・解除番号・保存成功。U2の全復元経路とU3の最終性能・操作支援をU1完了へ混同しない。具体的な最終Construction Verification Commandの本人確認は、計画承認とは別に最初の単位検証前に行う。

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

