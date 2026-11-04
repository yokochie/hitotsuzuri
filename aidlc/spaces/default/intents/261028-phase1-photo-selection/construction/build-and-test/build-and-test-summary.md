# Build and Test 現在結果

## 判定

### 承認確認用の現在結果（2026-11-04）

本人9f8f65c4により速度未達を残して承認確認へ進む。品質判定は全項目合格ではない。製品の自動試験は205件成功・失敗/スキップ0、製品行カバレッジ90.21%。補助測定ツールは起動修正・既知数値OCR補正・時間内訳追加後に画面不使用の自己試験22件成功。基本保存/復元、報告された各キーボード不具合、狭幅の確定到達、VoiceOverの名称/選択順/枚数/保存結果は本人確認済み。実321枚の資源10往復は安定。

残る例外は、速度0/30件で200ms条件未達（本人が今回受入）、子フォルダ折畳みで選択と編集が解除され得る既知問題（本人fe24ba92が現状継続）、コントラスト数値・実機の全異常経路/オフライン/順序比較・厳密な全画面幅条件等のUnverified。VoiceOverの取得不可/復元理由等も未確認。このほか横断追跡のNFR2/NFR4/NFR5は旧単位のDeferredが残るためFAIL。以下のTarget Verification Matrixを現在の各条件の判定とし、成功済み部分を未確認全体の合格へ広げない。今回の速度受入を他の条件の受入に拡張せず、全体の承認は別の本人判断を待つ。

状態は承認確認用。成功完了/配布準備完了とは宣言しない。CIは本人決定により非適用。レビュー後の本人指定修正（狭幅確定・補助ツール）は新規レビュー済みとは扱わない。

2026-11-04代理実機測定: 実321枚の30操作は全て照合成功したが、不確かさ込み200ms以内0/30で速度条件Not Met。10往復の不要要求0・保持量安定はMet。計測側のOCR採取間隔が大きい可能性があり、アプリ単独の遅延とは断定しない。閾値を変えず測定方法改善候補を影響見積りし本人方針待ち。未達/未確認を合格にしてConstruction完了しない。

本人93f73a38により狭幅での確定到達・保存・逆Tab復帰を成功確認。今回の入力修正は本人確認済み。以下の本人未確認記述は回答前の履歴として保持し、VoiceOver・コントラスト・実画面性能等の未確認条件は維持する。

### 現在の判定（狭幅の確定到達修正後）

本人指定の不具合を直接修正し、実UIのAlbum/Photoから有効確定へTab→Space保存、逆Tab復帰を追加検証。`.build/Native-20261103-234223-36633.xcresult`、全205件成功・失敗0・スキップ0、1474/1634行=90.21%、exit0。以下の201件等は履歴。前レビュー後の本人指示による変更で、今回内容を新規レビュー済みとは表示しない。通常幅・disabled・既知子折畳み保留を維持。本人再確認と実VoiceOver・性能等はUnverified、Construction完了は未宣言。

2026-11-03 本人08cbe47bにより今回のアルバム上下キー・写真表示追随・Shift-Tab復帰後の上下操作を実機成功と確認。以下の「今回本人再確認Unverified」は回答前の履歴として保持。残りの画面幅、VoiceOver、コントラスト、実画面性能等は未確認のままで、全体成功完了は未宣言。

### 現在の判定（アルバム上下キー修正後、2026-11-03）

本人905a320cの行操作不成立を実UIで再現し、標準Listの行操作へ戻した。通常/狭幅/逆Tab再入/空一覧を確認、独立レビュー新規指摘なし。正式証跡 `.build/Native-20261103-081433-31974.xcresult`、201件成功・失敗0・スキップ0、1451/1610行=90.12%、exit0。ソース変更なしで当工程へ再開したため同じ全件を重複実行しない。以下の197件等は履歴。本人再確認はUnverified、既知子折畳み問題と実VoiceOver・性能等の未確認を維持し、Construction成功完了は宣言しない。

### 現在の判定（Tab入場の先頭選択修正後、2026-11-03）

本人607a503cの指定どおり、未選択でTab入場したFolder/Albumは先頭選択、Photoはfocusのみ。既存選択・編集保持、逆Tab・狭幅を自動検証。独立確認で新規指摘なし。正式結果 `.build/Native-20261103-010415-5544.xcresult`、全197件成功・失敗0・スキップ0、1442/1597行=90.29%、exit0。検証後の製品変更はなく、同じ全件試験を重複実行しない。以下の189件等は旧結果として保持する。

NFR4.31の今回動作の本人再確認はUnverified。既知子折畳み問題は本人判断で未修正。VoiceOver・コントラスト・実画面性能等のUnverifiedを維持し、Construction完了は宣言しない。

### 現在の判定（Tab修正後）

本人3fc70abcの入力3操作成功を保持する。静的見出しのTab停止を修正し、独立確認で新規指摘なし。正式な全件検証は `.build/Native-20261102-234310-78127.xcresult`、189件成功・失敗0・スキップ0、全製品1361/1515行=89.83%、exit0。製品ソースはその後変更しておらず、同じ検証の重複実行はしない。今回のTab移動の本人再確認はUnverified。以下の旧件数と失敗報告は履歴。

VoiceOver・コントラスト・実画面性能・外部変更等は引き続きUnverified。子フォルダ折畳み問題は本人判断で未修正。Construction成功完了とフェーズ末コミットはまだ行わない。

### 最新結果（2026-11-02 22:47 JST）

U3の入力修正後、実アプリを操作する合成データのXCUITestを含め、正式な検証は全184件成功、失敗・スキップ0、全製品1301/1457行（89.29%）。証跡 `.build/Native-20261102-224614-55105.xcresult`。以下の176件・85.95%と入力不具合の記述は修正前の履歴。本人の実ライブラリでの再確認はUnverifiedであり、NFR4.31の合格は未宣言。

親を折り畳むと選択中の子が対象から外れ、編集写真が解除され得る既知問題は本人回答fe24ba92により未修正で継続。横断照合のNFR2/NFR4/NFR5も未充足。VoiceOver、コントラスト、実測性能などの未確認条件を維持し、Construction完了は宣言しない。

2026-11-02の本人実機確認で、フォルダの左右キー展開・Command複数選択・写真のキーボード選択が失敗した。NFR4.31と該当の操作支援受け入れ条件はNot Met。既存の合成状態/描画テスト成功では入力経路の成立を示せなかったため、U3だけを再実装する。以下の従来結果は自動検証とそれ以前の確認範囲に限る。

修正後のビルドと全176件は成功。全製品行カバレッジ1168/1359=85.95%。不変操作が有効な30件として合格できる不具合は修正し、独立レビューでも修正済み・新規指摘なしを確認した。
総合の受け入れ完了はまだ宣言しない。2026-11-02に本人から起動・写真アクセス・4枚保存・再起動復元の成功を受け取った。実Photosの異常系、キーボード/VoiceOver、コントラスト、実画面反映と10往復の測定結果は未確認で、これらを含む条件はUnverified。本工程を実行中のまま結果を受け取る。

## 入力と対象

全単位の計画、手順、summary、NFR Requirements/Design、Testing Contractから60詳細NFRと横断条件を棚卸しした。単体・結合・SwiftUI描画・資源/期限・保存保護を自動検証。CIは本人承認により非適用。通常の操作履歴・画像を外部送信しない。

## Target Verification Matrix

| Target ID | Source | Expected | Actual | Evidence | Owning Stage | Verdict |
|---|---|---|---|---|---|---|
| NFR2.24 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/scalability-requirements.md:7 | 復元と確定は単一セッションで競合させず、書込みは1件ずつ。古い世代の復元結果を採用しない ／ 遅延応答・重複開始・切替/取消のテスト | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.24 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/scalability-requirements.md:8 | 破損退避は同じ原本bytesに対し重複を増やさず、1 MiBの既存読込/保存上限を維持 ／ 反復失敗/再試行で同一内容の退避再利用と過大入力拒否を確認 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR2.31 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:9 | 本人Mac、ローカル画像取得済み100枚以上、選択/解除30回以上の95%以上が入力イベント→実画面反映200ms以内 ／ 実入力と描画の時刻対応。状態更新時間だけで代用しない | 実321枚・30操作照合成功、不確かさ込み200ms以内0/30、212.448〜412.296ms | verification/real-library-measurement-20261104.md | build-and-test | Not Met |
| NFR2.32 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:10 | 先頭末尾10往復後、不要要求0が15秒以内、必要集合外の保持が増え続けない ／ 各往復の必要数、保持数、要求数、bytesを比較 | 実321枚で端点10往復、不要要求0を直後/15秒後確認、保持最大19,611,648bytesで安定 | verification/real-library-measurement-20261104.md | build-and-test | Met |
| NFR2.33 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:11 | 全生存画像と予約256MiB以下、最大8要求（表示4/検証4）、画像最大512物理pixel ／ Fakeの上限/取消/外部参照試験と実測 | 自動境界試験の上限/取消/外部参照成功、実321枚の端点10往復で保持+予約最大19,611,648bytes・不要要求0 | 205件の該当回帰＋verification/real-library-measurement-20261104.md | build-and-test | Met |
| NFR2.34 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:12 | 各画像と4枚全体15秒の絶対期限、待機列込み、通信false ／ 注入時計境界と実画像不可確認。認可ダイアログ/書込時間は対象外 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR4.31 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:13 | 許可→複数フォルダ→アルバム→写真→確定/再試行をキーボードのみで完了 ／ 矢印、Space、Tab、可視フォーカス、領域退出と復帰 | 本人が通常/狭幅の主要Tab/矢印/Space/保存操作成功を回答。権限/再試行など全経路は未確認 | manual-acceptance.md:3fc70abc/08cbe47b/93f73a38 | build-and-test | Unverified |
| NFR4.32 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:14 | VoiceOverで名称・展開・選択順・枚数・保存結果・復元と理由を確認 ／ 取得不可も理由へ到達、色のみに依存しない | 本人が名称/選択順/枚数/保存結果のVoiceOver成功を回答。復元/取得不可理由等は未確認 | manual-acceptance.md:bc01a431 | build-and-test | Unverified |
| NFR4.33 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:15 | 1280×800pt、640×560pt、820pt境界で全操作に到達 ／ 4枠と操作を保持、長名全名、領域/フォーカスID保持 | 通常/狭幅の主要操作と広幅復帰時の選択保持を本人確認。厳密な640×560pt/820pt境界/長名の全条件は未確認 | manual-acceptance.md:2826d463/93f73a38＋205件の画面回帰 | build-and-test | Unverified |
| NFR4.34 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:16 | 通常文字4.5:1、大文字/操作要素3:1以上 ／ ライト/ダークとコントラスト設定で測定 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR2.7 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/scalability-requirements.md:9 | 2フォルダ以上・3階層以上、100枚以上の写真を受け入れ用データとする。固定の全件切捨てを設けない ／ Fakeと本人の実データで確認。100枚は最大件数ではなく検証の下限 | 実321枚、本人の複数フォルダ操作成功あり。実データの3階層以上条件の個別確認は未報告 | manual-acceptance.md＋verification/real-library-measurement-20261104.md | build-and-test | Unverified |
| NFR2.8 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/scalability-requirements.md:10 | 階層探索は訪問済みIDを管理し、同じフォルダ/アルバムの重複と循環を打ち切る。UIの画像要求は必要な範囲へ限定する ／ 深い階層・親子重複・同名異ID・循環・遅延を自動テスト | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR2.9 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/scalability-requirements.md:11 | 確定保存の同時実行は最大1件。画像要求は有限の同時数と有限の保持予算で制御 ／ 重複確定と高速切替のテスト。同時数の具体値はNFR Designで決定 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.21 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/observability-requirements.md:7 | TDD・製品全体行カバレッジ80%以上・統合前ローカルビルド/自動テストを維持する。CIは省略済み ／ U2専用テストと全単位テストで対象/コミット/結果を記録 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.22 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/observability-requirements.md:8 | 診断は失敗分類のみ。本人の保存/再起動/欠損確認と自動検証を区別し、未確認を成功にしない ／ 日本語手順・未確認欄・匿名指標。個人ID/名称/画像なし | 診断分類と保存/再起動の本人成功・欠損未確認を分離して記録。個人データを成果物へ転載なし | manual-acceptance.md、test-results.md、匿名の実測記録＋205件のログ回帰 | build-and-test | Met |
| NFR3.31 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/security-requirements.md:9 | 写真ライブラリ変更なし、画像取得通信なし、写真本体の恒久保存/外部送信なし ／ 境界と呼出しのコード確認、取得不可時の動作 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.32 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/security-requirements.md:10 | 保存置換の実成功と確定の写し/保存状態を一致させ、完了直後の認可変化・呼出し取消で成功を保存失敗へ変えない ／ 遅延保存Fakeで権限喪失/取消を競合、正常完了と実書込失敗を別検証 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.33 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/security-requirements.md:11 | 破損・未知版の原本保護、明示確定時の検証済み破損退避、symlink/過大拒否を維持 ／ U1/U2回帰。UIから直接書込しない | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.31 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/security-requirements.md:12 | 通常診断は最小失敗分類のみ。性能計測は本人の測定時に集計値だけ扱い、ID・名称・画像・原本bytesを出力しない ／ 計測出力/通常ログ確認 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.1 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/observability-requirements.md:12 | 通常は失敗の分類のみを診断へ記録し、操作履歴を常時蓄積しない ／ ログ捕捉で写真ID・名称・画像・低水準エラー文字列を除外確認 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.2 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/observability-requirements.md:13 | 検証時だけ入力から画面反映までの経過時間・要求開始/完了/取消数・現在の不要要求数・画像保持推定量を一時計測 ／ ローカル計測。持続時間には単調時計を使う。通常の製品ログから性能達成を推定しない | 実30操作の単調時計対応と10往復の資源を計測。要求開始/完了/取消総数の実測は未確認 | verification/real-library-measurement-20261104.md | build-and-test | Unverified |
| NFR5.3 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/observability-requirements.md:14 | TDDの意図した失敗と成功、対象と除外根拠を含む行カバレッジ80%以上、統合前CIを各単位で記録 ／ 未実施・実行不能・失敗・成功を区別。対象は製品Swiftソース全体を基本とし、自動生成コード以外の除外は根拠を計画で明示し基準を下げない | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.4 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/observability-requirements.md:15 | 許可・写真アプリの並び・実画像・画面・操作支援は本人の実機確認欄へ記録 ／ 日本語のXcode中心手順。実画像や個人IDを成果物へ転載せず、確認条件と結果だけを残す | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR5.5 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/observability-requirements.md:16 | 具体的な検証コマンドは最初の実装単位の検証前に本人確認し、未承認の例を承認済みとして扱わない ／ 検証の承認記録と実行結果を対応づける | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR1.31 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/tech-stack-decisions.md:9 | 既存Swift6/SwiftUI/PhotoKit、本人Mac、既存5責務とC1〜C4を維持 ／ 表示のために所有者・保存形式・外部依存を増やさない | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.32 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/tech-stack-decisions.md:10 | 各層TDD、全製品行カバレッジ80%以上、全既存回帰とU3のUI/状態/資源試験 ／ 統合前ローカルで確認、UI/アダプタも分母 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.33 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/tech-stack-decisions.md:11 | 日本語のXcode中心手順と本人確認表、実OS/画面幅/入力/VoiceOver/測定結果を記録 ／ 自動試験・本人観察・未確認を分離 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR3.25 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/reliability-requirements.md:7 | 保存後の新セッションでは全参照と4画像が有効なら順序/日時/確定状態を復元し、一部欠損では全写真クリアと有効フォルダ保持 ／ 正常/欠損1枚/所属変更/アルバム削除/対象外/画像不可を結合テスト | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.26 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/reliability-requirements.md:8 | 退避の作成・内容検証後にだけ新確定を原子的置換。退避/置換の失敗では成功表示せず旧原本と編集を保持 ／ 各I/O段階の失敗注入と強制中断相当の境界テスト | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.27 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/reliability-requirements.md:9 | 再試行は本人操作で毎回再検証し、結果未確定の書込みを二重開始しない。編集は終了時保存しない ／ 失敗/重複/遅延/終了再開のテスト | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR4.21 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/reliability-requirements.md:10 | 権限・復元中・復元成功・欠損・破損・未知版・書込失敗の案内と次の操作を区別 ／ 状態投影を自動検証。最終VoiceOver/キーボード全経路はU3 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR3.21 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/security-requirements.md:7 | 権限未許可では復元のライブラリ参照を進めない。写真変更・画像取得通信・画像恒久保存・外部送信なし ／ Fake呼出し検査とコード確認 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.22 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/security-requirements.md:8 | 破損/未知版/読込失敗は原本保護。破損確定の退避は本人の新しい確定操作に限り、未知版上書きは常に拒否 ／ 正常/構文破損/意味破損/未知版/I/O失敗の原本bytes比較 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.23 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/security-requirements.md:9 | 退避は専用領域の固定方式で原本bytesだけを保持し、名称やIDからパスを組み立てない。個人内容はログに記録しない ／ パス型とログ捕捉検査。退避を履歴UIへ拡張しない | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR2.21 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/performance-requirements.md:7 | 復元の4枚画像検証は全体15秒、各要求15秒との早い方で期限判定。受付・キュー待ちを含む絶対期限ちょうど以降は成功不採用 ／ 注入時計で期限前/同時/後・遅延応答を検証 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR2.22 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/performance-requirements.md:8 | 復元・再確定の画像も既存256 MiB予算と最大8同時要求へ含める。生存する全バッファと予約を計上 ／ 返却画像保持・取消・世代切替・小予算の回帰 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR2.23 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/performance-requirements.md:9 | 復元の探索・I/OでUIを不要に停止しない。復元途中の編集は禁止。画面反映95%以上200msと10往復測定はU3 ／ 遅延Fakeで独立状態案内を確認。U3最終実測を代替しない | 非同期/取消の自動境界は成功。最終実測の200ms条件がNot Met、10往復はMet | 205件の該当回帰＋verification/real-library-measurement-20261104.md | build-and-test | Not Met |
| NFR1.21 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/tech-stack-decisions.md:7 | 既存SwiftUI/macOSアプリと5責務・C1〜C4へ追加し、別DB・外部依存・サービスを追加しない ／ 導入済みXcode/Swift6でビルド、U1互換の版1形式を継続 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR1.1 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:12 | アプリ ／ Swift・SwiftUIのmacOSネイティブアプリ。表示名ひとつづり、Xcode Hitotsuzuri、アプリ型HitotsuzuriApp ／ アプリプロジェクトは未生成。ビルド・起動は後続で確認 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR1.2 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:13 | ツールチェーン ／ 本人の現在のMacと導入済みXcodeを使う。今回読取りでXcode 27.2 build27B52、Apple Swift6.4.2、arm64/macos27.2 targetを確認 ／ 上流の27.1/6.4は以前の観測。最新版への更新作業は行っていない。最低OS・言語モードはNFR Designで具体化 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR1.3 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:14 | ライブラリ ／ OS標準の写真APIを読み取り用途で使用し、5責務をFakeに置換できる境界を保つ ／ 認可・階層・順序・画像オプションを対象SDKでコンパイルし、実写真の順序とローカル取得は本人確認 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR1.4 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:15 | 保存 ／ 外部DBを追加せず標準の構造化シリアライズと専用ファイルを使う。版付きの設定と確定を分離 ／ JSONを第一候補として、固定パス・日時・原子的置換・退避をNFR Designで確定。未検証の原子性を保証しない | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.6 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:16 | 自動検証 ／ Xcode同梱のSwift Testingを単体/統合テストの第一候補、XCTestを必要なUIテストの候補とする。外部パッケージを必須にしない ／ 実際のテストターゲットとカバレッジ取得・UI計測をCode Generation計画で検証。TDDを維持 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.7 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:17 | CI ／ 既決の専用MacでのCIを利用する。GitHub Actionsのself-hosted runnerを準備候補とする ／ まだ登録・環境構築・実行していない。公開範囲と隔離・実行元制限を設定前に確認 | the plan runs no CI Pipeline | change-decisions/2026-10-31-local-verification.md | build-and-test | N/A |
| NFR2.1 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/performance-requirements.md:9 | 画像取得完了後の選択・解除は入力イベントから表示反映まで、30操作以上の95%以上が200ms以内 ／ 本人のMac・100枚以上のローカル写真。計測器・記録手順をNFR Designで決定しU3で実測。Store更新時間で代用しない | 実321枚・30操作照合成功、不確かさ込み200ms以内0/30、212.448〜412.296ms | verification/real-library-measurement-20261104.md | build-and-test | Not Met |
| NFR2.2 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/performance-requirements.md:10 | ローカル画像1要求は受付から15秒以内に最終成功・取得不可・失敗・取消のいずれかへ収束 ／ 仮想時計による境界・遅延テストと実機確認。暫定プレビューで時間を延長しない | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR2.3 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/performance-requirements.md:11 | 確定前4枚の画像検証全体は開始から15秒以内。1件ごとの15秒を足して60秒にはしない ／ 4件の成功・一部停止・期限ちょうどの競合テスト。単調時計の期限以降の応答は不採用 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR2.4 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/performance-requirements.md:12 | アプリ所有のデコード済み表示画像は推定256 MiB以下。一覧・4枠・検証画像を含む ／ 実バッファの推定byte数を一元集計し超過前に解放・要求制御。同一バッファの重複参照は二重計上せず、別コピーは計上。OS内部・プロセス全体のメモリは別記録 | 実321枚、保持と予約合計最大19,611,648bytesで256MiB未満、10往復/15秒後も安定 | 205件の生存バッファ回帰＋verification/real-library-measurement-20261104.md | build-and-test | Met |
| NFR2.5 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/performance-requirements.md:13 | 100枚以上で10往復スクロール後も保持量は上限以下、不要要求が残り続けない ／ U3で実測。最終スクロール後15秒以内に不要要求0を確認。画像API内部の保持量をアプリ側と混同しない | 実321枚で端点10往復、不要要求0を直後/15秒後確認、保持最大19,611,648bytesで安定 | verification/real-library-measurement-20261104.md | build-and-test | Met |
| NFR2.6 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/performance-requirements.md:14 | 探索・画像処理・ファイルI/OでUIを不必要に止めない。取得中も依存しない操作が可能 ／ 非同期境界・取消・古い応答を自動検証。保存中の編集禁止は意図した制約。初期読込の固定時間保証は設けず、件数と経過時間を測定する | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR3.6 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/reliability-requirements.md:9 | 保存の成功は固定内容が専用領域へ置換完了した場合のみ。設定と確定は別レコードで、書込みは直列化 ／ 成功・ディスク書込失敗・中断を注入し、旧正常内容または新しい正常内容が残り、半端な内容を正常扱いしない | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.7 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/reliability-requirements.md:10 | 書込み失敗で旧確定と編集を失わず、本人の再試行時は再検証する。結果未確定の保存を二重に開始しない ／ 遅延・重複・失敗・古い操作IDのテスト。画像の15秒を保存の打切りに流用しない | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.8 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/reliability-requirements.md:11 | 破損・未知版・読込失敗を保存なしと同一扱いにしない。未知版書込は禁止し原本を保持 ／ 破損・欠損フィールド・未対応版・I/O失敗を自動テスト。U1では危険な上書きを拒否、退避して再確定する回復経路はU2 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.9 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/reliability-requirements.md:12 | 起動・設定変更・参照欠損だけで旧確定を自動破棄/上書きしない。復元時の全写真クリアと有効フォルダ保持はU2で完成 ／ U1の書込境界テストとU2の正常/欠損復元テスト | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR4.1 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/reliability-requirements.md:13 | 取得中・空・取得不可・原因不明・保存失敗を区別し、次の操作を日本語で案内する ／ U1は基本表示、U3でキーボードとVoiceOver・長い名称・狭幅を完成 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR3.1 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/security-requirements.md:12 | 写真ライブラリ変更APIをアプリの操作として持たせない。権限未許可ではメタデータ・画像取得しない ／ 境界Fakeの呼出し検査と製品コード確認。本人のOS許可・拒否確認 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR3.2 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/security-requirements.md:13 | すべての画像取得で通信を明示的に禁止し、失敗・取消・時間超過でも許可へ切り替えない ／ 画像境界のオプション検査・取得不可の自動テスト・本人のオフライン確認 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR3.3 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/security-requirements.md:14 | 永続化は設定・アルバム情報・写真ID4件と順序・日時等のみ。画像本体の恒久保存・外部送信なし ／ 保存形式とファイルの往復テスト、コードと生成ファイル確認 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.4 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/security-requirements.md:15 | 保存先はアプリ専用領域。名前・外部IDからファイルパスを組み立てず、固定ファイル名を使用 ／ 名前の空白・引用符・改行・Unicode・不透明IDのテスト。IDや名称はデータとして扱う | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.5 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/security-requirements.md:16 | 通常の診断は失敗種別だけ。写真ID・フォルダ/アルバム名称・画像をログへ含めない ／ 診断出力捕捉テスト。UIの必要な名称表示と診断ログを区別 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| CONTRACT-COVERAGE | 全単位Testing Contract | 全製品行80%以上 | 1474/1634=90.21% | .build/Native-20261103-234223-36633.xcresult / bash scripts/verify-native.sh exit0 | build-and-test | Met |
| CONTRACT-CI | 全単位Testing Contract | 統合前CI | the plan runs no CI Pipeline | 本人承認のCI省略決定 | ci-pipeline（非実行） | N/A |
| CONTRACT-TDD | 各単位tdd-evidence | runner先行・層別Red→Green→Refactor | 記録あり、各RedとGreenのxcresultを保持 | 各単位tdd-evidence.md | build-and-test | Met |


## 証拠と未確認

E-ALL現在値は .build/All-20261101-125015-88429.xcresult。U1 60、U2 48、U3 68、全176件、失敗0、スキップ0、承認済みverify-all.sh終了コード0。修正後P-MEASUREはacceptedOperations=0、passed=false、終了コード0。
本人確認は[最初の確認](manual-acceptance.md)と[U3の詳細手順](../u3-native-experience/code-generation/manual-verification.md)。実機の未観測をFakeや描画テストの成功で置き換えない。性能検証の後続stageは計画にないため、本工程が確認結果を所有する。

## 横断追跡

機械センサーはNFR2/NFR4/NFR5について、以前の単位に残るDeferredも未被覆として報告している。cross-unit-traceability.mdに出力を保存した。現在U3の実装/試験への対応と、実機の未確認を区別し、旧単位の固定済み記録を無断で成功へ変えていない。

## フェーズとGit

Constructionは本人の実機確認待ちを含めて進行中。完了後に本人指定どおり関連するソース・記録をGitへコミットする。現時点では完了コミットを作っていない。入力資料・AI-DLC導入ファイル等の既存未追跡ファイルを無差別に追加しない。

