# U1 業務規則

`../../../inception/requirements-analysis/requirements.md`と`../../../inception/user-stories/stories.md`を入力とし、YAMLを規則の正本とする。

```yaml
rules:
  - id: BR1.1
    statement: 有効な4枚と記事同一性を保つ
    category: validation
    applies_to: article start
    trigger: 開始または再開要求
    logic: IF 確定選択が有効 THEN 写真ID順序と当時名称を写す。同一選択に記事があれば同じ記事を開く。再確定候補や複数候補でU2の判断画面が必要なら新規作成せず案内する。
    violation_behaviour: 不正選択または読込失敗を理由付きで返し、既存記事を変更しない
    source: [FR1, FR2, FR3, NFR2]
  - id: BR1.2
    statement: 自由本文と写真の対応を保持する
    category: constraint
    applies_to: article content
    trigger: 編集・保存・読込
    logic: IF 本文を入力 THEN 空欄・改行・日本語・絵文字・引用符を保持し、4件の本文IDはsourceの順序へ一致させる。再開時に初期候補を再適用しない。
    violation_behaviour: 対応不正を保存せず入力を保持し項目を案内
    source: [FR4, FR10]
  - id: BR1.3
    statement: 明示保存のみを正本へ確定する
    category: policy
    applies_to: article persistence and editor
    trigger: 新規作成操作または手動保存
    logic: IF 新規作成 THEN 骨組みを明示作成し初期保存版を1とする。IF 編集後の手動保存 THEN 入力の固定写しを保存し、成功後だけ保存済みを表示。同一内容の保存では版を増やさない。保存中に進んだ編集は未保存のまま。
    violation_behaviour: 自動保存をせず、保存失敗は入力と旧正本を保持
    source: [FR5, NFR2]
  - id: BR1.4
    statement: 破損・未知版・外部変更・重複操作を保護する
    category: constraint
    applies_to: persistence boundary
    trigger: 読込または書込
    logic: IF 既存選択版1 THEN 読める。IF 欠損・破損・未知版・I/O失敗 THEN 区別して報告。IF 基準版/保存内容が変化 THEN conflict。IF 同じoperationIDと同じ入力の確定記録あり THEN 元の結果を返す。異入力のID再利用は拒否。新規projectIDは再試行で維持。
    violation_behaviour: 空記事と誤認せず未知版を上書きしない。未確定結果は照合し、盲目的再適用をしない
    source: [FR2, FR5, NFR2]
  - id: BR1.5
    statement: 未保存離脱は本人が選ぶ
    category: policy
    applies_to: navigation and quit
    trigger: 戻る・閉じる・終了・切替
    logic: IF 未保存 THEN 保存して離れる/保存せず離れる/編集継続を提示。保存して離れるは現作業内容の保存成功後だけ離れる。IF 保存中に新編集あり THEN 離れず再確認。破棄は作業コピーだけ。
    violation_behaviour: 失敗・取消・曖昧な閉じ方では離れず入力を保持
    source: [FR6, NFR2, NFR4]
  - id: BR1.6
    statement: 写真の取得不能と文章の継続を分離する
    category: policy
    applies_to: open article and image retry
    trigger: 再開・権限変更・写真取得結果
    logic: IF 写真が不在・未認可・ローカルなし THEN 文章読込/編集/保存は続け、写真番号と判明した理由だけを表示する。原因不明をiCloudと断定しない。再試行は新requestIDで最新結果だけ反映。
    violation_behaviour: 本文や順序を消さず通信へ切替えない。コピーの最終接続はU3で完成
    source: [FR7, NFR1, NFR2]
  - id: BR1.7
    statement: 元写真非変更で記事用画像を取得する
    category: constraint
    applies_to: image conversion
    trigger: 画像1枚検証
    logic: IF 取得可能 THEN 現在の編集と回転を反映した静止画をsRGB JPEG品質0.9・長辺2560以下・拡大なしにし、不要元メタデータを移さない。全要求は通信禁止、変更APIを呼ばず、512px表示用を代用しない。
    violation_behaviour: 取得不能を失敗で返し写真アプリで事前取得して再試行する案内。元写真と記事は保持
    source: [FR14, NFR1, NFR7]
  - id: BR1.8
    statement: 検証画像は保存済み固定内容から別出力する
    category: policy
    applies_to: single image probe
    trigger: 検証出力操作
    logic: IF 未保存 THEN 保存を求め成功後の写しを固定。先頭写真を利用者選択先の別フォルダへ1枚だけ出す。名前は内部生成、既存物を上書きせず、画像1枚の検証出力と明示する。
    violation_behaviour: 保存失敗・保存取消・保存先取消なら画像ジョブを開始しない。4枚の記事セット成功と表示しない
    source: [FR13, FR15, FR17, NFR2]
  - id: BR1.9
    statement: 取消・失敗と確定成功を単一終端へ収束させる
    category: constraint
    applies_to: image request and probe
    trigger: 取消・期限・遅延応答・書込結果
    logic: IF 未確定で取消/失敗 THEN 当該一時物のみ片付けて失敗/取消。IF 確定済み THEN 成功を返す。取消受理だけで取消完了としない。二重開始は拒否し、終端後の遅延応答を破棄。
    violation_behaviour: cleanupFailureは残存場所を示し成功扱いしない。旧成果物/記事を保持
    source: [FR17, NFR2, NFR3]
  - id: BR1.10
    statement: 個人内容を通常診断へ出さない
    category: policy
    applies_to: all operations
    trigger: 進捗・失敗の診断
    logic: IF 診断する THEN 分類と処理段階を中心にし写真・本文・写真ID・人物・場所を記録しない。ユーザーへの必要な写真番号や保存先案内は通常ログと区別する。
    violation_behaviour: 秘匿情報を除去して報告し、原因を具体化できなければ不明と示す
    source: [NFR6]
  - id: BR1.11
    statement: 共通規則で保存内容の指紋を算出する
    category: calculation
    applies_to: ArticleWorkspace and later projection
    trigger: 保存・固定入力生成
    logic: IF 指紋を計算 THEN sourceとcontentだけを版付き共通算出処理で識別する。日時/保存版/projectIDは別照合項目。U2は同じ算出処理を利用し個別実装しない。
    violation_behaviour: 異なる指紋を同じ保存内容とせず、具体的符号化は設計仕様の固定順序に従う
    source: [FR13, FR16, NFR2]
```

| 規則 | 要点 |
|---|---|
| BR1.1–BR1.2 | 4枚の同一性と入力保持 |
| BR1.3–BR1.5 | 手動保存・競合/再試行・未保存離脱 |
| BR1.6–BR1.7 | 写真なし再開・通信/変更なしの画像取得 |
| BR1.8–BR1.9 | 保存済み固定入力の1枚検証と単一終端 |
| BR1.10–BR1.11 | 個人内容保護と共通指紋 |
