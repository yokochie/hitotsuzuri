# 開発・CIの確認根拠

## 現在の観測
- 調査時HEAD: `2b93567`。直近履歴にはPR #1、#2、#4の統合とPR #3の検証記録がある。短い作業ブランチと`main`への統合方針は既存の本人確認済み記録を根拠にする。
- `.github/workflows/verify.yml`: PR、`main`へのpush、手動実行。`xcode-27`でCore専用job成功後に機能jobを実行する。各上限は15分と45分であり、実測時間ではない。
- `native-core`はrunner契約テストとCore試験、`native`は必須smokeと全機能回帰・全製品カバレッジを検査する。後者の`HZS_CORE_PREFLIGHT_DONE=1`はCore事前検査だけを省略し、本体bundleのCore試験は残す。
- `scripts/native-test-runner.py`: groupごとに`xcodebuild test`を起動し、共通`.build/DerivedData`を利用する。結果bundleから選択試験の実行を確認し、全機能の単一bundleでカバレッジを判定する。分割job間でのビルド再利用、UI起動、重複Core試験は計測候補であり、現時点で原因とは断定しない。
- CIには同一refの古い実行を取消す設定、読取専用contents権限、checkoutのcommit固定・認証情報非保持がある。DependabotはActionsを週次更新する。
- 診断用workflowは特定ブランチ・commit文言に限定され、合成データのxcresultを1日保存する。通常検証へ無条件追加しない。

## 既存記録との違い
- `memory/team.md`の「CI構成を確認できず、実行環境未用意」は現行workflowと一致しない。過去の判断は残し、今回確認後の運用説明では現行構成に更新する。
- 既存CodeKBは前回のiCloud出力改善時点の説明を含む。CI構成の概略は参照し、画像取得に関する旧状態を今回の仕様や新たな制約として扱わない。

## Sources
- `aidlc/spaces/default/codekb/hitotsuzuri/code-structure.md`: App/Core/test/scriptsの責務。
- `aidlc/spaces/default/codekb/hitotsuzuri/technology-stack.md`: Swift、Xcode、macOS、Actions。
- `aidlc/spaces/default/codekb/hitotsuzuri/dependencies.md`: target依存と外部package未使用。
- `aidlc/spaces/default/codekb/hitotsuzuri/code-quality-assessment.md`: 試験実行確認、全製品80% floor、性能別区分。
- `aidlc/spaces/default/codekb/hitotsuzuri/architecture.md`: 単一macOS App/Core構成、backendなし。
- `aidlc/spaces/default/codekb/hitotsuzuri/business-overview.md`: 本人Macでの写真選択・記事制作支援。
- `.github/workflows/verify.yml`、`.github/workflows/diagnose-article-export.yml`、`.github/dependabot.yml`。
- `scripts/verify-native.sh`、`scripts/native-test-runner.py`、`scripts/test-native-runner.py`、`git log -8 --oneline`。
- `aidlc/spaces/default/memory/team.md`、`aidlc/spaces/default/memory/project.md`。

## 未確認・本人への質問
- `xcode-27` runnerの実機台数、同時実行枠、共有利用、費用、変更権限はYAMLから分からない。Q1=Cにより、現状を調べてから本人と相談して変更範囲を決める。未調査の状態でrunner増設・同時実行数増加を承認済みとは扱わない。
- 実測時間と現在の最遅区間は未取得。試験・遠隔CI実行は今回の下書き調査では行っていない。
- 他の作業の未コミット変更と`.worktrees/`が存在する。今回の下書き以外を変更していない。

## Interview Decisions
- `practices-discovery-questions.md` Q1: C。実行環境の変更範囲はまだ分からず、現状を調べてから相談して決める。
- 同ファイルのConsolidated Summary Confirmation: Looks correct。main中心の作業、フェーズ完了時コミット、最小の一連の動作確認、TDD・80%・統合前CI、本人Macでの利用、有料サービスを前提としない方針、日本語記録を維持する。
- 旧CI未用意の説明を現在のActions構成に合わせることを確認した。
- 協力担当の追加は無効であり、リリース担当単独で調査・統合した。試験・遠隔CIの実行と時間計測は後続段階で実施する。
