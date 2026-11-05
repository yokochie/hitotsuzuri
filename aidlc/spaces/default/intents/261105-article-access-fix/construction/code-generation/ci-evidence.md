# 記事アクセス修正のCI証拠

## Baseline
- [PR CI 42016213433](https://github.com/yokochie/hitotsuzuri/actions/runs/42016213433)、対象head `8229a1d116b7378507605171a0f990c6bca3544e`、結論success。
- Core job `127207276439`: runner選択契約28件成功（7.120秒）、Core機能454件実行成功。
- Native job `127208099449`: fixture smoke2件成功、主bundle517件実行成功（Core454＋UI63）、製品全体5227/5739=91.08%。
- どちらも完了jobログの`Verified`とcoverage出力を確認した。CI成功を本人の実機での権限エラー再現・修正成功とは扱わない。
- 記録のみの次コミット`8727406`とbaselineの間で、App/Core/全4試験ターゲット/scripts/.githubの差分なしを`git diff --quiet`で確認。本人の既存scheme差分は変更せず保持している。
- 重複push run `42016144277`はcancelしPR runを採用。ローカルUI/native試験を追加実行していない。

## Red
- 実装計画承認後、Core回帰6件を追加。Python選択契約28件成功（4.318秒、1回）、新クラスの自動検出と差分整形を確認。製品helperは未変更。
- SHA `22417808b6f3d57e6752d74814ddfa48b6326057`、[PR CI 42021621097](https://github.com/yokochie/hitotsuzuri/actions/runs/42021621097)、Core job `127225519545`、結論failure。nativeはCore失敗により未実行。重複push run `42021613866`はcancel。
- 新クラス6件実行、2失敗・4成功。既存Core454件は成功（U1は157件中2失敗、U2は149件成功、U3は154件成功）。
- `testExistingArticleUnderSearchOnlyAncestorCanOpenSaveAndReopen`: `ArticleFileSystem.swift:25`から `failed: caught error: "permissionDenied"`（0.901秒）。
- `testMissingArticleDirectoriesUnderSearchOnlyAncestorCanBeCreatedAndListed`: `ArticlePersistence.swift:85`から同じpermissionDenied（0.004秒）。
- どちらも独立したDarwin openで祖先の読取拒否・末端の読取成功を確認した後に失敗。fixture条件・コンパイル失敗ではなく、期待したstore操作の権限エラーを再現した。
- 読取拒否の分類、書込拒否と回復後の同操作再試行、中間symlink拒否、末端symlink拒否の4件は成功。権限復元・UUID領域cleanupの失敗なし。
- 本人実機の直接原因まで確定したとは扱わない。通常Sandbox経路の回帰は修正後に追加する。

## Green
- 対象SHA `88978d6fbac624961c3880ac894facf1c0070469`、[PR CI 42022838099](https://github.com/yokochie/hitotsuzuri/actions/runs/42022838099)。重複push run `42022831466`はcancel。
- Core job `127229603834`はsuccess（1分35秒）。runnerの結果検査が全460件の実行成功を確認。新規ArticleDirectoryAccessTestsは6件全成功（0.153秒）、先のRed2件も成功した。
- 同jobの完了ログで、以下の共通利用者・保護試験の成功を確認した。単なるファイル存在の確認ではない。

| クラス | 成功件数 |
|---|---:|
| ArticleDirectoryAccessTests | 6 |
| ArticleRecoveryTests | 11 |
| ArticlePersistenceTests | 10 |
| ArticleProbeTests | 14 |
| ArticleExportWriterTests | 21 |
| ArticleExportJournalTests | 8 |
| ArticleExportIntegrationTests | 19 |
| ArticleExportOSActionTests | 8 |

- `git diff 2241780 HEAD -- Hitotsuzuri.xcodeproj Hitotsuzuri/Hitotsuzuri.entitlements scripts .github`は差分なし。本人の未commit scheme差分は今回の変更に含めていない。
- main native job `127230329025`はsuccess（19分36秒）。fixture smoke2件成功、主bundle524件（Core460＋UI64）実行成功、全製品行coverage5284/5798=91.13%。runnerが全ケースPassedを確認しており0skip。
- `ArticleSandboxStorageUITests.testArticleCanStartSaveAndReopenInApplicationSupport`は27.277秒で成功。Application Supportの保存モード表示、記事開始、タイトル/本文保存、再起動後の同じ候補識別子と本文、候補1件、app内cleanup成功を同ケースで確認した。
- CIの主bundleは`.build/Native-functional-20261105-115817-2e6be51346164fbb81ff8c973807fe22.xcresult`。これはrunner上の場所であり、ローカルには取得していない。
- Red→Greenの間に変更した製品動作はArticleFileSystemの入口/child作成だけ。ArticlePersistenceは変更不要。Sandbox/entitlements/保存形式/CI/coverage閾値を変更していない。
- 本人環境での通常操作確認は未確認。合成データのCI成功とは別に保持する。性能の一式測定も今回再実行していない。
