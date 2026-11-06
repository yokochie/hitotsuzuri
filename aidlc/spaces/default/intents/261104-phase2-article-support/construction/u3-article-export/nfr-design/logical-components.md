# U3 論理構成と障害範囲

## Sources
components.mdのArticleDelivery/ArticleImages/ArticlePresentationとC2/C3、U3機能設計、security-design.md D1〜D7。配布単位は既存アプリ一つのまま。

| 内部境界 | 所有・入力 | 主な保護 | 障害範囲 |
|---|---|---|---|
| ExportController | 固定入力、jobID、進捗と終端 | 同IDと固定指紋、取消/確定の直列化、単調期限 | 対象ジョブだけを停止。Workspaceへ保存を呼び戻さない |
| ExportJournal | active状態、job別の結果/回復記録 | アプリ内の専用領域、OS排他、期待旧値、版と所有、同期 | 未確定は再実行を拒否/照合。記事保存と一枚検証の領域を変えない |
| ArtifactWriter | 選択親と検証済み一時実体、固定生成バイトと期待digest | 開いた親からの相対操作、nofollow、排他的生成、同期、非置換公開、公開前後の実体/全一式照合 | 不一致は成功にせず所有不明物を触らない。旧完成物を削除しない |
| ImageBridge | C2の画像要求と共有予算 | 一件ずつ取得/変換、通信禁止、ID/期限/設定検証、書込後解放 | 写真番号付きで失敗。文章は失わない |
| DestinationAccess | 都度選択した親とgrant | 実体照合、scope寿命、bookmark非永続化 | 失敗を対象保存先へ限定 |
| Clipboard/FolderActions | 文脈付き本文、完成結果 | OS結果と記事状態の分離 | コピー/Finder失敗でも完成成果物を保つ |
| Presentation接続 | 状態と利用者の操作 | 対象の編集保護、焦点復帰、文字状態、古い通知破棄 | 既存画面の主要操作を継続可能にする |

共有資源はC2の画像予算、保存先grant、直列I/O実行部。高解像度JPEGを四枚同時保持しない。ファイルI/OはUIから分離し、処理が止まってもworkerや待機キューを増やして回避しない。過去ジョブはファイル単位で必要時に読む。サーバー、分散トレース、キューサービス、追加DBは作らない。

## Flow
PresentationがC1の保存とU2投影を終えて固定値を渡す。ExportControllerはJournalへ登録し、ImageBridgeとArtifactWriterを順次呼ぶ。Writerが全検証と非置換公開を終えてからControllerが結果を採用する。コピー/Finderは完成結果または現在入力の別操作で、記事正本を更新しない。回復時は同IDと再選択した親をJournal/Writerで照合する。

## Validation Boundary
型/規則と障害注入は単体・統合、焦点と状態は薄いUI試験、性能は本人Mac、実写真とnoteは本人確認に分ける。各境界の実装パスと差分所有はコード生成計画で本人に示す。この文書は新しい独立コンポーネント正本や配布構成を増やすものではない。
