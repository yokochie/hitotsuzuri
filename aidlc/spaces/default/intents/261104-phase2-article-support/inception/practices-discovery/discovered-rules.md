# 本人指定の制約

既存規約と本intentの本人確認済み回答だけを記載する。慣行の推測を強制規約へ昇格させない。既存ルールへの反映は本段階の本人承認後に行う。

## Mandated
- ALWAYS 要件と実装計画の本人確認後に実装へ進む。
- ALWAYS AI-DLCの各フェーズ完了時に、そのフェーズの成果物と関連変更をGitにコミットする。
- ALWAYS 要件・設計判断・進捗・検証結果を日本語Markdownへ残し、Swift・Xcodeの経験を前提にしない実行・検証手順を用意する。
- ALWAYS 写真アクセス等、本人による実機確認が必要な項目を明示し、自動試験の成功と区別する。
- ALWAYS Phase2は本人のMacで利用する記事制作支援として実装し、noteへの受渡しを本文コピーと画像の手動アップロードで行う。
- ALWAYS Phase2の下書きを手動保存とし、未保存で離れるときに保存するか確認する。
- ALWAYS Phase2の統合前CIの条件を維持し、実行先・設定・費用の有無を実装計画で具体化して本人確認する。

## Forbidden
- NEVER アプリから写真ライブラリ内の写真・アルバム・フォルダを変更する。
- NEVER アプリから画像取得のための通信を要求する。
- NEVER 設計資料の技術選定や参考コードを、成立性を検証せず確定仕様として扱う。
- NEVER Phase2へ動画生成、制作履歴一覧・通知、生成AIの文章補助、noteへの自動投稿・直接連携、外部公開・独自クラウド機能を追加する。
- NEVER 本プロジェクトでVoiceOverの追加設計・検証を要求する。
- NEVER 統合前CIの条件を満たす前に統合完了と扱い、またはローカルの手動テストをCI実行済みと記録する。

## 出典
既存の`aidlc/spaces/default/memory/project.md`、本intentの`ideation/intent-capture/intent-capture-questions.md`、`ideation/feasibility/feasibility-questions.md`、`ideation/scope-definition/scope-definition-questions.md`、`ideation/rough-mockups/rough-mockups-questions.md`、本段階の`practices-discovery-questions.md`。回答・要約確認と、本段階全体の承認は区別する。
