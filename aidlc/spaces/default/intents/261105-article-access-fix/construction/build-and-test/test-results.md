# 記事アクセス修正の検証結果

## Inputs and Scope
`../code-generation/code-generation-plan.md`の承認済み8Step・Testing Contract、`../code-generation/unit-test-instructions.md`の対象とCI優先方針、`../code-generation/code-summary.md`の変更・実績を照合した。単一修正・Unit分割なし。要件FR1〜FR3、NFR1〜NFR3を対象とする。

## Final Result
SUCCESS。最終Target Verification Matrixはbuild-and-test-summary.mdに集約。適用16件Met、一般CI所有規則1件N/A、Not Met/Unverified/Pendingなし。新しいソース変更・失敗・懸念がないため同じ試験を再起動せず、承認済みの指示に従って同一ソースのCI証拠を採用した。

## Execution and Identity
- 対象製品/試験SHA: `88978d6fbac624961c3880ac894facf1c0070469`。
- [Green CI42022838099](https://github.com/yokochie/hitotsuzuri/actions/runs/42022838099): completed/success、head一致。Core job127229603834、Native job127230329025ともsuccess。
- 本段階でbuild-instructions.mdの`git diff --quiet 88978d6... -- App/Core/全試験/scripts/.github`を実行しexit0。`gh run view ... --json headSha,status,conclusion,jobs`もexit0。現在の製品・試験・runner・workflowは成功対象と一致する。
- Core/Native完了ログは前段階で取得・確認済み。独立点検でも完了状態と同じjobログを取得して確認している。ローカルのnative/build/UI/性能の再実行は0回。
- 本人の既存scheme Run引数差分を保持。今回のコミットではproject・entitlements・scheme・scripts・workflowを変更していない。CIはコミット済み設定を使った結果であり、本人の通常起動確認は別である。

## Build and Commands
| 実行場所 | コマンド | 結果 |
|---|---|---|
| CI Core job | python3 scripts/test-native-runner.py | exit0、28件成功、3.918秒 |
| CI Core job | bash scripts/verify-native.sh --core | exit0、Core460件実行成功 |
| CI Native job | bash scripts/verify-native.sh --functional | exit0、smoke2件・主524件成功 |
| CI Native runner内部 | xcodebuild test（project/scheme、platform=macOS、coverage=YES、CODE_SIGN_IDENTITY=-） | App/Core/試験のコンパイル・リンクと実行成功 |
| CI Native runner内部 | swift scripts/check-coverage.swift 主bundle | exit0、全製品5284/5798＝91.13% |

環境はmacOS27.0.1(26A434)、Xcode27.1(27A9275)、SDKmacOS27.0、arm64、VirtualMac2,1、image xcode-27-arm64。ローカルMacの性能実測環境とは区別する。

## Counts and Coverage
- 正規の全機能集計: 主bundle524件（Core460＋native SwiftUI/AppKit UI64）、成功524・失敗0・skip0。
- 別途入口smoke: 2件成功。先行Core460件は主bundleにも含まれるため、正規全機能件数へ重ねて加算しない。
- 新規回帰: Core6件＋Sandbox UI1件が全成功。新UIは27.277秒、同じ記事の識別子・文章・再開・UUID cleanupを確認。
- 全製品line coverage: 5284/5798＝91.13%（80%以上）。修正前91.08%から低下なし。分母は全手書きApp/Core source、個別bundleの率の平均ではない。coverage除外・閾値引下げなし。
- CIの主bundle: `.build/Native-functional-20261105-115817-2e6be51346164fbb81ff8c973807fe22.xcresult`。runner上の場所であり、ローカルには取得していない。
- 部分再現3コマンドの対象はこの全機能実行に含まれる。上流指示に従い別の部分native/UI実行を重複起動しなかった。

## Red / Green and Safety
修正前2241780の[CI42021621097](https://github.com/yokochie/hitotsuzuri/actions/runs/42021621097)、job127225519545で、検索のみ祖先下の既存記事ケース（0.901秒）と新規作成ケース（0.004秒）が期待したpermissionDeniedで失敗。fixtureは独立OS呼出しで条件を立証済み、コンパイル/setup失敗やskipではない。残り新規4件と既存454件は成功した。修正後は新規6件すべて成功した。

共通利用者・保護ケースの成功は `../code-generation/ci-evidence.md` のクラス別件数を参照。ArticleRecovery11件、ArticlePersistence10件、ArticleProbe14件、ExportWriter21件、ExportJournal8件、ExportIntegration19件、ExportOSAction8件を含む。既存の排他・競合・不明結果照合・取消・他者ファイル保護を維持した。

UIは実際のmacOS native appで実行し、合成写真/選択とapp自身のSandbox領域だけを使った。ブラウザ・DOM emulatorでの確認ではない。OS設定、一般クリップボード、実Photos/通常保存記事へ接続する追加操作はしていない。

## Known Limits and Handoff
- 本人Macの通常操作による症状解消は未確認。後続Deployment Executionで、code-summary.mdの1セットの操作を確認する。CI成功で本人確認済みへ変えない。
- 性能の一式再測定と旧Phase2の既知の未確認は今回の承認済み範囲外。新しい性能合格証拠として扱わない。
- ローカルの空.buildは削除済み、default.profraw不在。CI側fixtureは当該UUIDだけを回収した。通常データは削除していない。
- 今回のBuild and Testで失敗や未達targetはなく、失敗のloop-backは実施していない。

