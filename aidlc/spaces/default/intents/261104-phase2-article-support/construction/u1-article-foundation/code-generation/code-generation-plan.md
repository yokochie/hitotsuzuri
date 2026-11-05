# U1 コード実装計画

## Summary

- Builds: 記事開始・基本編集・手動保存/再開と、通信なしの実画像1枚検証出力。
- Touches: HitotsuzuriCoreの記事/保存/画像/出力、Hitotsuzuriの画面/メニュー、Xcode設定、専用試験とCI。
- Tests: 5責務で各5〜8件を基準に約40件の単体試験、8件以上の統合試験、6件以上のUI試験と性能/障害試験。

## 入力・境界
このUnitのfunctional-design、nfr-requirements、nfr-design、infrastructure-designの全成果物、inceptionのrequirements.md、stories.md、components.md、contract-summary.md、unit-of-work.md、unit-of-work-story-map.mdを正とする。新機能の日付/撮影情報フォーム・候補選択完成はU2、4枚/記事/manifest・コピー/Finder完成はU3。U1は単独で動作する最小統合で、後続型へ依存しない。

## 変更範囲と所有
| ファイル | 操作・責務 | 影響/試験 |
|---|---|---|
| HitotsuzuriCore/ArticleModels.swift、ArticlePorts.swift、ArticleFingerprint.swift | 新規。記事/操作/失敗/固定値・共有指紋 | 保存/後続利用、ArticleModelTests |
| HitotsuzuriCore/ArticlePersistence.swift、ArticleFileSystem.swift | 新規。独立記事保存、不変操作/current、descriptor相対/排他/同期 | ArticlePersistenceTests、ArticleRecoveryTests |
| HitotsuzuriCore/ArticleWorkspace.swift、ArticleEditSession.swift | 新規。同一性、写真なし再開、手動保存/離脱 | ArticleWorkspaceTests、ArticleSessionTests |
| HitotsuzuriCore/ArticleImageAccess.swift、ArticleImageConverter.swift | 新規。PhotoKit読取・用途別変換・期限/資源 | ArticleImageTests、ArticleResourceTests |
| HitotsuzuriCore/ArticleProbeDelivery.swift | 新規。先頭1枚の固定出力・確定/取消/回復 | ArticleProbeTests |
| Hitotsuzuri/ArticleView.swift、ArticleAppCoordinator.swift | 新規。最小編集画面、出力先選択、閉じる/終了調整 | ArticleFoundationUITests |
| Hitotsuzuri/HitotsuzuriApp.swift、PickerView.swift、DebugFixture.swift | 変更。依存注入、記事メニュー/画面、専用合成fixture | 既存選択の起動/フォーカスを回帰確認 |
| HitotsuzuriCore/PickerContent.swift | 変更。確定後の記事入口callbackのみ追加 | 既存selection-confirm/保存状態を保持。既存初期化は既定引数で互換 |
| Hitotsuzuri/Hitotsuzuri.entitlements | 変更。user-selected.read-writeだけ追加 | Sandbox/写真権限維持、広域権限/ネットワーク追加なし |
| Hitotsuzuri.xcodeproj/project.pbxproj | 変更。新Swift/試験ファイル参照 | 既存4試験ターゲット維持、製品ソースの計測漏れなし |
| HitotsuzuriU1Tests/Article*Tests.swift、ArticleTestDoubles.swift | 新規。上記単体/統合/性能 | Phase1のU1命名と混同せずArticle接頭辞で限定 |
| HitotsuzuriUITests/ArticleFoundationUITests.swift | 新規。記事開始→保存→再起動/再開→合成画像出力 | 実写真/本人領域を使わない |
| scripts/verify-article-foundation.sh | 新規。Article試験クラスを厳密指定 | 最初のRed前にrunner準備 |
| scripts/verify-native.sh | 必要なら変更。新試験を同じ承認済み実行へ含める | コマンド表記を維持、除外/閾値低下なし |
| .github/workflows/verify.yml | 新規。標準xcode-27で必須試験/80%以上 | U1統合前のCI、読取権限、秘密情報/アップロードなし |

アプリはApp→Coreへ依存する。選択モデル/保存の正本を改変しない。現在の共有schemeには本人の`--measure-native`無効化差分があるので保持し、巻き戻さない。既存AGENTS/README/設定/未追跡ファイル/Phase1設計資料を今回の変更に紛れ込ませない。必要な試験設定差分があれば既存値を保持して追加する。

## 実装順序
各チェックボックスは実装完了時にだけ記す。TDDは各層でRed出力→Green→整理と再成功を記録する。API/endpointは外部サーバーではなく内部protocol境界へ適用する。

- [x] Step 1: 変更前baselineを承認済みbash scripts/verify-native.shで実行し、既存失敗/件数/カバレッジを記録。全試験が起動できない場合は理由と影響を明示する。本人の作業差分を保護。
- [x] Step 2: runner/config準備。scripts/verify-article-foundation.shへ厳密Articleクラスfilterを設定し、既存U1IntegrationTestsの厳密filterでXCTest実行可能性を先に確認。Xcode参照の最小追加を行う。新クラス未作成時の「0試験成功」をRed/Greenとして記録しない。
- [x] Step 3: データモデルRed。ArticleModelTestsに4ID/順序、自由文字往復、版/不正値、共通指紋の空/null/改行/Unicode/順序の失敗例を先に書き実行。
- [x] Step 4: データモデルGreen。ArticleModels/Ports/Fingerprintを最小実装し、版付き型タグ/長さ/順序とSHA256を固定。同一ベクトルを後続へ公開。
- [x] Step 5: データモデルRefactor。全該当試験を緑に保ち、元選択写しと記事正本を分離。
- [x] Step 6: 永続化Red。ArticlePersistenceTests/ArticleRecoveryTestsで初期作成/保存/再開、不在/破損/未知版、操作ID再試行、後続保存後の旧ID、同期/確定前後の障害、外部変更/リンク/容量不足を先に検証。
- [x] Step 7: 永続化Green。ArticleFileSystem/Persistenceに記事別不変操作/current・排他/同期/検証を実装。同operationID照合を競合判定より先にし、確定後不確定は照合する。正常ボリュームの必要APIを小さな試験で実証。
- [x] Step 8: 永続化Refactor。失敗で元byte保持、確定参照だけを正とする復旧、逐次走査、索引派生を整理して再実行。
- [x] Step 9: 操作調整Red。ArticleWorkspaceTests/ArticleSessionTestsで画像なし文章再開、二重起動、保存中編集/古い応答、未保存離脱3択/保存失敗、候補がある時の無断作成防止を先に試験。
- [x] Step 10: 操作調整Green。ArticleWorkspace/EditSessionを実装し、既存SelectionStoringから直接読込。lastCommittedの画像成功に依存させず、基本全本文欄を持つ。
- [x] Step 11: 操作調整Refactor。正本と作業コピー・session/operation/generationを整理し全該当試験を再実行。
- [ ] Step 12: 画像/出力境界Red。ArticleImageTests/ArticleResourceTests/ArticleProbeTestsで現在編集/向き/縮小/JPEG/不要メタデータ、network=false、30秒、取消受理/終端、バッファ所有、保存先選択前grantなし、確定/片付け失敗を先に試験。
- [x] Step 13: 画像/出力境界Green。PhotoKit入力URLからImage I/O変換・sRGB新規JPEG、実処理単一ゲート・予約256MiB、期限/取消状態を実装。完了採用直前にも絶対期限比較、同時は期限優先。先頭1枚を別フォルダへ非上書き確定。OS処理残存と論理終端を分離。
- [x] Step 14: 画像/出力Refactor。権限寿命/遅延応答/回復記録を整理、容量とOSメモリの測定/非対応分類を再確認。未達を閾値変更で隠さない。
- [x] Step 15: フロントエンドRed。ArticleFoundationUITestsの開始/日本語編集/保存再起動/画像なし/未保存離脱/1枚出力を先に実行し失敗を記録。合成fixtureの必要配線をrunner準備として分離。
- [x] Step 16: フロントエンドGreen。ArticleView/CoordinatorとApp/Picker入口を接続。識別子・文字状態・キーボード・狭幅・閉じる/終了確認、フォルダ選択を実装。写真取得不能でもフォームを開く。
- [x] Step 17: フロントエンドRefactor。既存選択操作/焦点/保存の回帰を確認し、入力と表示を失わないよう整理。
- [x] Step 18: 統合試験。ArticleIntegrationTestsで実ファイル保存/再起動照合と実Image I/O合成画像→1枚出力を通す。成功/失敗/取消・旧成果物非変更、ログ捕捉、100記事/1000操作/長文とメモリ/時間を計測。新規統合経路もRed→Greenで追加。
- [x] Step 19: 環境/CI。権限・Xcode参照・標準xcode-27 workflowを完成し、承認済み全体検証と80%以上を実行。CIを同commitで実行してURL/結果を記録。外部pushに必要な具体差分と未実機確認を提示し、未実行CIを成功にしない。
- [x] Step 20: 記録/本人手順。code-summary、全AC/BR/詳細NFRのtraceability、source-manifest、TDD証拠を作成。日本語の実機起動/写真/Sandbox/1枚デモ/戻し方を記録し、本人確認が必要な点を分ける。未確認/未達は明示。

## レビュー所見の実装条件
機能設計の保存版確認先行はStep7の操作ID先行照合で解消する。出力先未選択のgrantはStep12/13の状態別型で表現。品質設計の期限同時競合はStep12/13で完了採用直前の絶対比較と逆順配送を試験する。上流契約の投影projectIDは後続U2、共通指紋基礎は本Unit。仕様と実装の差分は記録し、上流レビュー後の成果物を黙って編集しない。

## 品質・限界
全製品80%以上と統合前CI、30秒/40秒・256MiB/512MiB・取消0.5秒/2秒・保存p95 2秒を維持。API/OS内部の保証と実測を区別し、達成できない経路は未達/取得不能として明示する。実写真の非変更・現在編集/色/回転・Sandbox・実機再起動は本人確認を別に必要とする。U1では4枚一式やnote受渡し成功を主張しない。

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
