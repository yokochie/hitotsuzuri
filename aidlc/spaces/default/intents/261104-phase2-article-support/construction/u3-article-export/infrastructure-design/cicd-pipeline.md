# U3 ローカル実行と検証構成

## Sources
同Unitの../nfr-design/security-design.md（本人指示によるR-01修正を含む）、../nfr-design/logical-components.md、../functional-design/functional-spec.md、inception/domain-design/components.md、inception/contract-design/contract-summary.mdを入力とする。library種別ではperformance-design.md・scalability-design.md・reliability-design.md・observability-design.mdは独立成果物対象外であり、実在を仮定しない。対応する資源・回復・診断はsecurity-design.mdに具体化されている。

## Deployment
| Facet | Choice | Rationale |
|---|---|---|
| 実行単位 | 既存のmacOS 27/Swift 6アプリへ組込むライブラリ | 独立サーバー・クラウド・別アプリを作らない |
| 環境 | 本人MacでXcode/Debug/My Mac。CIは現行xcode-27 | 実行ごとに実OS/Xcode/機種/署名を記録し、ラベルだけで同一性能とみなさない |
| ネットワーク | 写真取得通信なし、独自ingress/egressなし | 全画像要求で通信禁止を維持 |
| 内部記録 | アプリ専用Application Support内のExportJobs。記事保存/選択/一枚検証記録と別領域 | 記事一覧や既存記録の正本を変えず、job別の固定入力と結果を保管 |
| 一時/完成物 | 利用者が選んだ親内の別生成名。一時物と完成物は同volume | 非置換renameで一式確定。別volumeコピーへ暗黙移行しない |
| 資源 | active出力一件、画像変換一件、既存共有画像予算と直列I/O | 無制限なJPEG保持やworker増設を避ける |
| IaC/配布 | 新しいIaC・公開配布・自動デプロイなし | 本人のローカル利用という範囲を保つ |

## Shared Resources and Ownership
| Resource | Owner | Consumer | Access Boundary |
|---|---|---|---|
| 保存済み記事・共通指紋 | ArticleWorkspace、U1/U2提供 | U3の固定入力 | C1/C2/C3の公開値のみ。U3から原本を更新しない |
| 高解像度取得と共有予算 | ArticleImages、U1提供 | 出力と既存表示 | C2要求IDと期限、直接256MiB/増分512MiB、用途を分離 |
| 保存先grant | ArticleDeliveryのOS境界 | 一つのジョブ/明示的照合 | 都度選択、親実体を保持、実I/O収束後に解放。bookmarkを永続化しない |
| ExportJobs記録 | U3 ArticleDelivery | 開始・結果・再起動照合 | バージョン/OS排他/旧値照合、jobID別の安全名、ローカルのみ |
| 一時物と完成物 | 当該ジョブ | ArtifactWriterと照合 | 公開前後の実体と期待一式を照合。不明な物を削除/巻戻ししない |
| クリップボード/Finder | OS操作境界 | 現在入力または固定完成結果 | OS結果と記事/出力成功を分離し、他アプリの状態を上書き復元しない |

## Verification Pipeline
| 段階 | 実行先・対象 | 通過条件 |
|---|---|---|
| 変更前の基準 | 現在のU2完了候補2337dd6のCI/Mac証拠 | 全機能426件とsmoke2件、全製品90.03%。これはU3未実装機能の成功ではない。無変更の長い基準を反復しない |
| runner準備 | 共通runnerとU3専用の限定コマンドをコード計画で具体化 | 未知引数/0件/skip/指定未実行を失敗とする。新しい性能メソッドを機能CIから明示分離 |
| 層別Red/Green | U3値型・manifest/固定入力・記録/Writer・制御・OS接続 | 意図した失敗→最小実装→整理を記録。認証・起動障害や未実行をRed/Greenにしない |
| 限定診断 | 影響するケース群だけ | 差替え、sync/rename境界、結果不明、取消、コピー/Finder失敗を失敗注入。長い全体を診断目的に反復しない |
| Core先行 | 現行native-core job、正式--core | 全Core機能成功後だけUIへ進む。性能の実測ケースを含めない |
| 全機能/coverage | 現行native job、正式--functional | smoke成功後、全Core機能+全機能UIの主bundleをPassedで確認し、全製品加重80%以上。試験除外/率平均で基準を下げない |
| U3性能 | 本人MacのU3限定実測 | 四枚の正常30試行、取消/メモリ観測条件を満たす。無関係なU2/U1の成功済み性能は再実行しない |
| 実写真/手動受渡し | 本人の検証用写真と選択保存先 | 編集/向き/色/GPS除去・Sandbox・Finder・note貼付けと順序を日本語記録。未実施を自動成功で補わない |

現在の.github/workflows/verify.ymlはPR・main/codex系push・手動起動、contents:read、checkout固定revision・persist-credentials:false、同一refの重複run取消を使う。native-coreは15分、成功依存のnativeは30分。CIで実時間/実メモリの性能jobを追加せず、純粋な期限/予算ロジックは機能試験に残す。U3追加後の実行時間を確認し、時間切れを成功や未実行免除にしない。

追加キャッシュ/成果物アップロード/大型runner/有料サービスは導入しない。合成データとログ/commitを証拠にし、本人の写真・下書き・manifest・回復記録はCIへ送らない。CIをローカル手動試験と呼び替えない。限定jobだけで統合条件を達成したことにしない。

## Local Safety and Monitoring
| 対象 | 構成・判定 |
|---|---|
| 正常保存先 | 本人Macの正常ローカルvolumeを基準に、排他的rename/同期の実結果を確認。任意の外付け/ネットワーク保存先の成立は仮定せず非対応を案内 |
| 差替え | 検証済み一時実体を保持し、名前解決直後/公開後の実体と全一式digestを成功条件へ入れる。差替え不一致は成功にせず所有不明物を触らない |
| 取消・停止 | 受理/画像論理終端/OS I/O収束/片付けを別に観測。OS停止を取消完了と表示せず、保留workerとgrantを安全に保持 |
| 一時データ | Core/DEBUG UIは試験所有UUID rootを使う。回収はその所有が証明できる領域だけで、本人データや旧bundleをまとめて削除しない |
| 診断 | 段階・分類・画像番号・匿名時間。本文・写真ID・場所・人物・保存先は通常ログへ出さない。外部監視/通知基盤は作らない |
| 戻し方 | アプリ終了後に保存済み下書きと必要成果物を保持し以前のビルドへ戻す。未知版/未完記録を上書き・自動削除しない |

## Implementation Boundary
これは構成と試験の設計であり、U3のコード・新runner・ジョブ保存領域はまだ生成していない。実装パス、共有型への差分、短い検証コマンド、OS境界と障害注入はコード生成計画で本人確認する。U3のために既存の認証/TCC/キーボード設定を自動変更しない。
