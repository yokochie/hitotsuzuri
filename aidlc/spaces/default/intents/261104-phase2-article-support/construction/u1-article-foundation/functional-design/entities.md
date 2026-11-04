# U1 記事の論理データモデル

入力は`../../../inception/domain-design/components.md`、`../../../inception/contract-design/contract-summary.md`。以下のYAMLをデータ形状の正本とする。既存選択は読取参照で、記事とは別の正本。型は論理型であり、特定フレームワークの実装ではない。

```yaml
entities:
  - name: SelectionSnapshot
    description: 記事作成時の確定選択の不変な写し
    owner: ArticleWorkspace
    attributes:
      - {name: selectionID, type: opaque identifier, required: true, unique: false}
      - {name: albumID, type: opaque string, required: true, constraints: nonempty}
      - {name: albumTitle, type: text, required: true, default: empty}
      - {name: orderedAssetIDs, type: ordered opaque string collection, required: true, min: 4, max: 4, constraints: distinct nonempty values}
      - {name: confirmedAt, type: instant, required: true}
      - {name: selectionRevision, type: integer, required: true, allowed_values: [1], default: 1}
    constraints: 元選択を変更しない。写真IDは大文字小文字や先頭文字を正規化せず不透明値として保持。
  - name: ArticleContent
    description: 画像の取得可否に依存しない記事本文と撮影情報
    owner: ArticleWorkspace
    attributes:
      - {name: title, type: text, required: true, default: empty}
      - {name: introduction, type: text, required: true, default: empty}
      - {name: photoTexts, type: ordered assetID and text pairs, required: true, min: 4, max: 4}
      - {name: closing, type: text, required: true, default: empty}
      - {name: shootingDate, type: optional valid Gregorian calendar day, required: false, default: absent}
      - {name: dateCandidateState, type: enum, required: true, allowed_values: [absent, candidate, confirmed], default: absent}
      - {name: location, type: text, required: true, default: empty}
      - {name: equipment, type: text, required: true, default: empty}
      - {name: film, type: text, required: true, default: empty}
      - {name: people, type: text, required: true, default: empty}
    constraints: photoTextsのIDと順序はSelectionSnapshotと一致。日付なしならstate=absent。自由本文の文字と改行は保存で変換しない。
  - name: ArticleProject
    description: 保存済み記事の唯一の正本
    owner: ArticleWorkspace
    attributes:
      - {name: schemaVersion, type: positive integer, required: true, allowed_values: [1]}
      - {name: projectID, type: opaque UUID, required: true, unique: true}
      - {name: source, type: SelectionSnapshot, required: true}
      - {name: sourceSelectionIDs, type: identifier set, required: true, constraints: includes original source selectionID}
      - {name: content, type: ArticleContent, required: true}
      - {name: savedRevision, type: integer, required: true, min: 1}
      - {name: fingerprint, type: versioned digest, required: true}
      - {name: createdAt, type: instant, required: true}
      - {name: updatedAt, type: instant, required: true}
    constraints: sourceは作成後不変。U1では新しい選択IDの関連追加を行わない。空記事と読込失敗は別の結果。
  - name: SaveOperation
    description: 再試行の照合に必要な内部記録
    owner: ArticleWorkspace
    attributes:
      - {name: operationID, type: opaque UUID, required: true, unique: true}
      - {name: projectID, type: opaque UUID, required: true, references: ArticleProject.projectID}
      - {name: inputDigest, type: digest of complete operation input, required: true}
      - {name: expectedRevision, type: optional integer, required: false}
      - {name: resultRevision, type: integer, required: true, min: 1}
      - {name: resultSnapshot, type: immutable saved article value, required: true}
      - {name: previousOperation, type: optional operation reference, required: false, references: SaveOperation.operationID}
    constraints: 変更結果と操作記録は同一の確定境界。操作結果は再起動後も照合可能。入力指紋とは別に操作全体を識別する。
  - name: ArticleEditSession
    description: 保存前の作業コピーと操作状態
    owner: ArticlePresentation
    attributes:
      - {name: sessionID, type: opaque UUID, required: true, unique: true}
      - {name: projectID, type: opaque UUID, required: true, references: ArticleProject.projectID}
      - {name: baseSavedArticle, type: optional saved article snapshot, required: false}
      - {name: workingContent, type: ArticleContent, required: true}
      - {name: editGeneration, type: integer, required: true, min: 0, default: 0}
      - {name: saveState, type: enum, required: true, allowed_values: [newUnsaved, clean, dirty, saving, failed, conflict]}
      - {name: activeSave, type: optional operation and generation snapshot, required: false}
      - {name: pendingNavigation, type: optional navigation intent, required: false}
    constraints: 正本ではない。保存成功後もworkingContentが保存した内容と異なればdirty。基準記事の更新は同じsessionとoperationの結果だけ。
  - name: SingleImageProbe
    description: 記事セットとは区別する画像1枚の検証ジョブ
    owner: ArticleDelivery
    attributes:
      - {name: requestID, type: opaque UUID, required: true, unique: true}
      - {name: article, type: immutable saved article snapshot, required: true}
      - {name: assetID, type: opaque string, required: true}
      - {name: destinationGrant, type: scoped user selected destination, required: true}
      - {name: state, type: enum, required: true, allowed_values: [selectingDestination, acquiring, converting, writing, committing, succeeded, failed, cancelling, cancelled, cleanupFailed]}
      - {name: finalLocation, type: optional local location, required: false}
      - {name: failure, type: optional classified failure and residual location, required: false}
    constraints: 先頭写真のみ。成功終端と確定後取消の扱いはfunctional-specを正とする。出力画像を記事の正本にしない。
relationships:
  - {from: ArticleProject, to: SelectionSnapshot, cardinality: one-to-one, direction: contains}
  - {from: ArticleProject, to: ArticleContent, cardinality: one-to-one, direction: contains}
  - {from: SaveOperation, to: ArticleProject, cardinality: many-to-one, direction: references}
  - {from: ArticleEditSession, to: ArticleProject, cardinality: many-to-one, direction: references}
  - {from: SingleImageProbe, to: ArticleProject, cardinality: many-to-one, direction: snapshots}
```

同じ名前や写真でも記事IDで区別する。参照先写真の消失は記事消去を意味しない。操作記録は重複適用防止の内部情報で、制作履歴画面や版復元機能を追加するものではない。物理保存の原子性・容量と内部記録の保護方法はNFR/Infrastructure Designで成立性を確認する。
