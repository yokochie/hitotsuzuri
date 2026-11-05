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
未実行。Redを確認した後、承認済み計画の最小修正へ進む。
