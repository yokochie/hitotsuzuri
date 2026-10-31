# 実装・確認の担当

入力: [要件](../requirements-analysis/requirements.md)、[ストーリー](../user-stories/stories.md)、[詳細画面](../refined-mockups/mockups.md)、[構成要素](../domain-design/components.md)、[単位定義](../units-generation/unit-of-work.md)・[依存](../units-generation/unit-of-work-dependency.md)・[対応表](../units-generation/unit-of-work-story-map.md)、[内部契約](../contract-design/contract-summary.md)、[開発規約](../practices-discovery/team-practices.md)、[確認回答](delivery-planning-questions.md)。

1回の実装・検証を動く増分にする区切りをBoltと呼ぶ。B1/U1、B2/U2、B3/U3すべての実装担当はaidlc-developer-agent（AI）。今回、人間の複数チームや並行実装は編成しない。

| 対象 | AI担当 | 本人担当 |
|---|---|---|
| 設計・コード | 契約と要件に沿う設計、TDD、差分説明 | 計画・重要判断・確認点の承認 |
| ビルド・自動テスト | 実行と結果記録、カバレッジ、失敗修正 | 必要な環境・設定の確認 |
| 実写真の確認 | 日本語手順・チェック項目の用意 | 許可操作、実フォルダ/順序/画像、再起動、操作支援 |
| CI | 構成案、ワークフロー、失敗解析 | 実行用環境・登録と必要な権限の確認 |

本人の都合による確認待ちは待機として明示し、未確認を合格にしない。秘密情報や写真内容を記録へ貼り付ける必要はない。実機確認の所要時間は未確定で、日程は本人と調整する。
