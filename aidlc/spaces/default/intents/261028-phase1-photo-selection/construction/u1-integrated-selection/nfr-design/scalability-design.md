# U1 容量設計

根拠: [性能要件](../nfr-requirements/performance-requirements.md)、[保護要件](../nfr-requirements/security-requirements.md)、[容量要件](../nfr-requirements/scalability-requirements.md)、[信頼性要件](../nfr-requirements/reliability-requirements.md)、[診断要件](../nfr-requirements/observability-requirements.md)、[技術選定](../nfr-requirements/tech-stack-decisions.md)、[機能仕様](../functional-design/functional-spec.md)、[内部契約](../../../inception/contract-design/contract-summary.md)、[確認回答](nfr-design-questions.md)。本段階は設計であり、製品のビルド・動作を確認済みとしない。

## SC1 探索と表示

対応: NFR2.7、NFR2.8。深い階層は明示スタックで探索する。フォルダIDの訪問済み集合とアルバムIDの採用済み集合を分け、同名異IDは統合しない。入力順を保持する。選択フォルダの順序は画面の階層順、アルバム内写真の順序は取得順の相対順序。動画を除外する際も日時ソートを追加しない。

探索コストは訪問するフォルダ・所属辺・アルバム数に比例する。メタデータは画像と分けて保持し、画像はLazyな画面セルの必要範囲だけ。表示対象が変わるたびに必要集合を差分更新する。100枚は受け入れ試験の下限であり、読み込む写真を100枚で切らない。極端なライブラリでメタデータ取得が長い場合も進行と取消可能な切替を示し、現在世代の完全な結果のみを確定判断に使う。

## SC2 並行性

対応: NFR2.9。単一アプリセッションにSelectionWorkflowを1つだけ置く。画面を増やして別の選択所有者を作らない。確定操作は最大1件、設定と確定のディスク書込も1本の直列実行。画像最大8件と予算制御はperformance-designのPD2/PD3を共用する。キューの古い世代を破棄し、操作履歴の無制限キューを持たない。

容量目標を超える場合は要求寿命・メタデータ構造・画像サイズを計測して改善する。上限の変更が必要なら変更理由を本人へ示す。クラウド・分散キャッシュ・水平拡張を追加しない。

