# 品質評価と表示復帰の調査結果

## 静的品質
| 項目 | 評価 | 根拠 |
|---|---|---|
| 責務/型 | good | 選択・記事・画像・出力がprotocolと型で分離 |
| ファイル規模/結合 | fair | CoordinatorにOS・session・表示owner・出力・DEBUG計測が集中 |
| 保存安全性 | good | nofollow-any、fd相対、排他、digest、原子的確定、未知版保護 |
| 表示状態と操作 | fair | owner欠落/取消済み/未要求をwaitingへ潰し、有効なボタンがno-opになる |
| 試験範囲 | fair | 部品と保存/出力試験は豊富だが、出力から表示への復帰接続が欠ける |
| 診断 | fair | 個人文章を避ける分類ログはあるが、表示owner/要求発行を通常画面から判別できない |

## 確認できたコード上の成立経路
1. `ArticleAppCoordinator.swift:187–199` は新session IDの時だけPreviewsを生成してload Taskを開始する。同じsession IDなら189行でreturnする。
2. 出力の358–384行では、未保存時の最初の確認を通った後、374行でpreviewTask取消・Previews.cancel・previews=nilを実行する。previewSessionIDは変更しない。
3. この破棄後の容量拒否、保存/入力検証失敗、パネルでの保存先取消、画像取得失敗、出力処理取消、正常完了のいずれも、Coordinatorに表示ownerの再生成・再loadがない。最初の「保存して出力/取り消す」確認で取り消した場合は374行に到達しないため別扱い。
4. `ArticleView.swift:164` はpreviews=nilや番号state欠落をwaitingに置換する。171–175行のボタンはnilだけでは無効化されず、252行のretryPhotoはnilなら即return。nilではキーボードの再試行順にも含まれない（211行付近）。`ArticlePreviewView.swift:16–17` も同じwaiting fallbackを持つ。
5. `ArticleImageAccess.swift:62–67` のPreviews.cancelはstatesを空にし、retryはstates非空を条件とする。取消済みownerをそのままretryしても要求は発行しない。

この接続は「4枚とも取得待ち、再試行無反応」を生じ得る強いコード上の候補。ただし本人の不具合が出力後の同一sessionで発生したかは未観測で、実機の直接原因とは未確定。今回、再現試験は実行していない。

## Freshな下書き再開・Observation・取消順序
新プロセス、Pickerへ離脱して戻る、既存記事を再読込して新EditSessionをadoptする場合は新session IDとなり、CoordinatorはPreviews生成とloadへ進む。出力後の同一sessionの編集復帰とは経路が異なる。fresh再開だけで常に待ちになるとの事実はコードから確定できない。

CoordinatorとPreviewsはMainActor Observable、ArticleViewはCoordinatorをBindableで参照し、各画像stateを読む。ArticlePreviewViewも参照先statesを読む。実装に状態読取の接続はあり、annotationの見た目だけからObservation欠落と断定しない。実機で要求が発行済み/状態がreadyか、画面だけ更新されないかの観測はない。

session同期は旧Task取消→旧Previews.cancel（世代更新・共有表示取消/解放）→新owner生成→load Taskの順で、同期本体にはawaitがない。Previewsはawait後の世代とTask取消を照合して遅い結果を拒否する。LocalImageAccessの取消handlerは要求ID単位で後からMainActorに到達し、全表示取消/releaseとは異なる。現時点でこの非同期順序が本人の直接原因と示す証拠はない。修正では遅い旧応答が新ownerを更新しないこと、退場時に不要要求/保持が残らないことを維持する。

出力は表示画像と変換memoryの同時保持を抑えるための破棄を行う。再表示の再開を追加する場合も、出力の実画像処理/片付けが終端へ達する前に再取得しないこと、同じsessionが有効かを照合することが必要。

## 出力の画像取得失敗との区別
本人申告は「写真アプリで読み込んだ後に出力成功」。出力用PhotoKitArticleImageReaderは編集入力/fullSizeImageURLを得られないとassetUnavailableを返し、ネットワークはfalse。表示は別のSystemImageDriver/LocalImageAccess経路で512px要求を行う。実写真のローカル可用性は未観測。出力成功が表示ownerの存在や要求発行を証明するものではない。通信追加・写真認可リセット・保存先変更をこの分析から導かない。

## 既存試験と欠落
- ArticleImageTests/ArticlePreviewRetryTestsは表示ownerを直接生成し、成功・期限・取消・番号別再試行・遅い応答拒否・資源解放を検証する。取消後states空は既存期待であり、取消後の同一owner retry再開は検証していない。
- ArticleExportSessionTestsは注入したactionsを使い、出力の成功/取消/失敗/固定入力を検証する。Coordinatorによる表示ownerの破棄/復旧を通らない。
- ArticleExportUITestsは成功一式・取得失敗・取消・cleanup・本文コピー・Finderを検証するが、その終端後に4枚の画像ready/実表示や再試行の要求増加を確認しない。初期の未保存確認取消と、表示破棄後の保存先取消は異なる。
- ArticleDraftUITestsは通常再試行・photos-missing状態でのキーボード要求数・本文保持を検証する。出力が解放した後の同一sessionは対象でない。
- ArticleSandboxStorageUITestsは本文/同じ記事の保存再開と4つの文章欄の存在を検証する。画像4枚の実表示・要求発行の検証ではない。

後続では、fresh再開と同一session復帰を分け、正常/画像失敗/処理取消/保存先取消/破棄後早期returnの終端、nil/空stateからの実要求、旧応答排除を最小の回帰へ対応付ける。具体変更・試験数・注入境界は要件と実装計画で決める。

## 検証の限界
静的読取のみ。新しいbuild・試験・Photos取得・画面操作・OS設定変更は実行していない。既存CI設定は全手書きApp/Core Swiftと80%floorを維持するが、従来の成功/coverage率を今回の回帰再現や修正成功へ代用しない。本人環境の操作順と表示/要求状態は未確認。
