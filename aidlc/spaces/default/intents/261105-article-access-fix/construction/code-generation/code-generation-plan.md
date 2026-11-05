# 記事アクセスエラーの実装計画

## Summary

- Builds: 許可済み保存先で記事の新規作成・保存・再開を回復し、既存データとsymlink防御を維持する。
- Touches: ArticleFileSystem.swift、ArticlePersistence.swift（必要時の失敗分類）、DEBUG fixtureと試験起動補助、Core回帰試験1ファイル・Sandbox UI回帰試験1ファイル。
- Tests: 新規Core結合6件＋Sandbox UI1件、既存機能CI全件と全製品coverage80%以上。Red/GreenはCIで記録し、ローカルUIを反復しない。

## Inputs and Scope

承認済みの `inception/requirements-analysis/requirements.md` のFR1〜FR3、NFR1〜NFR3を実装する。調査入力は `aidlc/spaces/default/codekb/hitotsuzuri/{architecture,code-structure,code-quality-assessment}.md`。User Stories・Units Generation・個別設計はSKIPであり、架空のUnit/Storyを作らない。単一の修正として要件IDを各Stepへ対応付ける。

原因候補は `ArticleDirectory.open` が `/` から全祖先を読取openし、create時に既存祖先にもmkdiratする点。本人の失敗syscallは未観測。Redは実際の権限制約に対する期待動作の失敗で確認し、コンパイル失敗・fixture作成失敗を証拠にしない。想定した失敗が出なければ、原因候補を再検証してから製品変更へ進む。

## Change Preview and Impact

| 対象 | 変更内容 | 依存・リスク |
|---|---|---|
| `HitotsuzuriCore/ArticleFileSystem.swift` | 全祖先の読取openを、対象パスを直接開く処理へ変更。Darwinの`O_NOFOLLOW_ANY`でパス全成分のsymlinkを拒否。既存対象を先にopenし、ENOENTかつcreate指定時だけ親を再帰的に確保し、開いた親fd相対で欠けた子を作成する。childもopen→ENOENT時のみmkdirat→nofollow再openとする | 記事、1枚/4枚出力、回復journal、Finder前検査が共有。影響は横断的だが、read/write/lock/rename/所有照合の契約を変更しない |
| `HitotsuzuriCore/ArticlePersistence.swift` | 必要な場合のみ、一覧のFoundation列挙で実際の権限拒否をpermissionDeniedへ分類。破損/未知版/不在との区別を維持 | 一覧失敗を空一覧へ変換しない。修正が不要なら変更しないと記録 |
| `HitotsuzuriU1Tests/ArticleDirectoryAccessTests.swift`（新規） | 合成領域での検索のみ可能な祖先、対象権限拒否・回復、中間/末端symlink拒否の6結合試験 | XCTestの実際のPOSIX権限とディスクI/Oで再現。root実行・権限設定失敗を成功扱いしない |
| `Hitotsuzuri/DebugFixture.swift` | DEBUG限定の保存場所選択を追加。通常と同じApplication Support解決APIから、専用接頭辞＋検証済みUUIDの隔離rootを使用。写真は既存合成adapterのまま。掃除はそのrootだけをapp自身が行う | 通常選択・記事・写真へ触れない。fixture専用環境変数は自由な絶対パスを受け取らない |
| `HitotsuzuriUITests/FixtureLaunch.swift` | 隔離保存場所の指定を起動・再起動・teardownへ一貫して保持 | UUID所有確認とapp内cleanupを保持。既存temporary方式の試験を維持 |
| `HitotsuzuriUITests/ArticleSandboxStorageUITests.swift`（新規） | Application Supportの隔離rootで記事開始→本文変更→保存→再起動→再開を1件で検証。最後にapp内cleanup成功を確認 | App Sandbox・現行entitlementsのままCIで実行。製品の通常保存先と同じ解決経路を使い、fixture一時rootだけの保証にしない |

現行Xcode projectはfilesystem synchronized groups、runnerはクラス自動検出のため新しい試験ファイルをそのまま認識する。project、scheme、entitlements、CI workflowの変更は予定しない。既存scheme差分は本人のものとして保持する。

## Implementation Steps

- [x] **Step 1 — 実行準備・baseline（全要件）**: 未変更製品と既存runnerを確認する。PR CI `42016213433`（対象8229a1d）は全機能517件・smoke2件成功、製品coverage5227/5739=91.08%。現HEAD8727406は記録のみで製品は同一。ソース差分なしを確認してbaselineに採用し、同じbaselineをローカルUIで取り直さない。既存Python選択契約試験を1回実行し、新クラスを拾う設定を静的確認する。
- [ ] **Step 2 — データアクセス Red（FR1、FR2、NFR1）**: Core結合試験6件とfixture準備・復元を追加する。検索のみ祖先の下に既に許可された末端を用意し、一覧・作成・保存・再開の期待を確認。実データに触れない。製品helperは未変更のまま、試験だけのコミットを既存ドラフトPRのブランチへpushし、CIのCoreで意図した権限エラーを観測する。コンパイルやfixture由来の失敗なら修正して正しいRedを得る。
- [ ] **Step 3 — データアクセス Green（FR1、FR2、NFR1）**: Step 2の意図した失敗を確認後、対象パスの直接openと、欠けたディレクトリだけの作成を実装する。`O_NOFOLLOW_ANY`（現行SDKのsys/fcntl.hに定義あり）を用い、中間/末端symlinkの拒否を維持する。ENOENTだけを作成経路へ送り、EACCES/EPERM・ELOOP等を握り潰さない。必要ならArticlePersistence.listの権限分類を最小限修正する。
- [ ] **Step 4 — Sandbox経路の回帰を追加（FR1、NFR3）**: DEBUG fixtureのApplication Support隔離モードと1件のUI試験を追加する。既存の記事入口・手動保存・再開UIを操作し、本文と同じ記事を再開できることを確認。frontendの業務ロジック変更はないため新しいUI機能のTDD層は追加しない。データアクセスRedの保護対象を実アプリ経路で確認する試験である。
- [ ] **Step 5 — CI GreenとRefactor（FR1〜FR3、NFR1〜NFR3）**: 修正＋Sandbox回帰をpushし、既存CIでCore→smoke→全機能・全製品coverageを1回通す。Red/GreenのSHA、run/job、実行件数、0skip、coverageを記録する。同じSHAでpush/PRの2実行が生じたら重複push runだけをcancelし、PR runを残す。成功後、必要な読みやすさの整理だけを行い、整理でソースを変えた場合のみ再検証する。無関係なリファクタはしない。
- [ ] **Step 6 — 共通利用者・安全性確認（FR3、NFR1、NFR2）**: 保存・1枚検証・4枚出力・両journal・Finder前検査と、既存のsymlink/差替え/排他/競合/結果不明/取消/他者ファイル保護試験の実行をCI結果で対応付ける。設定差分でSandbox・entitlements・coverage対象/閾値が維持されていることを確認する。FR3の回帰を全機能CIに含め、同じ目的の個別ローカル実行を増やさない。
- [ ] **Step 7 — 結果・手順・追跡記録（全要件）**: code-summary.md、traceability.json、試験結果/Red-Green記録を作成し、変更ファイルと各要件の対応を確定する。本人が確認する「写真選択→記事→本文保存→再開」を1セットの日本語手順にまとめ、自動試験と本人確認済み/未確認を分ける。Core fixtureは権限を必ず復元しUUID領域だけを掃除、UI fixtureはapp内で掃除し、今回のscratchが残っていないことを確認する。
- [ ] **Step 8 — 独立点検・完了確認（全要件）**: 完成した差分と記録を独立点検に渡し、その結果を本人が判断できる形で提示する。既存データとPhase2の既知の未確認事項を保護したままBuild and Testへ引き渡す。

## Test Coverage and Requirement Mapping

| 要件 | 検証 |
|---|---|
| FR1 | 新規Core2件（既存記事open/save/reopen、欠けた下位pathでcreate/list）＋新規Sandbox UI1件 |
| FR2 | 新規Core2件（対象の読取拒否を失敗として返す、書込拒否後の復元・同操作再試行と既存bytes保持） |
| FR3 | 既存ArticleProbeTests・ArticleExportWriterTests/JournalTests/IntegrationTests/OSActionTestsほか全機能CI |
| NFR1 | 新規Core2件（中間・末端symlink拒否）＋既存差替え/所有/排他等の保護試験、設定差分 |
| NFR2 | RedとGreenのCI証拠、runner選択契約、全機能CIと全製品80%以上 |
| NFR3 | Sandbox UIの隔離root/cleanup確認、合成adapterと差分の監査、本人確認の1セット手順 |

既存の振る舞いとデータモデルは維持するため、データモデル/database、独立した業務ロジック、API/endpoint層の追加はN/A。変更するテスト可能な層はrepository/data accessであり、Red→Green→Refactorをその順序で実施する。

## Verification and Execution Policy

- 自動試験は既存GitHub Actions `Verify native application`（xcode-27、contents:read、固定checkout、credential保存なし）を使用する。新サービス・課金構成は追加しない。runnerの現在の課金状態は変更しない。
- 正確な部分実行コマンド・fixture条件は `unit-test-instructions.md`。全製品coverageは部分実行の率では判定せず、Build and Testが既存CIの全機能主bundleで判断する。
- 既存CIは `bash scripts/verify-native.sh --core` の成功後、`bash scripts/verify-native.sh --functional` を実行する。主bundleにもCoreを含める既存検証契約は維持する。
- ローカルのbuild・native/UI・性能試験は本計画の通常経路に含めない。CIで再現不能など必要性が明確になった場合のみ、理由と限定した操作を本人へ示す。
- Redの失敗は期待した回帰の再現として記録し、ドラフトPRを統合可能としない。Greenの全既存機能とcoverageを満たしてから統合判断する。
- 操作記録を含めたコミット/pushは現在の `codex/phase2-u2-draft-experience` とドラフトPR #2で続ける。pushの本人承認済み方針を使用し、レビュー依頼・merge・公開リリースは追加で実行しない。

## Alternatives and Rollback

- 採用: 保存先パスを直接nofollow-anyでopenし、ENOENT時だけ不足部分を親fd相対で作成。許可済み保存先の祖先読取を不要にし、カーネルによる全成分symlink拒否と以後のfd相対操作を両立する。
- 不採用: 全祖先を検索専用fdでたどる方式。祖先ごとのSandbox認可が残り、今回の入口を単純化できない。
- 不採用: FileManagerの通常open/createだけへ置換、Sandbox解除・権限拡張。symlink差替え防御または権限境界を弱めるため。
- 戻す場合は今回の製品変更コミットだけをrevertする手順を記録する。保存形式変更なし。未保存の本人変更をreset/checkout/cleanで消さない。実行時は必要な保存を済ませてappを終了し、本人確認を受けたうえで戻す。通常データは削除しない。


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

