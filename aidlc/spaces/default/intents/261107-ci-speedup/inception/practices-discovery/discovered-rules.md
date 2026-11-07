# 確認済み制約

新しい恒久制約は追加しない。以下は既存の本人確認済み方針の再掲であり、今回の質問と要約確認でも維持された。CI高速化の具体策は後続の要件・計画で定める。

## Mandated
- ALWAYS 要件と実装計画の本人確認後に実装へ進む。
- ALWAYS 各フェーズ完了時に成果物と関連変更をGitにコミットする。
- ALWAYS 製品全体の80%以上の行カバレッジと統合前CIの条件を維持する。
- ALWAYS 判断、手順、検証結果を日本語で残し、本人Macでの確認と自動試験を区別する。

## Forbidden
- NEVER 統合前CIの条件を満たす前に統合完了と扱い、ローカル手動テストをCI実行済みと記録する。
- NEVER 本プロジェクトでVoiceOverの追加設計・検証を要求する。

## Sources
- `aidlc/spaces/default/memory/team.md`のWay of Working、Testing Posture、Deployment、Code Style。
- `aidlc/spaces/default/memory/project.md`の既存Mandated、Forbidden。
- `practices-discovery-questions.md`のQ1=CとConsolidated Summary Confirmation=Looks correct。
