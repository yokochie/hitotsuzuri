# U1 ローカル実行環境

入力は`../nfr-design/`のperformance-design.md、security-design.md、scalability-design.md、reliability-design.md、observability-design.md、logical-components.md、`../functional-design/functional-spec.md`、`../../../inception/domain-design/components.md`、`../../../inception/contract-design/contract-summary.md`。以下は設定と検証方針であり、未実行の成立性を合格としない。

## Deployment
| Facet | Choice | Rationale |
|---|---|---|
| compute model | 本人Macの単一ネイティブアプリ。既存App/Coreへ追加 | 配布サーバー・コンテナ・AWSなし |
| networking topology | アプリのネットワーク権限追加なし。画像要求は通信false。CIのソース取得通信とは区別 | NFR1.1、画像自動ダウンロード禁止 |
| storage strategy | OSが返すApplication Support/Hitotsuzuri/Articles。既存selection.json/settings.jsonは親領域のまま | NFR2.1〜2.5、旧選択と独立。Sandboxの実パスを文字列固定しない |
| environments | 開発/本人利用はmacOS27.2/Xcode27.2(27B52)、製品最低27.0。CIは標準xcode-27の実際の版を記録 | ローカルとCIが完全同一とは仮定しない |
| IaC approach | Xcode設定/entitlements/検証スクリプト/GitHub Actions YAMLをコード生成時に管理 | この段階では実設定変更なし、クラウドIaC不要 |
| resource sizing | 変換1件、直接画像バッファ256MiB、プロセス増分512MiB、画像30秒/書込込み40秒 | NFR3.1〜3.6、計測はmonitoring-design参照 |
| signing | 既存Manual/ad-hoc、Bundle ID com.yokochie.Hitotsuzuri維持 | ローカル検証用。配布証明書/公証/ストア公開を追加しない |
| source integration | main起点の短いcodex/作業ブランチ、確認後squash | 同commitのCIと本人確認後だけ統合 |

## Infrastructure Services
| Service | Role | Configuration | Notes |
|---|---|---|---|
| OS Application Support | 記事ストレージ | Articles/<project UUID>/current、operations/<operation UUID>、ロック。ファイル0600/dir0700を基本とする | currentと不変操作記録は同じボリューム。索引は派生。NFR2.3/2.4 |
| PhotoKit | 読取素材 | 既存photos-library権限、network=false、変更APIなし | このentitlement自体はOS上read-writeだが、実装の公開境界は読取専用。NFR1.1/1.2 |
| Image I/O/Core Graphics/CryptoKit | 変換・識別 | URLから用途別縮小、sRGB JPEG、SHA256共通処理 | 外部ライブラリなし、NFR7.1/5.2 |
| NSOpenPanel + 選択先アクセス | 出力ストレージ | com.apple.security.files.user-selected.read-write追加。ディレクトリ選択、ジョブ中だけアクセス管理 | 全ファイル/Downloads/Pictures全体権限や永続bookmarkなし。NFR2.2/2.7 |
| OSLog/OSプロセス計測 | ローカル診断 | 列挙型ログ、数値計測、私的内容なし | 外部監視/ダッシュボードなし、NFR6.1/6.3 |
| GitHub Actions | CI実行 | 公開リポジトリ標準xcode-27、読取権限、合成fixture | NFR5.1/6.2。pipeline詳細はcicd-pipeline.md |
| database/cache/queue/search/CDN/DNS/load-balancer | 対象外 | 追加なし | 既存表示キャッシュは継続、記事原画像を恒久保存しない |

## Shared Infrastructure
| Shared Resource | Owner Unit | Consumer Units | Access Boundary |
|---|---|---|---|
| 記事保存/共有値/指紋 | U1 | U2/U3 | ArticleWorkspace公開契約。ファイル直接書換え禁止 |
| 記事画像/保存先アクセス基礎 | U1 | U2/U3 | Images/Deliveryの用途別公開型 |
| Xcode project/検証スクリプト/CI | U1初回導入 | U2/U3 | 同一アプリ/合成試験、共有変更は各コード計画で影響と所有を明記 |

## ファイルシステムの保証と事前確認
内部保存は本人Macの正常なローカルボリュームを基準とし、descriptor相対openat系・O_NOFOLLOW/排他的作成・flock等の協調排他・同一ボリュームrename・必要なfsync/同期を使用する。最終出力フォルダは既存物を置換しないrenameatx_npの排他オプション等、SDKで利用可能な非上書き操作を選ぶ。SDKと実ボリュームで原子的参照切替/同期/排他を確認する小さな検証をコード計画へ含め、呼出失敗を無視しない。

ファイルを開いた実体と親descriptorを維持し、同名リンク/別名/親差替えを文字列検査だけで処理しない。確定参照の比較はロック内、同operationIDの既確定照合を競合確認より先に行う。非協調な外部プログラムとの完全な排他を保証しない。破損・未知版・識別変更では明示失敗にして旧データを保持する。

外付け/ネットワーク保存先で必要操作が非対応なら、上書きや非原子的コピーに切替えて成功を装わない。途中物を片付け、失敗または不確定結果を案内する。同期完了後の電源断にも絶対保証があるとはしない。実装前/実装中に成立しない条件が判明した場合は、該当計画へ記録して解決または本人へ判断を戻す。

## 権限寿命と戻し方
フォルダ選択で得たアクセスとsecurity-scoped APIの必要性を実際のSandboxで確認し、開始したアクセスだけを対称的に終了する。選択前にgrantを持つ型は作らない。取消・失敗でも一時物処理までアクセスを保つ。起動後に過去パス文字列だけで書込権限があるとは仮定せず、本人が再選択してジョブを照合する。

旧版へ戻す検証は別の作業領域/アプリ成果物を用意し、Articlesを退避・保護する。旧版へ新形式を書換えさせず、selection/settingsの互換読込を確認する。本人の作業ツリーや保存データをreset/削除する手順を作らない。実際の起動・署名・保存先許可・写真確認は日本語手順で案内する。

根拠: [利用者選択先の書込権限](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.files.user-selected.read-write)、[Sandboxファイルアクセス](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox)。実際のSandbox動作は本人確認が必要。
