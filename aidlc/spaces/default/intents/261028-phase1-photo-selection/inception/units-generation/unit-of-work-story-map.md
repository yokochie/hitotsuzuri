# 実装単位とストーリーの対応

入力: [要件](../requirements-analysis/requirements.md)、[ストーリー](../user-stories/stories.md)、[構成要素](../domain-design/components.md)、[設計判断](../domain-design/decisions.md)。単位は[定義](unit-of-work.md)・[依存](unit-of-work-dependency.md)を参照。

| Story | Unit ID | Directory | 担当範囲 |
|---|---|---|---|
| US1.1 | U1; U2; U3 | u1-integrated-selection; u2-session-reliability; u3-native-experience | U1認可基礎、U2権限喪失等、U3キーボード・読み上げ |
| US1.2 | U1; U3 | u1-integrated-selection; u3-native-experience | U1階層・探索・重複排除、U3長い名称・領域移動 |
| US1.3 | U1; U2; U3 | u1-integrated-selection; u2-session-reliability; u3-native-experience | U1写真抽出と順序・ローカル画像、U2遅延失敗、U3資源管理と性能 |
| US1.4 | U1; U3 | u1-integrated-selection; u3-native-experience | U1四枚制限・順序・解除、U3プレビュー・操作支援・表示性能 |
| US1.5 | U1; U2; U3 | u1-integrated-selection; u2-session-reliability; u3-native-experience | U1変更時の基本選択、U2保存済みと編集の整合、U3未保存表示 |
| US1.6 | U1; U2; U3 | u1-integrated-selection; u2-session-reliability; u3-native-experience | U1参照検証と保存基礎、U2完全な保護・競合・再試行、U3保存状態とフォーカス |
| US1.7 | U2; U3 | u2-session-reliability; u3-native-experience | U2正常・欠損・破損・権限なし復元、U3復元状態表示 |
| US1.8 | U1; U2; U3 | u1-integrated-selection; u2-session-reliability; u3-native-experience | U1基本検証と安全性、U2外部変更と回復、U3案内と操作支援 |

全8ストーリーを割り当て、全3単位に実装する範囲がある。複数単位にまたがる受け入れ条件は単位ごとのFunctional Designで寄与と非該当理由を明記し、後続単位だけが満たす条件をU1完了時に合格としない。

## 単位内の進め方

各単位内では契約と受け入れ条件を確認し、テスト可能な層ごとに失敗テスト→実装→整理→回帰確認を行う。必要な本人の実機確認と結果記録を行い、計画上の出口を確認する。単位間の正式な実装順序・デモ・コマンドはDelivery Planningで確定する。
