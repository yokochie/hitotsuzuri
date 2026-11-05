# U2 下書き編集の実装記録

## 最終結果と未確認

候補commit `2337dd6b0f2abcc4233e75b9e904814cf53a0bc0` の[最終CI 41945323042](https://github.com/yokochie/hitotsuzuri/actions/runs/41945323042)は成功した。主bundleのCore機能371件＋UI55件＝426件と、別bundleの起動smoke2件がすべてPassedで、未成功/skipはない。製品全ソースの加重行カバレッジは **4207/4673＝90.03%**。除外追加や性能bundleの率平均・合算は行っていない。

性能合否は本人指定により本人Macで別途確認し、Core性能5件とUI性能4件が成功した。CIを性能の代用にせず、性能成功も機能回帰の代用にしない。測定後の製品差分はPickerContentのクリック焦点処理/DEBUG診断だけで、記事の保存/投影/描画/計測実装は不変。指示どおり成功済み性能を反復していない。

**独立レビューはこれから**で、Unit承認・main統合・配布済みとはしない。実写真、Sandbox成果物、note手動受渡し、本人操作の通常アプリcold起動、最小640×560ptの高さ境界操作は未確認。OS lifetime peakの当該処理への厳密な帰属、起動前OS bootstrap/ディスクcache coldも測定の限界として残す。本人手順は`user-verification.md`を参照する。

## 実装内容

記事の入口、同写真再確定時の候補選択、手動保存、全本文と撮影情報、日付候補、未保存確認、編集/プレビューを接続した。本文コピー・一式出力の値型とC3境界は定義したが、OSクリップボード・Finder・4枚成果物の実装は`u3-article-export`で行う。未接続の操作は製品で利用不可と表示する。

新規記事の絶対末尾ASCII接尾辞だけをUTF-8単位で除き、有効な暦日を未確認候補にする。保存済み記事には初期値を再適用しない。年月日のraw入力を有効な永続値と分け、不正値もdirtyとして保持する。本文のUnicode正規化による書換えを許さず、投影/保存/切替判定で共通指紋を使う。

永続化は既存schemaVersion 1、操作記録、lock、原子的確定、元操作照合を継続する。関連付けでは新しい選択IDと保存版だけを更新し、元sourceと本文を保持する。不確定結果は後続I/O失敗でも元の固定入力を保持して照合し、追加入力で上書きしない。

記事切替は切替先を準備してから採用し、待機中に元入力が変わった場合は切り替えない。候補シートを閉じてから未保存確認を出し、OSの閉鎖/終了には一度だけ応答する。投影の実処理一件と表示意図を別に管理し、編集へ戻った後の古い成功/失敗を採用しない。コピー境界でも記事IDと指紋を照合する。

Pickerと記事は同じ表示画像アクセスを共有する。4番号の受付で共通15秒期限を固定し、番号別再試行には新しい期限を使う。写真が取得不能でも本文を編集・保存できる。通信要求や写真ライブラリの変更は追加しない。

## 変更ファイル

全43ソース/試験/スクリプトのパスは`source-manifest.json`に列挙する。主な責務は次のとおり。

| 対象 | 内容 |
|---|---|
| CoreのInitialContent/MetadataInput/Projection/OutputPorts/Presentation | 入力規則、純粋投影、C3境界、単一編集・操作状態 |
| Workspace/Ports/Persistence/Fingerprint/EditSession/ImageAccess | C1関連付け、保存照合、raw入力、表示画像期限 |
| Appの記事Coordinator/View/MetadataFields/PreviewView | 全欄、日付、候補、プレビュー、離脱、焦点、狭幅配置 |
| App/Picker/DebugFixtureとCore PickerContent | 共通入口、画像アクセス共有、独立した合成fixture |
| U2の10 Core試験クラス・共通Fake、通常UI23/性能UI4/smoke2 | 正常/失敗/遅延/取消/再起動、長文・幅・キーボード、計測 |
| 既存ArticleSessionTests | 新しい必須ポートへのFake適合のみ。既存期待値は保持 |
| 専用/正式runner・共通Python・契約試験・verify.yml | Core先行停止、通常/性能の選択、実行済み検査、機能CIと全製品加重coverage |

本人の共有scheme変更、Phase1記録、既存の未追跡設定等は本Unitのソース変更へ含めない。pbxproj・entitlement・既存coverage checker/閾値は変更していない。workflowと既存UI起動helperは本人指定の試験改訂で対象へ追加した。新規package、有料runner、OS/TCC/キーボードのグローバル設定変更は行っていない。

## 最終検証

正式な機能確認は本人31548a2aの承認により `bash scripts/verify-native.sh --functional`。CIはCore機能を先行確認し、その成功後に全Core機能＋全機能UIの単一主bundleから全製品80%以上を判定する。実時間/実メモリの合否はMac専用へ分離した。

| 最終CIの段階 | 結果 |
|---|---|
| native-core / job126975986587 | Core機能371件成功 |
| native / job126976799446・主bundle | 同じCore371件＋UI55件＝426件成功 |
| 別起動smoke | 記事/Pickerの2方式成功、回収まで確認 |
| UI内訳 | ArticleDraft23件575.496秒、Foundation6件89.965秒、Native26件394.531秒 |
| UI合計 | 55件1059.996秒、未成功/skipなし |
| 製品全体の行カバレッジ | 4207/4673＝90.03%、製品sourceの除外追加/率平均なし |

先行と主bundleで同じCoreを確認しているため、新規ケース742件として合算しない。旧CIで失敗していたNative8件は、マウス選択時のfocus所有不足を限定CIで再現して修正し、8件限定Greenの後、最終の26件全成功を確認した。余分なTabやtimeout延長で期待を変えていない。画像応答からfocusは移さない。

層別Red→Green→整理、認証・容量・起動失敗、Unicode入力の非再現、runner改訂と限定CIは`tdd-evidence.md`と`ci-evidence.md`に履歴として保持する。過去の部分成功/失敗を最終候補へ混ぜず、未実行を機能RedやGreenに数えない。今回のCI成功と本人Mac性能成功も環境別に記録する。

UI fixtureはケース固有UUID rootを再起動中保持し、teardownで当該rootだけを回収する。Coreも当該プロセス発行rootだけを正常終了時に回収する。リンク/異なるnamespaceを拒否し、強制終了時の残存可能性は残す。本人データや過去bundleを自動回収しない。

## 本人Macの性能結果

MacBook Pro/Mac15,3、Apple M3/8core、16GB、macOS27.2/Xcode27.2。電源の取得時点はAC Power/79%（全期間監視ではない）。100記事/対象初期1000操作、タイトル200文字/6本文各10000文字を使用した。詳細値と条件は`tdd-evidence.md`を正本とする。

| 測定 | 現在の成功値 |
|---|---|
| 保存/再開30回（Core） | p95 15.249ms / 4.814ms |
| 純粋投影100回 | p95 9.454ms |
| 入口/一覧loading各30回 | 最大44.339ms / 104.687ms |
| 保存中文字/待機中入力 | 最大21.642ms / 14.689ms（入力30試行60sample） |
| preview/editor各30回 | p95 172.049ms / 147.706ms |
| UI再開30回 | p95 136.202ms |
| 異なる10プロセスのcold起動 | App.init以降のp95/最大1.216728秒 |
| U2表示メモリ30回 | direct4,194,304B、sample増分0、最大観測間隔12.971ms |
| U1画像変換30回 | 最大166.400ms、sample増分92,422,672B |
| 未応答表示の取消30回 | 受理最大54.625µs/論理終端最大336.709µs |

Core性能は`Native-core-20261105-091508-6e699b0c5e61487dbe663ccdb42e3ba7.xcresult`の5成功、UI性能は`Native-selected-20261105-092155-1201c1732b2241db8136be0f5bb8aa36.xcresult`の4成功（各0skip）。UIのnot-ready timeout検査は0。Macの50ms観測品質・5秒baseline・応答時間・256MiB/512MiBと反復数は維持した。合成512pxのCoreメモリ測定を実Photosや製品UI全体のメモリへ拡張解釈せず、OS lifetime peakの厳密帰属未確認を消さない。

## 計画との差・対象外・残る確認

本人指定で通常UI23件/Mac性能UI4件/smoke2件を分離し、CI性能jobを廃止した。製品全ソースの80%は維持する。途中の限定診断用CI/印分岐と旧版比較jobは役目を終えてrootが撤去し、最終CIは通常2jobで全機能を確認した。記録/対応表は作成済みだが、Step18の独立レビュー部分は待ちとして未完を残す。

実写真の編集/回転/色/位置情報除去、Sandbox成果物、note受渡しはU1/U3と本人の統合確認、OSコピー/Finder/4枚一式出力は`u3-article-export`へ残す。合成fixtureを本人実機確認へ置き換えない。未接続操作は利用不可のまま。レビュー済み上流文書の旧担当表記`u3-output-delivery`は対応表で正式名へ統一したが、上流本文を無断編集していない。

内容幅640/959/960/961/1200ptと長文/キーボードは自動試験で確認した。内容高さ560ptの専用実測と本人操作は未確認。VoiceOver追加検証は本人指定により対象外。起動・確認・戻し方は`user-verification.md`に残す。
