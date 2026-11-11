# ドラフトPRでのCI検証

- 検証対象は [PR #5](https://github.com/yokochie/hitotsuzuri/pull/5)、head `4d64dc42d765da79ffe485fbccd6025c29bca18e`。基点は `65de561`。
- [初回CI](https://github.com/yokochie/hitotsuzuri/actions/runs/42330520754) は成功。2026-11-07 11:41:55 JSTのPR作成から、12:08:02 JSTの最終必須ジョブ完了まで26分07秒。Coreは1分23秒、機能ジョブは24分35秒。
- PRはドラフト。対象は既存GitHub Actionsでの検証。作業の確認条件は `../../construction/ci-pipeline/ci-config.md` と `../../construction/ci-pipeline/quality-gates.md` を参照。
