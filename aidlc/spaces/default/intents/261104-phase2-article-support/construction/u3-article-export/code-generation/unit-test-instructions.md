# U3 専用試験の実行手順（計画）

## 現在地
以下の専用runner/新テストは承認後に作成する計画で、現在は未実装・未実行である。既存基準は候補2337dd6のCIとMacの426機能＋別smoke2件、全製品90.03%。U3新機能の成功証拠ではない。

## Runner and Readiness
既存Xcode project/Hitotsuzuri scheme/macOS宛先/XCTest/同期フォルダを使用する。新規Core試験はHitotsuzuriU3Tests、UIはHitotsuzuriUITestsへ追加し、共通Python runnerのexport区分を新しい薄いラッパーから呼ぶ。第三者依存やshared scheme変更は計画しない。

最初に短いrunner契約をRed/Greenにし、既存C3の値型を消費するArticleExportContractTestsの3件で準備を確認する。対象が存在しビルドでき、指定3件が実行成功/0skipになるまで、新しいモデル/業務のテスト先行へ進まない。

```bash
bash scripts/verify-article-export.sh ArticleExportContractTests
```

この成功は既存契約の受領とrunner準備であり、新機能のGreenに数えない。未知引数/0件/未成功/指定未実行を非0にする。型不在コンパイルエラー、認証や起動障害だけを機能Redにしない。

## Unit Commands
下記は全てU3専用選択。既存U3 target全体を無条件に選ばず、表の8クラスと必要なU3 UIだけを対象にする。既存共通smokeはUI起動の前提として先行する。

```bash
bash scripts/verify-article-export.sh --core
```

```bash
bash scripts/verify-article-export.sh --functional
```

```bash
bash scripts/verify-article-export.sh ArticleExportWriterTests ArticleExportJournalTests
```

```bash
bash scripts/verify-article-export.sh ArticleExportDeliveryTests ArticleExportSessionTests ArticleExportIntegrationTests
```

```bash
bash scripts/verify-article-export.sh ArticleExportOSActionTests
```

```bash
bash scripts/verify-article-export.sh ArticleExportUITests
```

本人Macで新しいU3性能だけを測る場合:

```bash
bash scripts/verify-article-export.sh --performance
```

--coreはU3機能だけ、--functionalはU3機能＋smoke＋U3 UI、--performanceは新規性能2メソッドだけを要求し、既存U1/U2性能・長いUI性能を起動しない。GITHUB_ACTIONS=trueでは性能区分を拒否し、クラス指定の機能CIからも新性能2メソッドを除く。性能はArticleExportIntegrationTests内に置き、通常の統合機能ケースは残す。

## Test Matrix
| クラス | 目安 | 検証対象 |
|---|---|---|
| ArticleExportContractTests | 3 | 既存C3受領、指紋/本文不一致拒否、runner準備 |
| ArticleExportModelTests | 8 | 固定入力、版1manifest、四枚と順序、設定、相対参照と文字 |
| ArticleExportJournalTests | 8 | 登録、排他、同ID、旧値、破損/未知版、終端保管と再起動 |
| ArticleExportWriterTests | 12 | 一式、非置換、sync/rename境界、R-01実体差替え、symlink、容量/権限、片付け |
| ArticleExportDeliveryTests | 8 | 順次取得、予算、期限、重複/遅延、取消と成否 |
| ArticleExportSessionTests | 8 | 保存判断、固定内容、編集保護、古い通知と焦点復帰の判断 |
| ArticleExportOSActionTests | 8 | 専用pasteboard、文脈、コピー/Finder失敗、grant寿命 |
| ArticleExportIntegrationTests | 機能12＋性能2 | 実ファイル一式、再起動/結果照合、失敗/取消、Mac実測 |
| ArticleExportUITests | 8 | 保存前確認/取消、正常、写真不能、片付け失敗、完了コピー、Finder失敗、幅/キー、回復 |

件数は必要境界を省く上限ではない。各部品の正常と二つ以上の異常/境界を含む。Writerは公開/片付けの危険境界が多いため12件を基準とする。

## Data and OS Boundaries
実型から作った固定入力/manifestと、試験所有UUID rootだけを使う。C2は非通信要求を記録するFakeと実変換の合成画像を使い分ける。時計/期限は機能試験で注入し、実時間計測へ混ぜない。私的写真・既存下書き・旧完成物は使わない。

OSコピーは名前付きの試験専用pasteboardを使い、general pasteboardや他アプリの内容を読む/上書きしない。Finder/workspaceと保存先選択は注入で正常/失敗を検証し、実ウィンドウ表示や本物のSandbox/noteの成功は本人確認で分ける。UI fixtureも所有UUID rootと既存の安全な回収方式を使い、対象外を再帰削除しない。

R-01は検証後からrename前までの一時名差替え、rename後の完成名差替え、同じ実体の内容変更を注入する。未検証成功を拒否し、所有不明物の削除/巻戻し/上書きがないことを検証する。

## Coverage and Performance
U3限定runは製品全体のcoverage合否を判定しない。全製品80%以上はintentの承認済み正式検証と機能CIの全Core機能＋全機能UIの単一主bundleで確認し、部分率の平均/合算・製品source除外で代替しない。

新規Mac性能2件は各4096×3072の合成JPEG4枚、本文各10000文字、正常ローカル保存先で30試行p95≤10秒。メモリはbaseline5秒以上、実観測間隔50ms以下、直接画像256MiB/プロセス増分512MiB、取消の受理0.5秒/画像論理終端2秒と正常片付けp95≤5秒を別に確認する。観測品質不成立は合格にしない。入力サイズの上限ではなく検証条件である。

画像1件30秒/工程40秒、全体180秒の工程開始・採用判定は決定論的試験も維持する。OS停止や確定不明を取消完了とせず照合へ収束させる。性能は本人Macだけで合否を判定し、CIで実測を反復しない。未実施/未達/本人実機未確認を記録し、合成試験だけで実写真やnoteの完成を宣言しない。
