# CI容量の設計

`../nfr-requirements/scalability-requirements.md`と`../nfr-requirements/tech-stack-decisions.md`を参照。
- 既存のxcode-27とCore→機能ジョブの依存関係を前提に、機能ジョブ内部の時間を削減する。リポジトリのrunner一覧が0件でも、実際のジョブは動作しており、共有・ホスト構成と枠は未確認。
- 並列化候補は別々のGUIセッション、CPU/メモリ、固有の結果・作業領域、同時実行枠、費用を先に確認する。同一デスクトップを操作するテストの並行実行は、独立性の証明がある場合に限る。
- 現行の同一ref取消を維持し、容量変更は根拠と影響を示して本人と相談する。
