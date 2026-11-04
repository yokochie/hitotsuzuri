# U2 データモデル

根拠: [実装単位](../../../inception/units-generation/unit-of-work.md)、[割当](../../../inception/units-generation/unit-of-work-story-map.md)、[ストーリー](../../../inception/user-stories/stories.md)、[要件](../../../inception/requirements-analysis/requirements.md)、[構成要素](../../../inception/domain-design/components.md)、[契約](../../../inception/contract-design/contract-summary.md)。[CI省略](../../../change-decisions/2026-10-31-local-verification.md)を適用し、統合前ローカル検証を維持する。

U1から所有者を変えず、次の状態と制約を完全化する。列挙していないライブラリ・画像の値型はC2/C3を利用し、新所有者を増やさない。

```yaml
{
  "entities": [
    {
      "name": "WorkflowState",
      "owner": "SelectionWorkflow",
      "description": "復元と確定の進行状態",
      "attributes": [
        {
          "name": "workflowID",
          "type": "opaque-ID",
          "required": true,
          "unique": true
        },
        {
          "name": "restoreState",
          "type": "enum",
          "required": true,
          "allowed_values": [
            "notStarted",
            "loading",
            "validating",
            "restored",
            "missing",
            "failed",
            "blocked"
          ],
          "default": "notStarted"
        },
        {
          "name": "lastCommittedSnapshot",
          "type": "optional-immutable-CommittedSelection",
          "required": false
        },
        {
          "name": "requestGeneration",
          "type": "integer",
          "required": true,
          "min": 0,
          "default": 0
        },
        {
          "name": "error",
          "type": "optional-typed-failure",
          "required": false
        }
      ],
      "constraints": [
        "復元成功前に保存済みと表示しない",
        "復元失敗で原本を書き換えない"
      ]
    },
    {
      "name": "EditingSelection",
      "owner": "SelectionWorkflow",
      "description": "現在の編集",
      "attributes": [
        {
          "name": "editingSessionID",
          "type": "opaque-ID",
          "required": true,
          "unique": true
        },
        {
          "name": "targetFolderIDs",
          "type": "ID-set",
          "required": true,
          "default": []
        },
        {
          "name": "activeAlbumID",
          "type": "optional-ID",
          "required": false
        },
        {
          "name": "orderedAssetIDs",
          "type": "ordered-ID-list",
          "required": true,
          "min": 0,
          "max": 4,
          "default": []
        },
        {
          "name": "revision",
          "type": "integer",
          "required": true,
          "min": 0,
          "default": 0
        }
      ],
      "constraints": [
        "ID重複なし",
        "復元は全4枚を一括適用、部分適用しない"
      ]
    },
    {
      "name": "CommittedSelection",
      "owner": "SelectionPersistence",
      "description": "最後の確定の永続記録",
      "attributes": [
        {
          "name": "selectionID",
          "type": "opaque-ID",
          "required": true,
          "unique": true
        },
        {
          "name": "albumID",
          "type": "opaque-ID",
          "required": true
        },
        {
          "name": "albumTitle",
          "type": "text",
          "required": true
        },
        {
          "name": "orderedAssetIDs",
          "type": "ordered-ID-list",
          "required": true,
          "min": 4,
          "max": 4
        },
        {
          "name": "confirmedAt",
          "type": "instant-with-offset",
          "required": true
        },
        {
          "name": "formatVersion",
          "type": "integer",
          "required": true,
          "allowed_values": [
            1
          ]
        }
      ],
      "constraints": [
        "空IDと重複なし",
        "画像と編集中の選択を含めない",
        "未知版は拒否"
      ]
    },
    {
      "name": "TargetFolderSettings",
      "owner": "SelectionPersistence",
      "description": "対象フォルダ設定",
      "attributes": [
        {
          "name": "settingsID",
          "type": "opaque-ID",
          "required": true,
          "unique": true
        },
        {
          "name": "folderIDs",
          "type": "ID-set",
          "required": true,
          "default": []
        },
        {
          "name": "formatVersion",
          "type": "integer",
          "required": true,
          "allowed_values": [
            1
          ]
        }
      ],
      "constraints": [
        "空ID禁止",
        "有効なIDのみ画面へ復元、原本は自動変更しない"
      ]
    }
  ],
  "relationships": [
    {
      "from": "WorkflowState",
      "to": "CommittedSelection",
      "direction": "immutable-copy",
      "cardinality": "1 to 0..1"
    },
    {
      "from": "WorkflowState",
      "to": "EditingSelection",
      "direction": "coordinates",
      "cardinality": "1 to 1"
    },
    {
      "from": "EditingSelection",
      "to": "TargetFolderSettings",
      "direction": "restored-copy",
      "cardinality": "1 to 0..1"
    }
  ]
}
```

IDは不透明文字列、名称は識別に使わない。formatVersionは保存schemaVersionに対応。退避ファイルは破損原本を保護する技術的な保管物で、選択履歴や新しい利用者向けエンティティではない。

