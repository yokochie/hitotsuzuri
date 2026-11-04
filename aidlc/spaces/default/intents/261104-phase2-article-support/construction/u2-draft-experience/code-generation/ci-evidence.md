# U2 CI検証記録

## 実行準備

- 作業ブランチ: `codex/phase2-u2-draft-experience`。承認済みU1の現在の作業ツリーを保持して分岐した。main統合・配布は行わない。
- 本人の公開コード/試験push承認と、U2の承認済みコード計画Step17に基づく。
- 新しいスクリプトの無引数はsmoke→全4target→単一主bundleの製品加重カバレッジ80%以上。部分実行の結果は全体合格に置き換えない。
- workflowは通常・性能・全体の区分を持つ。全体を指定すると通常/性能ジョブは同時に重複起動しない。旧U1ブランチのbaseline-native診断は保持する。
- GitHubのdefault branchはmainだが、2026-11-05時点のmainに`.github/workflows/`は存在しなかった。手動実行はworkflowがdefault branchに必要なため、統合前にも全体検証できるよう、commit messageの`[verify-all]`を明示指定したpushでもnative-allを選べるようにした。これは試験をskipする指定ではなく、全体の試験/カバレッジを一度だけ実行する選択である。
- 上記の手動実行条件は[GitHub公式説明](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow?tool=webui)で確認。新YAMLはRuby標準YAMLで構文読取成功。GitHub上での実行成功とは別である。

## 未実施

現時点ではU2候補のcommit/pushとCI実行はまだ行っていない。最後に確認済みの[旧U1候補の実行](https://github.com/yokochie/hitotsuzuri/actions/runs/41798035585)は失敗している。U2の限定ローカル成功からCIの成功を推定しない。

公開対象はsource-manifestに列挙するコード/試験と、このUnitの関連記録に限定する。本人のscheme変更、Phase1 audit、未追跡のハーネス設定等をまとめてstageしない。
