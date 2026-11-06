# 出力画像のアプリ内取得計画

## Summary

- Builds: 出力時のiCloud画像取得、写真番号と進捗、長い待機、取消と再試行。
- Touches: Coreの出力画像取得・出力制御・状態、出力画面、DEBUG fixtureと対象回帰試験。
- Tests: 新規Core回帰約12件＋画面回帰3件をTDDで検証し、既存全機能と全製品80%条件を維持。

## 入力と範囲

承認済み `../../inception/requirements-analysis/requirements.md` のFR1–FR4/NFR1–NFR3を対象とする。CodeKBと `../../inception/reverse-engineering/developer-scan.md` に基づくZero Unitの実装。新規DB、repository、外部HTTP API、独自認証を追加しない。出力時のPhotoKit通信許可は本人指定であり、過去の通信禁止を今回の出力へ適用しない。表示/選択画像は従来の通信禁止・15秒期限のまま。

## 実装方針

PhotoKitArticleImageReaderへ取得方針と進捗sinkを渡し、requestContentEditingInputのisNetworkAccessAllowedへ実際に反映する。progressHandlerからMainActorへ通知し、request/job/写真の所有を照合する。PhotoKitのerror/cancel/input欠落を識別できる範囲で型付き失敗へ変換する。直接Photosを試験しなくてもoptionsとcallback経路を検証できる最小adapter境界を設ける。

ArticleImageAccessは出力用取得待ちと変換を区別する。出力が許可した取得待ちには独自の総経過期限を置かず、成功/PhotoKit失敗/本人取消を待つ。変換開始後は既存の30秒相当の保護を維持する。probe等の既存呼出元へ暗黙のダウンロード許可を広げず、既定は従来のローカル取得とする。要求ID確定前の取消も保持し、発行後に正しいassetとtokenへ取消を届ける。完了済みtoken保持を解放し、旧callbackや進捗を排除する。

ArticleExportDeliveryは画像取得待ちを既存40秒/全体180秒の経過へ算入しない。取得が戻った後の変換/書込/確定の期限を段階に応じて計測し、待機後のcheckで即失敗しない。単に全期限を削除する案は採用しない。待機中も取消と単一jobの所有、実処理終端までのbusy/grant/input owner、256MiB予算を維持する。

進捗はReader→ImageAccess→Delivery→OSActions→ExportSession→Viewへ接続する。写真番号と取得中を常に文字表示し、fraction未到着は不定進捗、到着後は0〜1の有効値を表示する。百分率を一式完了と扱わない。逆行/重複/範囲外/非有限値や古い写真/要求の進捗は破棄または安全に正規化する。取消受付後の進捗で取消メッセージを上書きしない。

失敗は写真番号と判別可能な理由、アプリ内の再出力案内を表示する。共通assetUnavailable文言を無条件に全経路で書き換えず、出力向け説明を用意する。固定本文・4枚順序・現在編集反映・位置情報除去・非置換公開・所有cleanup/復旧の契約は維持する。

## 影響範囲

| パス | 変更と依存 | 影響 |
|---|---|---|
| HitotsuzuriCore/ArticleImageAccess.swift | reader options、progress、待機/変換期限、取消/世代/owner。既存probe呼出元へ既定互換を維持 | 中 |
| HitotsuzuriCore/ArticleExportDelivery.swift | providerの取得方針/進捗、待機除外の段階期限、実終端とcleanupを維持 | 中 |
| HitotsuzuriCore/ArticleExportModels.swift、ArticleOutputPorts.swift、ArticleExportOSActions.swift | 必要最小の進捗/取得情報の中継。保存schemaや出力manifestは変更しない | 中 |
| HitotsuzuriCore/ArticleExportSession.swift | 番号/fractionの表示状態、旧通知拒否、出力用失敗文言 | 中 |
| Hitotsuzuri/ArticleExportView.swift | 不定/確定進捗と文字、既存取消操作の維持、実UI識別子 | 低 |
| Hitotsuzuri/DebugFixture.swift | 新しい合成cloud相当readerの保留/進捗/取消/失敗回復制御 | 試験専用 |
| HitotsuzuriU2Tests/ArticleCloudImageTests.swift（新規） | reader/取得方針・待機/変換/取消/旧通知回帰 | 試験 |
| HitotsuzuriU3Tests/ArticleCloudExportTests.swift（新規） | Delivery/Sessionの進捗・長期待機・再試行/保護回帰 | 試験 |
| HitotsuzuriUITests/ArticleCloudExportUITests.swift（新規） | 実Coordinator/出力画面で取得中/進捗/取消/再出力を検証 | 試験 |
| 既存のArticleImage/ExportSession/ExportIntegration/ExportDelivery試験と各fake provider | interface追従と変更した出力待機方針に限る期待値修正。保存/取消/変換期限の検証は削除しない | 試験 |

Xcode synchronized groupと既存runnerで新classを発見する。通常workflow、80%閾値、除外、entitlements、共有scheme、保存形式、写真変更APIは変更しない。READMEや本人の作業中設定、旧intentの変更をこの実装へ混ぜない。

## 実行順

- [ ] Step 1: runner準備と基準確認。既存CI42179866652の機能535件/smoke2/91.49%と、現在の対象ソース同一性を確認する。新classの発見規則とunit-test-instructionsのコマンドを確認し、同じローカルbuild/UIを再実行しない。（NFR3）
- [ ] Step 2: Core境界 Red。既存interfaceで再現可能なネットワーク許可・進捗未接続・旧30/40/180秒超過の回帰を先に追加しCIで意図した失敗を観測する。新しいadapter境界が必要なら、通常方針を変更しない最小の試験用注入を先に整え、compile失敗をRedに数えない。（FR1–FR4、NFR1–NFR3）
- [ ] Step 3: Core Green。readerから出力まで明示的な取得許可/進捗を接続し、待機/変換/書込の期限を分ける。要求ID確定前取消、実終端待ち、旧応答、写真ごとの通知所有を保護し、対象Core回帰を成功させる。（FR1–FR4、NFR1–NFR2）
- [ ] Step 4: Core Refactor。成功を保ちながら期限方針とprogress/取消の責務を整理する。PhotoKitの所有とUIの状態を混在させず、不要な抽象化を追加しない。（NFR2–NFR3）
- [ ] Step 5: 接続/画面 Red。合成readerの実進捗を実Coordinator/Deliveryへ流し、番号/百分率/待機、取消後の表示復帰、失敗後の新規再出力を3画面回帰で確認する。文言だけをfakeが直接書き込むfixtureを使わず、通常UI未対応の意図した失敗をCIで記録する。（FR2–FR4、NFR2–NFR3）
- [ ] Step 6: 接続/画面 GreenとRefactor。ExportSession/Viewの状態と失敗案内を実装し、旧通知・取消文言・次写真の進捗を検証する。対象3画面と既存写真復帰回帰をCIで確認して成功を保つ。（FR1–FR4、NFR1–NFR2）
- [ ] Step 7: 通常全機能CI。対象限定の一時診断workflowを使った場合は削除し、Core→smoke→全機能/全製品80%の既存CIを通す。ソースSHA/実行件数/coverageを記録し、同じ試験をローカルで繰り返さない。（全要件）
- [ ] Step 8: code-summary/7要件traceability/Red-Green証拠と本人確認手順を作成し、独立レビュー、Build and Testへ引き継ぐ。フェーズ記録をcommitし既存Draft PRへ反映する。実iCloud取得は自動試験だけで確認済みとせず、最終段階に本人確認をまとめる。（NFR3）

テスト対象のないDB/repository/HTTP API層を作らず、該当するCore業務/API境界と画面でRed→Green→Refactorを行う。実装前の計画承認後にだけ製品/試験変更を開始する。

## 試験対応

| 番号 | 狙い | 要件 |
|---|---|---|
| T1 | 実reader optionsへ出力のみnetwork許可、表示/probe既定禁止 | FR1、NFR2 |
| T2 | ローカル/未取得相当とも4枚順序と固定本文を出力 | FR1、NFR2 |
| T3 | progressなし/0/中間/1を状態へ中継、1でも一式完了前 | FR2 |
| T4 | 非有限/範囲外/逆行、前写真/前要求/前jobの通知拒否 | FR2、NFR2 |
| T5 | 仮想時計で旧30/40/180秒超過後も取得し、その後成功 | NFR1 |
| T6 | 長期待機後も変換/書込等の保護期限は有効 | NFR1、NFR2 |
| T7 | token確定前・進捗前・進捗中の取消を正しい要求へ配信 | FR3 |
| T8 | 取消後の遅い完了/進捗を拒否、実終端前の再入を防止 | FR3、NFR2 |
| T9 | 通信/権限/不明失敗を写真番号付きで表示、一式成功にしない | FR4 |
| T10 | 失敗/取消cleanup後の新しい再出力が成功、旧成果物保護 | FR4、NFR2 |
| T11 | 256MiB予算・owner/grant解放・写真正本非変更の既存契約 | NFR2 |
| T12 | 待機中MainActor操作可能、取消文言を進捗が上書きしない | FR3、NFR1 |
| U1 | 実画面で写真番号と進捗なし→中間→取得完了→一式完了 | FR1–FR2 |
| U2 | 待機/進捗中に取消、処理中再入拒否、画像/本文復帰 | FR3、NFR2 |
| U3 | 写真2取得失敗からアプリ内再出力で4枚成功、本文/順序保持 | FR4、NFR2 |

関連ケースは最少の独立テストへまとめてもよいが、全対応と意図した失敗の証拠を残す。UIは自動試験専用UUID rootと合成画像のみを使い、既存FixtureLaunchの所有cleanupを利用する。

## CIと戻し方

既存ブランチ/PRでCIを利用する。対象限定Red/Greenが必要な間だけmarker限定の一時workflowを追加できる。Actions SHA pin・read-only権限・合成データのみ・短期artifact保持を維持し、同一SHAのpush/PR重複は一方を取消して成功証拠へ数えない。最終通常CIの条件は省略しない。既存runnerを変更する必要があれば、理由と契約回帰を先に確認し、無断で選択やcoverageを弱めない。

実機では写真アプリの事前操作をせず未取得画像を出力し、進捗・取消・再試行・4枚/本文保持を確認する。問題が残れば通常保存で本文を保護し、操作順/文言を記録する。現在の作業をreset/clean/restoreしない。比較が必要なら検証済みf272e3dの別作業領域を使う。設定・記事schemaは変更せず、写真や権限を削除して回避しない。

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
