# U1 データモデル

根拠: [構成要素](../../../inception/domain-design/components.md)、[内部契約](../../../inception/contract-design/contract-summary.md)、[要件](../../../inception/requirements-analysis/requirements.md)。本書の論理形がデータの正本。IDの外部参照は所有権の移動を意味しない。

```yaml
{
  "entities": [
    {
      "name": "PresentationContext",
      "owner": "PickerPresentation",
      "description": "表示だけの状態。永続化しない。",
      "attributes": [
        {
          "name": "viewID",
          "type": "opaque-ID",
          "required": true,
          "unique": true
        },
        {
          "name": "focusedItemID",
          "type": "optional-ID",
          "required": false,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "activeRegion",
          "type": "folder|album|photo",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "expandedFolderIDs",
          "type": "ID-set",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        }
      ],
      "constraints": [
        "表示だけの状態。永続化しない。"
      ]
    },
    {
      "name": "EditingSelection",
      "owner": "SelectionWorkflow",
      "description": "写真0〜4件、重複なし。アルバムなしなら写真0件。選択可能な写真だけ追加。",
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
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "activeAlbumID",
          "type": "optional-ID",
          "required": false,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "orderedAssetIDs",
          "type": "ordered-ID-list",
          "required": true,
          "unique": false,
          "constraints": "重複なし、EditingSelectionは0〜4、CommittedSelectionは4"
        },
        {
          "name": "availability",
          "type": "assetID-to-availability",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "revision",
          "type": "nonnegative-integer",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        }
      ],
      "constraints": [
        "写真0〜4件、重複なし。アルバムなしなら写真0件。選択可能な写真だけ追加。"
      ]
    },
    {
      "name": "WorkflowState",
      "owner": "SelectionWorkflow",
      "description": "編集の所有者はEditingSelection。確定済みの写しは保存成功後にだけ更新。",
      "attributes": [
        {
          "name": "workflowID",
          "type": "opaque-ID",
          "required": true,
          "unique": true
        },
        {
          "name": "authorization",
          "type": "notDetermined|authorized|denied|restricted|otherUnsupported",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "loadState",
          "type": "idle|loading|ready|empty|failed",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "saveState",
          "type": "idle|validating|saving|saved|failed",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "restoreState",
          "type": "notStarted|deferredToU2",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "lastCommittedSnapshot",
          "type": "optional-CommittedSelection-copy",
          "required": false,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "error",
          "type": "optional-typed-failure",
          "required": false,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "requestGeneration",
          "type": "nonnegative-integer",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        }
      ],
      "constraints": [
        "編集の所有者はEditingSelection。確定済みの写しは保存成功後にだけ更新。"
      ]
    },
    {
      "name": "LibraryFolder",
      "owner": "LibraryAccess",
      "description": "IDは不透明文字列。名称が一致しても統合しない。循環は訪問済みIDで打ち切る。",
      "attributes": [
        {
          "name": "folderID",
          "type": "opaque-ID",
          "required": true,
          "unique": true
        },
        {
          "name": "title",
          "type": "text",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "parentFolderID",
          "type": "optional-ID",
          "required": false,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "childFolderIDs",
          "type": "ordered-ID-list",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "albumIDs",
          "type": "ordered-ID-list",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        }
      ],
      "constraints": [
        "IDは不透明文字列。名称が一致しても統合しない。循環は訪問済みIDで打ち切る。"
      ]
    },
    {
      "name": "LibraryAlbum",
      "owner": "LibraryAccess",
      "description": "写真の相対順序を保存し、日時で再ソートしない。",
      "attributes": [
        {
          "name": "albumID",
          "type": "opaque-ID",
          "required": true,
          "unique": true
        },
        {
          "name": "title",
          "type": "text",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "parentFolderID",
          "type": "optional-ID",
          "required": false,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "orderedAssetIDs",
          "type": "ordered-ID-list",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        }
      ],
      "constraints": [
        "写真の相対順序を保存し、日時で再ソートしない。"
      ]
    },
    {
      "name": "LibraryAsset",
      "owner": "LibraryAccess",
      "description": "画像本体とは分離。日時欠損は順序に影響しない。",
      "attributes": [
        {
          "name": "assetID",
          "type": "opaque-ID",
          "required": true,
          "unique": true
        },
        {
          "name": "creationDate",
          "type": "optional-instant",
          "required": false,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "mediaKind",
          "type": "photo",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "pixelWidth",
          "type": "nonnegative-integer",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "pixelHeight",
          "type": "nonnegative-integer",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        }
      ],
      "constraints": [
        "画像本体とは分離。日時欠損は順序に影響しない。"
      ]
    },
    {
      "name": "ImageRequest",
      "owner": "ImageAccess",
      "description": "写真・用途・世代と要求IDを紐付ける。通信許可への切替は禁止。",
      "attributes": [
        {
          "name": "requestID",
          "type": "opaque-ID",
          "required": true,
          "unique": true
        },
        {
          "name": "assetID",
          "type": "ID",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "displayPurpose",
          "type": "grid|selectionTray|validation",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "targetSize",
          "type": "positive-pixel-pair",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "generation",
          "type": "nonnegative-integer",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "state",
          "type": "pending|preview|final|unavailable|failed|cancelled",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        }
      ],
      "constraints": [
        "写真・用途・世代と要求IDを紐付ける。通信許可への切替は禁止。"
      ]
    },
    {
      "name": "ImageResult",
      "owner": "ImageAccess",
      "description": "画像または失敗結果。画像は永続化しない。取消済み応答は採用しない。",
      "attributes": [
        {
          "name": "resultID",
          "type": "opaque-ID",
          "required": true,
          "unique": true
        },
        {
          "name": "requestID",
          "type": "ID",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "assetID",
          "type": "ID",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "generation",
          "type": "nonnegative-integer",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "image",
          "type": "optional-transient-image",
          "required": false,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "quality",
          "type": "preview|final",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "failureReason",
          "type": "optional-typed-failure",
          "required": false,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        }
      ],
      "constraints": [
        "画像または失敗結果。画像は永続化しない。取消済み応答は採用しない。"
      ]
    },
    {
      "name": "TargetFolderSettings",
      "owner": "SelectionPersistence",
      "description": "空集合可。保存形式のschemaVersionを論理属性formatVersionへ対応づける。",
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
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "formatVersion",
          "type": "positive-integer",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        }
      ],
      "constraints": [
        "空集合可。保存形式のschemaVersionを論理属性formatVersionへ対応づける。"
      ]
    },
    {
      "name": "CommittedSelection",
      "owner": "SelectionPersistence",
      "description": "順序付き重複なし4件。設定とは別レコード。画像と編集中状態を含めない。",
      "attributes": [
        {
          "name": "selectionID",
          "type": "opaque-ID",
          "required": true,
          "unique": true
        },
        {
          "name": "albumID",
          "type": "ID",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "albumTitle",
          "type": "text",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "orderedAssetIDs",
          "type": "ordered-ID-list",
          "required": true,
          "unique": false,
          "constraints": "重複なし、EditingSelectionは0〜4、CommittedSelectionは4"
        },
        {
          "name": "confirmedAt",
          "type": "instant-with-offset",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        },
        {
          "name": "formatVersion",
          "type": "positive-integer",
          "required": true,
          "unique": false,
          "constraints": "型に従う。IDは正規化しない。"
        }
      ],
      "constraints": [
        "順序付き重複なし4件。設定とは別レコード。画像と編集中状態を含めない。"
      ]
    }
  ],
  "relationships": [
    {
      "from": "LibraryFolder",
      "to": "LibraryFolder",
      "cardinality": "0..1 parent / 0..many children",
      "direction": "parent-to-child"
    },
    {
      "from": "LibraryFolder",
      "to": "LibraryAlbum",
      "cardinality": "1 / 0..many",
      "direction": "folder-to-album"
    },
    {
      "from": "LibraryAlbum",
      "to": "LibraryAsset",
      "cardinality": "many / many ordered",
      "direction": "album-to-asset"
    },
    {
      "from": "EditingSelection",
      "to": "LibraryAlbum",
      "cardinality": "1 / 0..1",
      "direction": "ID-reference"
    },
    {
      "from": "EditingSelection",
      "to": "LibraryAsset",
      "cardinality": "1 / 0..4 ordered",
      "direction": "ID-reference"
    },
    {
      "from": "ImageRequest",
      "to": "ImageResult",
      "cardinality": "1 / 0..many",
      "direction": "request-to-results"
    },
    {
      "from": "ImageRequest",
      "to": "LibraryAsset",
      "cardinality": "many / 1",
      "direction": "ID-reference"
    },
    {
      "from": "CommittedSelection",
      "to": "LibraryAsset",
      "cardinality": "1 / 4 ordered",
      "direction": "ID-reference"
    },
    {
      "from": "CommittedSelection",
      "to": "LibraryAlbum",
      "cardinality": "many / 1",
      "direction": "ID-reference"
    }
  ]
}
```

10モデルの所有者は上流から変更しない。任意属性の既定値はなし、集合とリストの初期値は空、世代とrevisionは0。保存版は1。名称は空でもIDを維持し画面では「名称なし」と補う。日時の表示は端末の地域設定に従うが保存は時点を失わない。復元用のデータ形は備え、復元の全経路はU2で完成する。

