# 記事アクセス修正のCI証拠

## Baseline
- [PR CI 42016213433](https://github.com/yokochie/hitotsuzuri/actions/runs/42016213433)、対象head `8229a1d116b7378507605171a0f990c6bca3544e`、結論success。
- Core job `127207276439`: runner選択契約28件成功（7.120秒）、Core機能454件実行成功。
- Native job `127208099449`: fixture smoke2件成功、主bundle517件実行成功（Core454＋UI63）、製品全体5227/5739=91.08%。
- どちらも完了jobログの`Verified`とcoverage出力を確認した。CI成功を本人の実機での権限エラー再現・修正成功とは扱わない。
- 記録のみの次コミット`8727406`とbaselineの間で、App/Core/全4試験ターゲット/scripts/.githubの差分なしを`git diff --quiet`で確認。本人の既存scheme差分は変更せず保持している。
- 重複push run `42016144277`はcancelしPR runを採用。ローカルUI/native試験を追加実行していない。

## Red / Green
実装計画承認後、Core回帰6件を追加。Python選択契約28件成功（4.318秒、1回）、新クラスの自動検出と差分整形を確認。製品helperは未変更。実行結果が得られてからSHA・run/job・対象メソッド・期待失敗/成功を追記する。現時点ではRed成立・修正済みとしない。
