# 実装単位の依存関係

入力: [構成要素](../domain-design/components.md)、[設計判断](../domain-design/decisions.md)、[要件](../requirements-analysis/requirements.md)、[ストーリー](../user-stories/stories.md)。単位定義は[unit-of-work.md](unit-of-work.md)。

```yaml
units:
  - name: u1-integrated-selection
    kind: service
    depends_on: []
  - name: u2-session-reliability
    kind: service
    depends_on: [u1-integrated-selection]
  - name: u3-native-experience
    kind: ui
    depends_on: [u1-integrated-selection, u2-session-reliability]
```

## 依存の意味

| 単位 | 必要な単位 | コード・テスト上の理由 |
|---|---|---|
| U1 | なし | 実ライブラリから選択・保存までを内包する統合された最小構成 |
| U2 | U1 | ライブラリ・画像・選択・保存の実装を利用し、状態と異常系を完全化する |
| U3 | U1、U2 | U1の参照・選択とU2の保存・復元・失敗状態を用いて画面と操作支援を仕上げる |

U1は後続なしで起動できる最小の統合単位であり、孤立したレイヤーや設計文書だけでは完了しない。U2/U3の依存はコードとテストが必要とする実際の依存として記録する。

## 接続点

U1で5責務間の接続を導入し、U2は保存結果・参照検証・復元状態を完全化、U3はその表示用状態と操作を利用する。公開契約と失敗の意味はContract Designで明記する。同じアプリ内の呼出しとID参照を使い、HTTPや外部イベント基盤は追加しない。

## 並行性と制約

このDAGでは相互に独立な複数単位はない。U2はU1を、U3はU2を必要とするため、異なる作業コピーで未完成の相手に依存せず同時に完成させる分割ではない。各単位内のテスト作業などの並行性は別途検討できる。ここでは依存の構造だけを定義し、実演・日程・実装の正式な順序と確認点はDelivery Planningに残す。
