# Phase2 接続仕様

## 入力と適用範囲
`../units-generation/unit-of-work.md`・`unit-of-work-dependency.md`、`../domain-design/components.md`、`../requirements-analysis/requirements.md`、本段階の確認済み回答を基準とする。3つの依存辺をアプリ内のSwiftプロトコルと共有値の仕様として定義する。以下のYAMLは実装言語に依存しないshared-schema仕様で、製品コードや実行済み検証ではない。HTTP・外部公開API・サーバー・メッセージ基盤は追加しない。

## Contracts
| # | Provider Unit | Consumer | Mechanism | Owner |
|---|---|---|---|---|
| C1 | U1 u1-article-foundation | U2 u2-draft-experience | アプリ内async呼出し・shared-schema | U1（ArticleWorkspaceの基礎） |
| C2 | U1 u1-article-foundation | U3 u3-article-export | アプリ内async呼出し・shared-schema | U1（保存済み固定入力・記事画像・出力先基礎） |
| C3 | U2 u2-draft-experience | U3 u3-article-export | 純粋な本文投影とアプリ内操作接続 | U2（Workspaceの本文規則とPresentationの調整） |

各仕様の所有はコード差分の提供者であり、データ正本の所有を変更しない。ArticleProjectはArticleWorkspace、未保存編集はArticlePresentation、画像要求はArticleImages、ジョブとmanifestはArticleDeliveryが所有する。U3の実装はU2/U1の公開値だけを使い、保存原本を直接書き換えない。

## 共通の値・エラー・版
```yaml
format: shared-schema
contract_version: 1
types:
  ProjectID: opaque UUID
  SelectionID: opaque UUID
  OperationID: opaque UUID
  AssetID: opaque nonempty string
  Revision: nonnegative integer
  InputFingerprint: deterministic digest of canonical saved content
  CalendarDay:
    fields: {year: integer, month: integer, day: integer}
    validation: valid Gregorian date; no time or timezone
  PhotoText:
    fields: {assetID: AssetID, text: string}
  ArticleContent:
    fields:
      title: string
      introduction: string
      photoTexts: ordered PhotoText collection
      closing: string
      shootingDate: optional CalendarDay
      dateCandidateState: absent or candidate or confirmed
      location: string
      equipment: string
      film: string
      people: string
  SourceSnapshot:
    fields:
      selectionID: SelectionID
      albumID: opaque nonempty string
      albumTitle: string
      orderedAssetIDs: ordered collection of four distinct AssetID values
      confirmedAt: instant
      selectionRevision: Revision
  SavedArticle:
    fields:
      projectID: ProjectID
      source: SourceSnapshot
      sourceSelectionIDs: collection of SelectionID
      content: ArticleContent
      savedRevision: Revision
      fingerprint: InputFingerprint
      createdAt: instant
      updatedAt: instant
  Failure:
    cases:
      - invalidInput
      - missing
      - corruptData
      - unsupportedVersion
      - conflict
      - permissionDenied
      - assetUnavailable
      - invalidReference
      - capacity
      - timedOut
      - cancelled
      - ioFailure
      - cleanupFailure
      - clipboardFailure
      - finderFailure
    details: classification plus optional field or photo index; no private content in ordinary logs
```

ArticleContentのphotoTextsはSourceSnapshotの写真IDと順序に一致し、未知・重複・欠落を検証する。自由文字はそのままデータとして扱い、空本文を許容する。日時は記録用の時点、撮影日は年月日として区別する。CalendarDayの候補生成は2000〜2099年、手動修正可能な年の範囲はFunctional Designで確定する。

既存選択にはリビジョンがないため、記事へ取り込む最初のSourceSnapshotはselectionRevision=1とし、記事内の写真順を変えない今回範囲では固定する。再確定後に既存記事を再開すると、照合した新選択IDはsourceSelectionIDsへ明示的関連付けし、当初のsourceと記事ID・文章を保持する。現在の確定選択IDはsourceSelectionIDsで同じ記事へ到達可能にする。新規作成は別ProjectIDと初期リビジョンを持つ。

## C1 記事管理と編集の接続
```yaml
format: shared-schema
id: C1
version: 1
provider: u1-article-foundation
consumer: u2-draft-experience
operations:
  readCommittedSelection:
    input: none
    output: SourceSnapshot or Failure
    effects: read only; independent of successful preview image acquisition
  resolveArticle:
    input: SourceSnapshot
    output: exact-linked article or matching candidates or new-article option
    matching: same albumID and orderedAssetIDs; no automatic overwrite on a new selectionID
  createArticle:
    input: {operationID: OperationID, source: SourceSnapshot, initialContent: ArticleContent}
    output: SavedArticle or Failure
    effects: creates a separate project; never changes selection storage
  openArticle:
    input: ProjectID
    output: SavedArticle or Failure
    effects: no PhotoKit success precondition
  listDrafts:
    input: none
    output: summaries with projectID, title, source albumTitle and updatedAt, plus per-item read failures
    ordering: updatedAt descending, then projectID ascending
  resumeWithSelection:
    input: {operationID: OperationID, projectID: ProjectID, expectedRevision: Revision, source: SourceSnapshot}
    output: SavedArticle or Failure
    effects: validates matching photos; records selection association without replacing text
  saveArticle:
    input: {operationID: OperationID, projectID: ProjectID, expectedRevision: Revision, content: ArticleContent}
    output: SavedArticle or Failure
    effects: compare revision and underlying stored content before replacing; increment savedRevision only on committed change
semantics:
  concurrency: serialize writes; conflict preserves both working input and last good stored article
  cancellation: observe before commit; after commit return committed success, not ambiguous cancellation
  repetition: same operationID with same input yields the original result; different input with reused ID fails
  retry: caller requests retry after reconciling uncertain outcome; never blindly repeats a write
  versioning: unknown persisted schemaVersion is read failure and must not be replaced
```

createArticleのSavedArticleは初期状態の永続化成功を意味する。初期内容は本人操作で作成した記事の骨組みであり、編集後の自動保存を許すものではない。初回作成に失敗した場合は新規の未保存作業内容を画面に保持し、保存成功と表示しない。記事を再開する際の候補照合・選択はPresentationが表示するが、既存の正本を新規扱いする判断はWorkspaceが読込結果で拒否する。

保存済み記事の一覧では1件の破損を「全て0件」とせず、正常候補と読込失敗の存在を区別する。重複OperationIDの記録・不確定結果の照合をどの永続機構で実現するかはFunctional Designで定める。アプリ再起動後も、対象記事・保存版・指紋を照合して同じ変更を二重適用しない。新規作成のProjectIDは書込前に発行して再試行で維持する。

## C2 固定記事入力・画像・保存先の基礎
```yaml
format: shared-schema
id: C2
version: 1
provider: u1-article-foundation
consumer: u3-article-export
types:
  ImageSettings:
    fields: {colorSpace: sRGB, encoding: JPEG, quality: 0.9, maximumLongEdge: 2560, allowUpscale: false}
  SavedExportInput:
    fields: {article: SavedArticle, settings: ImageSettings}
    semantics: immutable copy of a successful save, not a mutable editor reference
  DestinationGrant:
    fields: {grantID: opaque identifier, selectedDirectory: local URL}
    semantics: access valid only for user-selected destination and grant lifetime
  ImageResult:
    fields: {requestID: OperationID, assetID: AssetID, jpegBytes: immutable bytes, width: positive integer, height: positive integer}
operations:
  requestArticleImage:
    input: {requestID: OperationID, assetID: AssetID, settings: ImageSettings, deadline: monotonic deadline}
    output: ImageResult or Failure
    progress: requestID, stage, optional completed fraction
    requirements: current edit and orientation; no network; no mutation; omit unnecessary source metadata
  cancelImage:
    input: OperationID
    output: cancellation request acknowledged
    semantics: idempotent; terminal image result or failure still determines completion
  chooseDestination:
    input: none
    output: DestinationGrant or cancelled or Failure
  writeSingleImageProbe:
    input: {requestID: OperationID, image: ImageResult, destination: DestinationGrant}
    output: distinct probe result or Failure
    semantics: U1 integrated path; labeled one-image verification, never a four-image article success
semantics:
  terminal: exactly one final result per requestID; discard late responses after terminal or deadline
  retry: no automatic network fallback or retry; user initiates a new request after remediation
  resources: bounded active image conversion; deadline and budget fixed in NFR Requirements before code
  grant: release access on success, failure or cancellation; no persisted permission assumed
```

JPEG結果は出力用の変換完了後のデータであり、512px表示キャッシュを渡す型ではない。Presentationのプレビュー用取得は別の用途として同じ責務内で扱い、必要な解像度・バッファを用途で区別する。OSの元画像形式が取得できない場合はassetUnavailable等で返し、作り物やサムネイルで代用しない。

出力先の選択とアクセス開始/終了はArticleDeliveryの内部OS境界としてU1から導入し、U3が拡張する。URLの文字列だけでアクセス権を保証しない。元画像や保存先の名前から任意のパス・命令を組み立てず、ジョブ専用の安全なファイル名と相対パスを用いる。

## C3 本文投影と出力操作の接続
```yaml
format: shared-schema
id: C3
version: 1
provider: u2-draft-experience
consumer: u3-article-export
types:
  RenderedArticle:
    fields: {projectID: ProjectID, sourceFingerprint: InputFingerprint, plainText: string, markdown: string, imagePaths: ordered collection of four relative paths}
  ExportProgress:
    fields: {jobID: OperationID, stage: string, completedImages: integer, fraction: optional number}
  ExportResult:
    fields: {jobID: OperationID, projectID: ProjectID, savedRevision: Revision, selectionRevision: Revision, fingerprint: InputFingerprint, directory: local URL, fixedPlainText: string}
operations:
  renderArticle:
    input: {source: SourceSnapshot, content: ArticleContent}
    output: RenderedArticle or Failure
    effects: pure; no filesystem, clipboard, network or article writes
    structure: title, introduction, four photos with their text, closing, nonempty shooting memo
  prepareSavedExport:
    input: current edit session and user save decision
    output: SavedExportInput or cancelled or Failure
    effects: Presentation coordinates manual save through C1; Delivery never saves the article itself
  runExport:
    input: {jobID: OperationID, savedInput: SavedExportInput, rendered: RenderedArticle, destination: DestinationGrant}
    output: ExportResult or Failure
    provider_implementation: ArticleDelivery in U3 implements U2-defined action port
    progress: ExportProgress callback tied to jobID
  cancelExport:
    input: OperationID
    output: cancellation request acknowledged
  copyPlainText:
    input: text plus context identifying editor content or fixed export
    output: success or clipboardFailure
    provider_implementation: OS action in U3; pure text projection supplied by U2
  revealExport:
    input: successful ExportResult
    output: success or finderFailure
    provider_implementation: OS action in U3
```

C3はU2が宣言する投影・操作ポートをU3が利用/実装する境界である。設計上のPresentation→Deliveryの呼出しと、ビルド時のU3→U2の型依存を混同しない。U1は後続のU2型に依存せず、最小本文投影を備える。U2がArticleWorkspace内の投影規則を完成させ、U3はその規則を複製しない。U2単独のビルド・試験にはFake実装を使い、U3の実OS処理を必要としない。

### 出力の整合・取消・受渡し
- runExportはSavedExportInputのfingerprintとRenderedArticleのsourceFingerprintを検証し、異なる本文を混ぜない。renderArticleの指紋は、SavedArticleの指紋と同じ規則でsourceとcontentから算出する。保存日時・保存版など投影外のメタデータは指紋へ混ぜず、別項目で照合する。
- 実行中はPresentationが対象記事の編集・保存・切替を制御し、ジョブは固定値だけを参照する。出力側からWorkspaceへ保存の呼戻しをしない。
- 一時領域へ記事・画像4枚・manifestを生成し、相対画像参照・件数・ID/順序の対応が一致した後だけ、毎回別フォルダの成功結果を返す。既存フォルダの上書きはしない。
- manifestの共有形式版は1。manifestID、jobID、projectID、元選択IDと選択リビジョン、savedRevision、入力指紋、日時、順序写真ID、相対画像パス、articleRelativePathを出力と一致させる。本文コピーやnoteへの自動送信には含めない。
- 取消は確定前なら一時物を片付けcancelled、確定後ならその成功結果を返す。取消要求の到着だけで先に取消完了としない。片付け失敗はcleanupFailureで残存場所の案内を返し、成功扱いしない。
- 再起動後の未完ジョブは成功として表示しない。ジョブ専用一時物を識別して案内・片付けを行い、別ジョブ・旧成果物を削除しない。具体的な記録方式と確定の原子性はFunctional/NFR Designで検証する。
- 同じjobIDの二重開始は拒否または既存実行状態を返し、別の成果物を黙って複製しない。本人の再出力は新jobID・別フォルダ。成功応答が不明な場合は同じIDの結果を照合してから判断する。
- 編集画面のコピーは現在入力、完了画面のコピーはExportResult.fixedPlainText。コピー成功は保存成功ではない。Finder失敗は成果物の成功と分離して案内する。

## Contract Ownership and Compatibility
接続仕様版1は同じアプリ版を一括ビルドするための契約で、ローリング更新を約束しない。永続データのschemaVersion・manifest版・旧選択版は別に管理する。

- C1/C2はU1、C3はU2が提供仕様を所有し、U3は出力/OS実装を担当する。実装方法の差分は契約を破らない範囲で各責務が決める。
- フィールド追加はoptionalまたは既定値を持つ安全な形に限定し、読込側は既知schemaVersion内の未知フィールドを無視できるようにする。必須項目削除・意味変更は関係単位の合意、契約版/永続版の判断と移行試験を伴う。
- 未知の永続schemaVersionを、未知フィールドと混同して書込可能にしない。旧選択schemaVersion 1の読込試験を維持し、記事追加のために既存selection.jsonを無断変更しない。
- 契約試験は、値の往復、候補照合、版競合、保存取消の境界、固定内容の指紋一致、画像取消/期限、4枚の整合、二重開始、片付け失敗、コピー/Finder失敗を含める。実画像・Sandbox・note操作は本人確認として区別する。
- 権限なし・破損・未知版・競合・容量不足・取得不能・期限切れ・取消・I/Oの分類を失敗理由の日本語表示へ写し、通常ログへ本文・写真・人物・場所を記録しない。原因不明を具体原因と断定しない。

## Open Questions
| Contract | Question | Blocks |
|---|---|---|
| C1 | 記事保存の物理形式・操作ID/保存版照合・破損と外部変更の保護をFunctional Designで具体化する | U1のCode Generation |
| C2 | 画像取得/変換・期限・メモリ予算・Sandbox権限とアクセス寿命をNFR/Infrastructure Designで実証する | U1の実画像出力 |
| C3 | 一時物の確定・異常終了回復・同じジョブ結果照合の物理方式をFunctional/NFR Designで定める | U3のCode Generation |

本人の未回答はない。上記は契約の意味を変える未決定ではなく、実装前の成立性検証と具体化事項。実装計画のCI環境・検証コマンドの本人確認も維持する。
