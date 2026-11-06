# U2 論理部品と障害の分離

## 根拠
`../nfr-requirements/performance-requirements.md`、`security-requirements.md`、`tech-stack-decisions.md`、`../functional-design/functional-spec.md`、`../../../inception/contract-design/contract-summary.md`、`../../../inception/domain-design/components.md`を具体化する。同一macOSプロセス内で責務を分離し、サーバー/クラウド基盤を追加しない。

## 所有・隔離
| 部品 | 所有する状態/操作 | 障害の影響と分離 |
|---|---|---|
| ArticlePresentation/Coordinator | 現在セッション、開始要求、候補/部分失敗、保留離脱先、表示モード、焦点 | 一つの要求世代に限定。画像失敗で文字セッションを落とさない。入口2か所を一つへ |
| ArticleEditSession | 作業content、保存済み基準、固定pending操作/不確定状態 | 保存失敗で入力保持。pending照合はUI世代取消と別。新規初期化は作成時だけ |
| MetadataInputState | raw年月日、妥当性、候補/確認状態、元表示との差分 | 不正入力もdirty。保存/投影のみ止め他欄編集は継続 |
| ArticleWorkspace/C1 | 選択の読取、候補照合、一覧/開く、関連付け、保存 | 型付き失敗を維持。永続化の所有はU1、UIに別の正本なし |
| ArticleProjectionContext | 不変記事ID、純粋renderArticle、共通指紋 | 投影失敗はコピー/プレビュー/出力準備に限定し、保存済み記事を書換えない |
| ArticlePhotoPreviews/既存ImageAccessing | 番号別画像状態、要求世代、既存共有予算/キャッシュ | 通信禁止、期限/取消、不要所有解放。成果物画像へ転用しない |
| C3 ActionPort/Capability | コピー、保存済み出力入力、ジョブ結果/取消、Finder接続の値 | 型はU2、実OS/四枚処理はu3-article-export。U2はFakeで独立試験し未接続は無効 |
| Window/Application bridge | 一回の閉鎖/終了保留、元delegate、対応するreply | 保存失敗なら閉じない。旧Pickerのdelegate/キー状態を保護 |
| 診断/計測境界 | 固定段階/分類/件数/時刻/byte数 | 私的情報を受取らない。外部送信/常時監視なし |

テキスト接続図: 入口→Coordinator→C1→EditSession、EditSessionの検証済み写し→ProjectionContext→Preview/C3、4写真ID→PhotoPreviews→画面。閉鎖/終了→Coordinatorの離脱確認→C1保存結果→一回のOS応答。画像から保存可否へ依存を作らない。

## 共有資源と障害範囲
UI/MainActorは状態採用と描画、永続化actorはI/O、純粋投影は不変値の非UI処理、画像読取は既存境界である。共有画像バッファは一つの予算で数え、画面別キャッシュを増やさない。開始・保存・離脱はそれぞれ単一保留とし、同じ対象の競合を調整する。投影/画像/コピーの応答は独立世代で採用する。

保存先アクセス・画像変換・一時物・manifest・成果物確定はU3/U1側の責務。ここでクラウドのリトライ/サーキットブレーカー/レプリケーションを追加しない。手動再試行の前に未確定結果を照合する。アプリの強制終了後は保存済みだけを復元し、未保存復旧機能を新設しない。

## 判断記録
| 判断 | 文脈・決定 | 結果/代替 |
|---|---|---|
| 単一作業セッション | 幅変更/プレビューで文字を守るためViewの枝から編集所有を分離 | 複数画面の作業コピーを作る方式は同期と誤保存を増やすため不採用 |
| 記事ID付き純粋投影文脈 | C3出力に記事IDが必要。固定receiverで入力契約を維持 | 大域active article参照/選択ID流用を排除。同じ文脈と入力が決定的 |
| raw日付と有効contentの分離 | 不正値の保持と永続型の妥当性を両立 | dirtyにraw差分を追加し、旧正常値の黙った保存/投影を防ぐ |
| OS操作ポートの依存逆転 | U2をU3の実装なしでビルド/試験可能にする | Fakeは試験のみ。製品の未接続操作は利用不可 |

実装対象名とファイル分割はCode Generation計画で確定する。上記は既存C1/C2/C3の必須フィールド/意味を変更するものではない。
