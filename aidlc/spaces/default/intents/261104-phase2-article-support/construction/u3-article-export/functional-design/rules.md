# U3 業務規則

## Sources
requirements.md FR7/FR12〜18、NFR1〜7、stories.md US1.4/1.6/1.7/1.8、contract-summary.md C2/C3。

## Rules
```yaml
rules:
  - id: BR3.1
    statement: コピーは現在入力か固定した完成内容かを区別する。
    category: policy
    applies_to: 本文コピー
    trigger: コピー操作
    logic: IF 編集画面 THEN 現在入力の投影だけを渡す。IF 完了画面 THEN そのジョブの固定本文だけを渡す。
    violation: clipboardFailureまたは入力不整合を表示し成功扱いにしない。未保存状態と記事は変えない。
    source: [FR7, FR12]
  - id: BR3.2
    statement: 保存成功した同一内容だけを出力する。
    category: validation
    applies_to: 固定入力と本文投影
    trigger: 出力開始
    logic: IF 未保存 THEN 保存の判断を求める。保存成功後に記事ID・保存版・写真順・指紋・設定を固定し、投影の指紋と照合する。
    violation: 保存失敗・取消・異入力・不正参照ではジョブを開始せず、入力と旧保存を保つ。
    source: [FR13, FR16]
  - id: BR3.3
    statement: 四枚の現在編集画像を通信せずに扱う。
    category: constraint
    applies_to: 画像取得と変換
    trigger: 一枚ごとの出力要求
    logic: IF 許可済みかつローカル取得可能 THEN 現在編集と向きを反映したsRGB JPEG品質0.9、長辺2560以下、非拡大、不要メタデータなしの結果を一枚ずつ生成する。
    violation: 対象番号と理由を示して失敗にする。表示用画像で代用せず、通信許可や元写真の変更をしない。
    source: [FR7, FR14, NFR1, NFR3]
  - id: BR3.4
    statement: 新規のジョブ専用フォルダだけへ生成する。
    category: authorization
    applies_to: 保存先と出力パス
    trigger: 保存先決定と全書込
    logic: IF 利用者の選択範囲と所有識別が有効 THEN 固定した安全な相対名だけを使い同じ親内の一時領域へ生成する。シンボリックリンク・領域外参照・同名完成物は拒否する。
    violation: permissionDenied・invalidReference・conflict等で停止し、既存完成物と記事を保つ。
    source: [FR15, FR17, NFR2]
  - id: BR3.5
    statement: 全一式の検証後だけ成功を確定する。
    category: validation
    applies_to: Markdown・画像・manifest
    trigger: 生成完了
    logic: IF article.md、manifest.json、images/01.jpgから04.jpgの四枚が固定入力・順序・相対参照と一致し全書込が完了 THEN 非置換の一括確定を行う。
    violation: 一枚欠落・途中書込・不一致では成功結果を返さず当該一時物だけを片付ける。
    source: [FR15, FR16, FR17]
  - id: BR3.6
    statement: 一つのジョブを二重に実行せず古い応答を採用しない。
    category: constraint
    applies_to: ジョブと進捗
    trigger: 開始・進捗・終端通知
    logic: IF 同一ID同入力 THEN 既存状態または照合結果を返す。同一ID異入力を拒否する。実行中は対象の編集・保存・切替と二重開始を抑止し、現jobIDの通知だけを反映する。
    violation: 旧通知を破棄し、再出力には新IDを求める。固定入力は変更しない。
    source: [FR13, FR17]
  - id: BR3.7
    statement: 取消・期限を単一の終端へ収束させる。
    category: policy
    applies_to: ジョブの取消
    trigger: 取消要求または期限到達
    logic: IF 確定前 THEN 新規処理を止め、要求取消と資源解放と一時物片付けの結果を待って終端を返す。IF 確定済み THEN 成功結果を返す。
    violation: 取消受付を取消完了と表示しない。片付け不能はcleanupFailureと残存案内を返す。数値の期限・予算はNFR設計で確定する。
    source: [FR17, NFR3]
  - id: BR3.8
    statement: 異常終了後は権限と所有と一式を再照合する。
    category: policy
    applies_to: 回復記録
    trigger: 再起動または結果不明
    logic: IF 記録が未完 THEN 自動成功にせず案内する。利用者が保存先を再選択して同一親と所有を確認できた場合だけ、完成一式を照合または当該一時物の片付けを行う。
    violation: 不在・未知版・外部変更・所有不明・権限なしでは触らず案内する。旧完成物や別ジョブは削除しない。
    source: [FR17, NFR2, NFR6]
  - id: BR3.9
    statement: 本文・管理情報・手動受渡しを分ける。
    category: constraint
    applies_to: 本文投影と診断
    trigger: コピー・書出し・記録
    logic: IF コピー THEN U2のプレーンテキストのみを渡す。manifestと画像パスは含めない。自由文字はデータとして保持し、空白だけの撮影項目は省略する。通常ログは分類と番号のみとする。
    violation: 任意文字列を命令にせず、本文・写真ID・人物・場所・パスを通常ログや自動送信へ出さない。
    source: [FR12, FR16, NFR6]
  - id: BR3.10
    statement: Finder表示は出力成功と別の結果とする。
    category: policy
    applies_to: 完成フォルダ表示
    trigger: Finderで開く
    logic: IF 完成した結果のフォルダが存在し表示操作が成功 THEN 表示成功とする。表示できなくても完成した出力結果は取り消さない。
    violation: 移動・削除・表示失敗を案内し、存在しない場所を開いたと表示しない。
    source: [FR18]
  - id: BR3.11
    statement: 失敗後も文章を継続し各操作へキーで到達する。
    category: policy
    applies_to: 出力操作の画面接続
    trigger: 処理状態の変化
    logic: IF 処理中 THEN 進捗と取消を文字で示す。IF 終端 THEN 制御を解放し入力を保持して元操作へ焦点を戻す。コピー失敗・画像不能も文章保存を妨げない。
    violation: 色だけの状態や成功の誤表示をしない。VoiceOver追加検証は本人指定の対象外。
    source: [FR7, FR17, NFR4]
  - id: BR3.12
    statement: 実機確認と自動試験を区別する。
    category: policy
    applies_to: 出力品質とnote受渡し
    trigger: 完了判定
    logic: IF 自動試験が成功 THEN その検証範囲だけを記録する。実写真・編集・回転・色・位置情報除去・保存先権限・note貼付けと画像順は本人の結果を別に記録する。
    violation: 未確認を成功にせず、自動投稿やmanifestの外部送信を行わない。
    source: [NFR5, NFR7]
```

## Summary
| 規則 | 要点 |
|---|---|
| BR3.1〜3.3 | コピー元の区別、保存固定、通信しない四枚取得 |
| BR3.4〜3.5 | 保存先の限定と一式の非置換確定 |
| BR3.6〜3.8 | 二重開始・取消・異常終了の照合 |
| BR3.9〜3.12 | 本文と管理情報の分離、Finder、入力継続、本人確認 |
