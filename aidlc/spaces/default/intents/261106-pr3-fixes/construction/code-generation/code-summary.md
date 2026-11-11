# PR #3 CI契約試験の修正

## 変更
PR head `47cc24a88ae7e1382165e22a1b57e750677db9ac`を起点に、専用作業ディレクトリ `.worktrees/pr3-ci-fix` の `scripts/test-native-runner.py` のみを変更した。

- `is_pinned_action_reference` が正しいAction名と40桁小文字16進commit SHAの完全一致を検査する。
- 診断workflowの旧upload-artifact/checkout SHA完全一致2か所をこの検査へ置換した。
- 新旧commit固定を許可し、tag・branch・短い/不正なSHA・別Action・前後の余分文字を拒否する4つの回帰テストを追加した。
- 既存の診断条件・権限・対象1件・always保存・所有bundle・保持期間・隠しファイルの検査を保持した。workflowとアプリ本体は今回変更していない。

## TDDと検証結果
承認済みTesting Contract `sha256:02e880216f822f2f68029581ce26cea7250bd911a18675cdc550b27d9b586232` に従い、全て同じコマンド `python3 scripts/test-native-runner.py` を専用作業ディレクトリで実行した。

| 段階 | 実測結果 |
|---|---|
| 変更前 | 28件、1 failure、10.162秒。upload-artifact旧SHAとの不整合を再現 |
| Red | 32件、1 failureと14 subtest errors、9.862秒。4つの追加テストが未実装helperのNameErrorで失敗し、既知のSHA不整合も継続 |
| Green | 32件成功、9.875秒、exit 0 |
| Refactor後 | 32件成功、9.863秒、exit 0 |

`git diff --check` はexit 0。変更差分は1ファイル、41行追加・2行削除。新規依存なし。テストは偽装Xcodeと一時fixtureを使い、実写真・利用者データを使用していない。

## 要件対応と残作業
FR1・FR2のローカル契約試験とNFR2の差分制約を満たした。修正はGitHub接続経由でPR #3へ反映済み。対象コミットは `1209e298f6b32b71299c3762b93ee6180f8a9e43`、ファイルblobはローカル検証済みと同じ `77b876cab61a399013884b0cf5e947f30105aadb`。通常のgit pushはHTTPS認証がなく失敗したため、接続済みGitHubのファイル更新を利用した。ローカル専用ブランチの同内容コミットは `2393a8f`。

FR3の通常CI成功確認、およびNFR1の全体Core/UI・80%カバレッジ確認は後続Build and Testで行う。現時点では成功扱いしない。マージは実行していない。
