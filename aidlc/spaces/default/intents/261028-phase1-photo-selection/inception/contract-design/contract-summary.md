# ひとつづり — 内部契約

## 入力と範囲

[単位定義](../units-generation/unit-of-work.md)、[依存関係](../units-generation/unit-of-work-dependency.md)、[構成要素](../domain-design/components.md)、[要件](../requirements-analysis/requirements.md)、[確認済み方針](contract-design-questions.md)に基づく。U1〜U3は同じアプリの増分であり、以下はアプリ内の契約と内部保存形式。HTTPや外部公開APIは追加しない。

## Contracts

| # | Provider Unit | Consumer | Mechanism | Owner |
|---|---|---|---|---|
| C1 | U1 | U2; U3 | 型付き操作と表示状態 | SelectionWorkflow |
| C2 | U1 | U2; U3 | 非同期の認可・ライブラリ問合せ結果 | LibraryAccess |
| C3 | U1 | U2; U3 | 取消可能な画像要求・結果通知 | ImageAccess |
| C4 | U1 | U2; U3 | 非同期の読込み・保存と版付き内部形式 | SelectionPersistence |

U3→U2の依存はC1の完全化された失敗・復元状態、C4の結果を表示に使う関係。U3→U1はC1〜C3の基本操作・画像を利用する関係。U2はU1の契約を完全化し、互換性を保つ。提供単位と論理的な所有者を区別し、U2で同名の別所有者を増やさない。

## 共通モデルと結果

IDは不透明な識別子として扱い、名称を主キーにしない。操作結果は成功・取消・失敗を区別する。取消は保存成功でも通常エラーでもない。内部の低水準エラー文字列をそのまま画面へ出さず、種別と原因情報から日本語案内へ変換する。以下の仕様はSwiftの公開型・プロトコルへ実装時に対応づける意味上の形式であり、これ自体を実行するDSLではない。

```yaml
shared-schema: hitotsuzuri-internal-v1
identifier: opaque-string
request-context:
  requestID: opaque-string
  generation: nonnegative-integer
  albumID: optional-opaque-string
result:
  cases: [success, cancelled, failure]
  failure-kinds:
    - authorizationDenied
    - authorizationRestricted
    - libraryUnavailable
    - invalidReference
    - imageUnavailable
    - ioFailure
    - corruptData
    - unsupportedVersion
    - timedOut
```

失敗種別は表示判断用。retryableという単一の真偽だけで自動再試行しない。書込み失敗は本人操作で再試行、無効参照・画像準備は案内に従う再起動、取消は古い表示を採用しない。細かなOSエラーとの対応はFunctional Designで定める。

## C1 選択進行と表示

```yaml
contract: C1
version: 1
owner: SelectionWorkflow
caller: PickerPresentation
operations:
  - name: start
    input: []
    effect: 権限を確認し、許可があれば設定と確定内容を読み込んで検証
  - name: requestAuthorization
    input: [userIntent]
    effect: 本人操作による許可要求
  - name: setTargetFolders
    input: [folderIDs]
    effect: 対象内アルバムを再構築し編集選択を整合
  - name: selectAlbum
    input: [albumID]
    effect: 別アルバムなら編集写真をクリアし要求世代を更新
  - name: toggleAsset
    input: [assetID]
    effect: 取得可能な写真を追加または解除、重複なし・最大4枚
  - name: confirm
    input: [userIntent]
    effect: 編集を固定して参照と画像可否を検証し、保存成功後に確定表示
  - name: retrySave
    input: [userIntent]
    effect: 保持した編集内容を改めて検証し保存
presentation-snapshot:
  fields: [authorization, targetFolderIDs, folders, albums, activeAlbumID, orderedAssets, imageStates, orderedSelectedIDs, lastCommittedSelection, loadState, saveState, restoreState, error, canConfirm]
  mutations: provider-only
  publish: UI実行コンテキストで一貫した読み取り用状態を公開
```

保存中の入力変更と再確定は拒否し、進行表示を維持する。拒否した入力を後で勝手に実行する待ち行列は持たない。`canConfirm`は4枚・取得可能・保存中でない等から提供側が導出し、Viewで別のルールを作らない。別アルバムとフォルダ変更はFR5に従う。UI用のフォーカス・領域展開はPickerPresentationが所有する。

## C2 認可・階層・写真の参照

```yaml
contract: C2
version: 1
owner: LibraryAccess
caller: SelectionWorkflow
operations:
  - name: authorizationStatus
    input: []
    output: [notDetermined, authorized, denied, restricted, otherUnsupported]
  - name: requestAuthorization
    input: []
    output: authorization-status
  - name: fetchHierarchy
    input: [request-context]
    output: folder-and-album-metadata
  - name: fetchAssets
    input: [albumID, request-context]
    output: ordered-photo-metadata
  - name: validateReferences
    input: [folderIDs, albumID, orderedAssetIDs, request-context]
    output: validation-report
validation-report:
  fields: [albumExists, albumInTargetFolders, missingAssetIDs, nonMemberAssetIDs, resolvedOrderedAssetIDs]
invariants:
  - システム写真ライブラリ1つだけを参照
  - 権限未許可時は取得しない
  - 写真分類のみを返し、アルバム内の写真相対順を保持
  - ID再取得時も入力の選択順に戻して返す
  - ライブラリ変更操作を公開しない
```

メタデータ取得の応答にも要求世代を付け、利用側が現在世代と一致する場合だけ採用する。PhotoKit内部で取消不能な同期処理があっても結果の不採用は保証する。アルバム順とPhotos上の並びの一致は実機検証対象で、未成立なら無断で日時ソートへ変更しない。

## C3 画像要求

```yaml
contract: C3
version: 1
owner: ImageAccess
caller: SelectionWorkflow
request:
  fields: [assetID, displayPurpose, targetPixelSize, request-context]
  networkAccessAllowed: false
  return: cancellation-handle
response:
  fields: [requestID, assetID, generation, quality, image, outcome]
  quality: [preview, final]
  outcome: [image, unavailable, cancelled, failure]
operations:
  - requestImage
  - cancelRequest
  - releaseUnneededImages
```

複数回の画像応答が来ても要求IDと世代で識別し、取消・切替・セル再利用後に別写真へ表示しない。最終成功の後に来た低品質応答で表示を劣化させない。取消は低水準APIへの取消要求と以後の結果破棄で成立させる。画像取得可否の判断に必要な品質とローカル成功条件、タイムアウト・保持上限は後続設計で具体化する。取消・タイムアウトで通信許可へ切り替えない。

## C4 設定と確定内容の永続化

```yaml
contract: C4
version: 1
owner: SelectionPersistence
caller: SelectionWorkflow
operations:
  - name: loadSettings
    output: [missing, valid-settings, corruptData, unsupportedVersion, ioFailure]
  - name: saveSettings
    input: [target-folder-settings]
    output: [success, ioFailure, unsupportedVersion]
  - name: loadCommittedSelection
    output: [missing, valid-selection, corruptData, unsupportedVersion, ioFailure]
  - name: saveCommittedSelection
    input: [committed-selection, requestID]
    output: [commit-receipt, ioFailure, unsupportedVersion]
target-folder-settings:
  schemaVersion: 1
  fields: [folderIDs]
committed-selection:
  schemaVersion: 1
  fields: [selectionID, albumID, albumTitle, orderedAssetIDs, confirmedAt]
  constraints:
    - orderedAssetIDsは重複のない4件
    - confirmedAtはタイムゾーンを失わない日時表現
    - 写真画像本体や編集中の選択は含めない
commit-receipt:
  fields: [requestID, committedSelection]
```

専用領域に保存し、確定内容と設定を別の論理レコードとして扱う。書込みは直列化し、失敗時に以前の確定内容を保持する。置換完了後にのみcommit-receiptを返す。操作開始時に検証した固定内容を渡し、完了時の受領IDと内容を照合する。保存成功の意味はアプリの永続化操作が完了したことであり、電源断や媒体故障まで保証するものではない。

破損・未対応版を検出した読込みは原本を自動上書きしない。未対応版は書込みも拒否し、対応版のアプリ等を確認する案内を出す。破損時は本人が新たな確定を明示した場合の原本退避と置換方法をFunctional Designで定め、単なる起動や設定変更では破損した確定レコードを置換しない。旧版移行は必要になった時に定義し、未知の版を現行版として読み替えない。

## 復元・保存の結合条件

読込み成功だけで保存済みとして表示せず、SelectionWorkflowが権限・フォルダ・アルバム所属・4枚と画像可否を検証する。1つでも欠損・取得不可なら写真全体をクリアし、有効なフォルダを残して案内する。保存担当の原本はその判定だけで削除しない。確定時検証はその時点の確認であり外部Photosとの原子的トランザクションではない。直後の外部変更は次回確定・復元時に検知する。

## 実行・タイムアウトと取消

UI状態の公開はUIの実行境界で行い、ファイルI/O・探索でUIを不要に停止しない。Swiftの具体的なActor/Sendable設計はFunctional Designで検証する。画像・取得は一定時間で進行不能を案内し、その値と計測をNFR設計で確定する。OSの認可ダイアログで本人の回答を待つ時間には通常の取得タイムアウトを適用しない。保存処理は完了確認なしに成功とせず、タイムアウトしても裏で成功した処理を無制御に重複再試行しない。取消後の書込みの扱いは保存原子性と合わせて具体化する。

## Contract ownership rules

- C1〜C4は表の所有者が定義を保守し、U2/U3は同じ意味を利用する。
- 内部型の変更はすべての呼出し元・Fake・契約テストを同じ変更で更新する。追加フィールドは既存の意味を変えず、保存の未知フィールドは必要な既知項目が有効な場合に無視できる設計とする。
- 保存形式の破壊的変更はschemaVersionを上げ、移行方針とテストを伴う。未対応版を自動上書きしない。
- 試験は成功・取消・遅延・古い応答・保存失敗・未対応版・欠損を含める。実ライブラリの並び・権限・画像取得は本人の確認と区別する。

## Open questions

| Contract | Question | Blocks |
|---|---|---|
| C2 | PhotoKitでPhotosのアルバム順を再現できるか実機で確認 | U1の実機成立性確認 |
| C3 | 取得成功の品質条件、タイムアウト、保持上限と資源計測 | U1の画像実装、U3の性能判定 |
| C4 | 保存形式の具体的な日時・ファイル配置、置換/退避と中断の手順 | U1の永続化実装、U2の異常系 |
| C1〜C4 | Swiftの実行境界と取消伝播の具体的な型・テスト | 各単位のFunctional Design/Code Generation |

上記は具体設計・検証事項であり、既知の不成立を承認済みとするものではない。Constructionの対象コード着手前に該当設計と計画を確認する。
