# U3 操作規則

```yaml
{
  "rules": [
    {
      "id": "BR3.1",
      "statement": "領域とフォーカスをIDで保持し幅変更で編集を失わない",
      "category": "policy",
      "applies_to": "PickerPresentationと既存の進行・画像担当",
      "trigger": "領域切替・幅変更",
      "logic": "IF 領域切替・幅変更 THEN 存在する直前の対象へ戻し、非同期完了で奪わない",
      "violation_behaviour": "状態不一致を成功とせず検証失敗として記録する",
      "source": "NFR4"
    },
    {
      "id": "BR3.2",
      "statement": "キーボードで許可から確定まで到達する",
      "category": "policy",
      "applies_to": "PickerPresentationと既存の進行・画像担当",
      "trigger": "入力",
      "logic": "IF 入力 THEN 矢印・Space・Tabと標準一覧操作を提供し取得不可の理由も確認可能にする",
      "violation_behaviour": "状態不一致を成功とせず検証失敗として記録する",
      "source": "NFR4"
    },
    {
      "id": "BR3.3",
      "statement": "選択と4枠を同じ状態から表示する",
      "category": "policy",
      "applies_to": "PickerPresentationと既存の進行・画像担当",
      "trigger": "選択・解除",
      "logic": "IF 選択・解除 THEN 5枚目を拒否し選択順・枚数・実画像と読み上げを一致させる",
      "violation_behaviour": "状態不一致を成功とせず検証失敗として記録する",
      "source": "FR4"
    },
    {
      "id": "BR3.4",
      "statement": "保存結果と権限案内を分離する",
      "category": "policy",
      "applies_to": "PickerPresentationと既存の進行・画像担当",
      "trigger": "保存・復元・失敗",
      "logic": "IF 保存・復元・失敗 THEN 置換成功を後続権限喪失や呼出し取消で保存失敗に変えず、実失敗は旧確定と編集を保持",
      "violation_behaviour": "状態不一致を成功とせず検証失敗として記録する",
      "source": "FR6"
    },
    {
      "id": "BR3.5",
      "statement": "必要な表示画像と選択以外を解放し古い応答を採用しない",
      "category": "policy",
      "applies_to": "PickerPresentationと既存の進行・画像担当",
      "trigger": "スクロール・切替",
      "logic": "IF スクロール・切替 THEN 通信を要求せず既存256MiB・8要求・15秒上限内で管理",
      "violation_behaviour": "状態不一致を成功とせず検証失敗として記録する",
      "source": "NFR2"
    },
    {
      "id": "BR3.6",
      "statement": "操作反映と資源安定を実測する",
      "category": "policy",
      "applies_to": "PickerPresentationと既存の進行・画像担当",
      "trigger": "受け入れ検証",
      "logic": "IF 受け入れ検証 THEN 100枚以上・30操作の95%以上200ms以内、10往復で増大継続なし、不要要求15秒以内0を確認",
      "violation_behaviour": "状態不一致を成功とせず検証失敗として記録する",
      "source": "NFR2"
    }
  ]
}
```

## 要約

BR3.1〜3.3はフォーカスと選択の表示、BR3.4は保存と権限の整合、BR3.5〜3.6は表示資源と実測を扱う。詳細手順はfunctional-spec.mdを正本とする。
