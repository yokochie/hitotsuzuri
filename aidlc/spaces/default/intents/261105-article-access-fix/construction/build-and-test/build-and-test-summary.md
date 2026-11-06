# 記事アクセス修正の品質確認

## Inputs and Target Inventory
- 実装範囲とTesting Contract: `../code-generation/code-generation-plan.md`。
- 対象試験・CI優先・再実行抑制: `../code-generation/unit-test-instructions.md`。
- 変更内容・実績・本人確認手順: `../code-generation/code-summary.md`。
- 直接要件: `../../inception/requirements-analysis/requirements.md`。以下のrequirements.mdはこのファイルを指す。
- 本intentのnfr-requirements/nfr-designはSKIPで資料なし。定量条件は直接要件とTesting Contractから抽出した。別intentのPhase2で受容済みの未確認を今回の合格へ変更しない。
- Unit分割なし。主な検証はCore結合6件＋Sandbox UI1件、既存の全機能試験、設定差分・追跡・記録確認。Minimalのため追加のintegration/performance/security指示書は生成せず、承認済みunit-test-instructionsを使用する。

## Target Verification Matrix
| Target ID | Source | Expected | Actual | Evidence | Owning Stage | Verdict |
|---|---|---|---|---|---|---|
| BT00 | code-generation-plan.md#Implementation Steps | 製品と試験がコンパイル・リンク・起動可能 | CI xcodebuild test成功、smoke2件成功 | Core/Native完了jobログ、code-summary.md | build-and-test | Met |
| BT01 | requirements.md#FR1 | 検索のみ祖先下の既存記事を読込・保存・再開 | 新規Core既存記事ケース成功 | Core job 127229603834／testExistingArticleUnderSearchOnlyAncestorCanOpenSaveAndReopen | build-and-test | Met |
| BT02 | requirements.md#FR1 | 不足する記事ディレクトリを作成し一覧・再開 | 新規Core新規作成ケース成功 | Core job 127229603834／testMissingArticleDirectoriesUnderSearchOnlyAncestorCanBeCreatedAndListed | build-and-test | Met |
| BT03 | requirements.md#FR1 | 通常Application Support経路で記事開始・保存・再開 | Sandbox UI1件成功、27.277秒 | Native job 127230329025／ArticleSandboxStorageUITests | build-and-test | Met |
| BT04 | requirements.md#FR2 | 実際の読取拒否を失敗として返し、復元後に回復 | 新規Core読取拒否ケース成功、元bytes保持 | Core job 127229603834／testReadDeniedIsNotAnEmptyDraftList | build-and-test | Met |
| BT05 | requirements.md#FR2 | 書込拒否で元記事保持、同操作再試行で重複なし | 新規Core書込拒否・回復ケース成功 | Core job 127229603834／testWriteDenialPreservesArticleAndRetrySucceedsAfterRestoration | build-and-test | Met |
| BT06 | requirements.md#FR3 | 共通利用者の正常系と取消・中断・競合・所有外保護 | 既存保存・1枚/4枚出力・journal・OS境界試験成功 | ci-evidence.mdのクラス別件数、全機能CI524件 | build-and-test | Met |
| BT07 | requirements.md#NFR1 | 中間・末端symlink拒否、リンク先変更なし | 新規Core symlink2件成功 | Core job 127229603834／ArticleDirectoryAccessTests | build-and-test | Met |
| BT08 | requirements.md#NFR1 | fd相対I/O・排他・確定・差替え防御維持、追加権限なし | 既存保護試験成功、設定差分なし、独立点検追加所見なし | code-generation/reviews/review-01.md、Core完了ログ | build-and-test | Met |
| BT09 | requirements.md#NFR2・Testing Contract | 意図したRedを実装前に得てGreenへ進む | 2241780の権限エラー2件→88978d6で6件全成功 | Red42021621097とGreen42022838099 | build-and-test | Met |
| BT10 | requirements.md#NFR2・Testing Contract | 全既存機能成功・0skip・最小回帰とhappy-path維持 | 主524/524、smoke2/2、先行Core460/460、0skip | Native/CoreのVerified出力、runner契約28件成功 | build-and-test | Met |
| BT11 | requirements.md#NFR2・Testing Contract | 全製品行coverage80%以上、除外・閾値緩和なし | 5284/5798＝91.13%、設定差分なし | Native job 127230329025／check-coverage.swift | build-and-test | Met |
| BT12 | requirements.md#NFR2 | 統合前CI、成功結果と現在ソースの一致 | head88978d6のCI success、現在source diff exit0 | 本段階のgh run viewとgit diff --quiet | build-and-test | Met |
| BT13 | requirements.md#NFR2・NFR3 | CI優先、重複起動削減、通常データと一時データの保護 | ローカルnative/UI/性能0回、重複push run取消、合成UUID cleanup成功 | ci-evidence.md、FixtureLaunch/新UI試験、ローカル不在確認 | build-and-test | Met |
| BT14 | requirements.md#NFR3 | 本人確認手順を集約し、自動成功と実機未確認を区別 | code-summary.mdに一連の手順と未確認を明記、PRも同状態 | code-summary.md#Manual Verification、PR2 | build-and-test | Met |
| BT15 | Testing Contract／strategy_volume | 要件ごとの有効な試験と各componentのhappy-path | 6要件を新規7件・既存機能・設定/記録確認へ対応、欠落なし | cross-unit-traceability.md、最終追跡検査 | build-and-test | Met |
| BT16 | build-and-test Step1／一般CI所有規則 | 今回CI Pipeline段階が担当する一般義務 | the plan runs no CI Pipeline。明示NFR2のCI義務はBT12で別途達成 | aidlc-state.mdのci-pipeline SKIP | build-and-test | N/A |

## Execution Policy
承認済みのCI優先方針に従い、同じソースに対して既に実行したCIを結果として採用する。部分再現コマンドの対象も全機能主bundleへ含まれ、重複してローカル実行しない。Build and TestではCI完了状態・ソース一致・上流入力との対応を再確認する。

## Readiness and Limits
最終判定: SUCCESS。適用対象16件がMet、一般CI所有規則1件がN/A、Not Met/Unverified/Pendingは0件。今回の修正はbuild-ready/test-ready。Deploy-readyの最終判定は本人のMacでの通常起動確認を含む後続手順で行い、まだ本人環境で症状が解消したとは主張しない。

NFR3は一連の確認手順と自動/本人確認の区別を求めており、この条件はcode-summaryとPRで満たした。本人確認の実施結果は未確認のままDeployment Executionへ引き継ぐ。追加の性能測定や過去の全未確認項目の再実行は承認済み計画の対象外である。今回の成功で既知の制約を解消済みへ変更しない。

