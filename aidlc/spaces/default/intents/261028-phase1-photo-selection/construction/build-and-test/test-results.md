# Build and Test 実行結果

## 速度未達を残した承認確認

2026-11-04 本人9f8f65c4が速度未達の受入と承認確認への移行を選択。NFR2.31/NFR2.1はNot Metのままで、成功に書き換えない。追加の測定方式改善は行わない。他のUnverified・横断追跡FAIL・既知子折畳み問題は明示して最終の本人判断を待つ。今回回答はBuild and Test全体やConstructionフェーズ承認ではない。

最終の製品自動試験は205件成功、90.21%。その後の補助測定スクリプトだけの起動/診断/数値OCR/時間内訳変更は、ビルド成功と画面不使用自己試験22件、実30操作全照合で確認した。製品ソースは無変更のため全UIを追加反復しない。対象名や写真・個人IDを記録へ転記しない。Loop-Back Logと過去の失敗・未確認履歴は保持する。

2026-11-04代理実機測定はverification/real-library-measurement-20261104.mdに保存。実321枚、通常20msクリック30操作は対応30・不成立0だが、不確かさ込み200ms以内0件（212.448〜412.296ms）でNFR2.31/NFR2.1はNot Met。10往復は各端点で不要要求0、最大保持＋予約19,611,648bytes、終了15秒後も安定でNFR2.32/NFR2.5はMet。最初のOCR不成立と長押し試行も履歴として保持。測定方法のOCR負荷/採取間隔が結果へ寄与する候補を示し、アプリが原因と断定しない。

改善候補は測定文字領域だけのOCRとフレーム受取/認識の分離。見積20〜40分、追加費用0、測定文字の範囲誤りによる欠測リスク。閾値・同frame照合・欠測拒否は維持。自律ループ3/3のため本人の方針を待ち、未達を残したまま成功完了しない。

2026-11-04 本人bc01a431が、VoiceOverの領域/名称/写真選択順/枚数/保存結果の読み上げ成功を回答。対応する実機確認範囲を成功として記録し、取得不可理由や実測性能・コントラスト等の未確認は維持する。

## 現在の結果（狭幅の確定到達修正後）

本人93f73a38が狭幅Album/PhotoからTab→確定→Space保存とShift-Tab復帰の成功を回答。今回の実機不具合は確認成功として解消。以下の「本人再確認Unverified」は回答前の記録。VoiceOver等の未確認条件は維持。

本人38ec67b9が見えている確定へAlbum/Photo画面からTabで到達できないと確認。既承認作業の入力経路の不具合として直接修正。狭幅で確定有効時のAlbum前進Tabを確定へ接続し、未完了の領域復帰要求を取り消す。確定からShift-Tabは現在領域の記憶IDへ戻す。通常幅・disabled分岐・onAppearは維持。

実UIの修正前3件中2失敗を記録後、修正後4件成功。承認済み `bash scripts/verify-native.sh` の全体実行は一度でexit0、`.build/Native-20261103-234223-36633.xcresult`、205成功・失敗0・スキップ0、全製品1474/1634行=90.21%。製品変更はPickerContentとNativeInputTestsのみ。以下の201件等は旧結果。今回の変更は前レビュー後の本人指示による直接修正で、レビュー済みの内容と同一とは扱わない。新しい計画/試行/レビュー/manifest操作は行っていない。

本人再確認はUnverified。既知子折畳み問題と実VoiceOver・コントラスト・性能等の未確認を維持し、総合成功完了は宣言しない。

## 現在の結果（アルバム上下キー修正後）

本人08cbe47bが修正後のTab入場→アルバム上下移動・写真表示追随と、写真からShift-Tab復帰後の上下操作の成功を回答。今回の実機失敗は再確認成功として解消。NFR4.31のこの操作部分は成功だが、許可/再試行等の全経路・その他の未確認条件まで成功に広げない。

本人905a320cの枠focusのみで行操作不能を実Redで確認し修正。独立U3 71件・UI22件・全体201件成功、新規指摘なし。正式な承認済み `bash scripts/verify-native.sh` はexit0、`.build/Native-20261103-081433-31974.xcresult`、201成功・失敗0・スキップ0、全製品1451/1610行=90.12%。この結果を現在のカバレッジMetの証拠とし、以下の旧件数/割合/不具合報告は履歴。ソース無変更のため同じ全件実行を重複しない。

本人の実ライブラリ再確認はUnverified。既知子折畳み問題、実VoiceOver・コントラスト・実画面性能等の未確認は維持し、総合成功完了は宣言しない。正式証跡と修正根拠はverification/album-arrow-checkpoint-20261103.md。既存Loop-Back Logは保持する。

## 現在の結果（Tab入場の先頭選択修正後、2026-11-03）

本人指定の先頭選択と写真focusのみ・既存選択/編集保持を実装。独立確認でU3 71件・UI18件・全体197件成功、新規指摘なし。本人がXcodeのUI操作許可後、正式な `bash scripts/verify-native.sh` がexit0。`.build/Native-20261103-010415-5544.xcresult`、197成功・失敗0・スキップ0、全製品1442/1597行=90.29%。証跡ID1492368c-60bb-4441-a4a9-5deefe8d7b37で通常単位checkpoint承認済み。現在の全体カバレッジはこの証跡でMet、以下の旧件数・割合は履歴。ソース無変更のため同じ試験を重複実行しない。

本人再確認はUnverified。既知子折畳み問題とVoiceOver・実画面性能等の未確認を維持、総合成功完了は宣言しない。環境停止と許可後成功はverification/tab-entry-review-environment-20261103.mdに分けて記録。既存Loop-Back Logは維持し、今回本人の動作変更要求はchange-decisions/2026-11-02-tab-entry-selection.mdに記録した。

## 現在の結果（Tab修正後の正式証跡）

`.build/Native-20261102-234310-78127.xcresult`、承認済み `bash scripts/verify-native.sh` exit0、189件成功・失敗0・スキップ0、全製品1361/1515行=89.83%。直前の独立レビューと正式検証後に製品変更はなく、その結果を再開時の証拠として採用する。全体カバレッジの現在値はこの結果で、以下の旧表は履歴。通常単位checkpointは正式証跡ID1ec665af-8a92-4ba2-9a3f-c13a935b6eacで承認済み。

本人の基本フローと入力3操作成功を保持。今回のTab見出し修正は自動試験で成功、本人再確認はUnverified。実VoiceOver・実画面性能等の未確認条件は維持し、成功完了の判定はしない。子フォルダ折畳み問題は本人が現状継続を選択済み。

## Tab修正のコード生成検証（2026-11-02）

Loop-back 3の修正では静的見出しをTab順から外し、アルバム一覧の焦点所有と写真退出・空領域復帰を整理した。追加5件の実UI回帰が成功し、承認済み `bash scripts/verify-native.sh` はexit0。`.build/Native-20261102-232557-72550.xcresult` は189件成功・失敗0・スキップ0（既存176＋UI13）、全製品1361/1515行=89.83%。この結果はコード生成側の検証で、当工程の最終判定は再開後に更新する。

実Tab直後のSpace/矢印が写真選択・フォルダ展開・領域移動・確定保存へ反映されることを証拠とする。公開AXで全停止先を直接列挙する観測は成立せず、その補助コードは撤去済み。本人によるTab再確認と実VoiceOverは未確認。子フォルダ折畳みの既知問題は未変更。

## 最新結果 2026-11-02 22:47 JST

本人回答3fc70abc: 修正した3操作はすべて成功。ただしTab移動で操作不能な「フォルダ」「アルバム」「写真」の見出しへ停止する。NFR4.31は入力3操作の成功を記録し、Tab順序の追加不具合はNot Metとして別に修正する。

## Loop-Back Log 追加記録

### Loop-back 3 — 2026-11-02

- Diagnosis: PickerContent.headingが静的Textへ明示的にfocusable/focusedを付け、通常のTab順序へ入れている。写真領域のTab退出先にも静的な選択見出しを使っている。
- Root-cause stage: code-generation、u3-native-experienceのキーボードフォーカス経路。
- Planned fix: 静的見出しを通常のTab順序から外し、VoiceOverの見出し意味は保持する。空領域/確定不可時のフォーカス先も操作可能な要素へ整理し、実UI試験でTabとShift-Tabの停止先・領域退出/復帰を確認する。既知の子フォルダ折畳み問題とU1/U2は変更しない。
- Estimated impact: 小規模、20〜40分、追加費用0。Tab退出・空領域・狭幅復帰の回帰リスクがあるため、先に実UI回帰をRedで確認し、全件テストを実行する。実装前に新しい試行の計画を本人確認する。

承認済み `bash scripts/verify-native.sh` の正式検証はexit0。`.build/Native-20261102-224614-55105.xcresult`、U1 60件・U2 48件・U3 68件・実アプリ合成データUI8件、全184件成功、失敗・スキップ0。全製品1301/1457行=89.29%で80%条件を満たす。以降の旧件数・カバレッジは履歴。現在のCONTRACT-COVERAGE実績はこの結果に更新する。

入力修正後の本人実ライブラリの再確認はUnverified。NFR4.31の過去のNot Met報告を、自動試験だけで実機合格へ変更しない。親折畳みで選択中の子と編集写真が解除され得る既知問題は、本人回答fe24ba92により未修正で継続。VoiceOver・コントラスト・実画面性能等のUnverifiedは維持する。横断センサーはNFR2/NFR4/NFR5でpass=falseのまま。成功完了は未宣言、本人確認待ち。

UI起動時に保存済み狭幅が持ち越される試験環境問題は、各試験が実ウィンドウを通常幅へ戻す準備を追加して解消。レビュー後の変更は試験起動準備と調査記録のみ、製品コード・操作の期待値・既知問題は変更していない。詳細は `../../verification/native-checkpoint-20261102.md`。Loop-Back Logは保持する。

## 初回実行 2026-11-01

| Check | Command / Evidence | Result |
|---|---|---|
| E-BUILD | build-instructions.mdのxcodebuild build | BUILD SUCCEEDED、exit0 |
| E-U1 | U1専用手順、.build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.01_12-32-30-+0900.xcresult | 60成功、失敗0、exit0 |
| E-U2 | U2専用手順、.build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.01_12-32-42-+0900.xcresult | 48成功、失敗0、exit0 |
| E-U3 | U3専用手順、.build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.01_12-32-54-+0900.xcresult | 51成功、失敗0、exit0 |
| E-ALL | bash scripts/verify-all.sh、.build/All-20261101-123314-79948.xcresult | 全159成功、失敗0、スキップ0、1113/1311=84.90%、exit0 |
| P-MEASURE | 下記の公開境界プローブ | 不変の空選択30回でpassed=true、期待違反exit1 |
| S-PHOTOS | rg -n 'performChanges\|isNetworkAccessAllowed' Hitotsuzuri HitotsuzuriCore | 変更API一致なし、画像オプションfalseを確認 |
| Traceability | aidlc engine sensor-traceability --stage build-and-test | pass=false、NFR2/NFR4/NFR5未被覆。詳細はcross-unit-traceability.md |

単位別と全体実行は同じテストを含むため件数を加算しない。Xcodeが出したSimulator接続等の警告はmacOSビルド成功と区別した。個人写真や保存原本を使っていない。

## P-MEASURE 再現コマンド

```bash
swift -module-cache-path .build/ProbeModuleCache -F .build/DerivedData/Build/Products/Debug -framework HitotsuzuriCore -e 'import Foundation; import HitotsuzuriCore; MainActor.assumeIsolated { let native=NativeMeasurement(enabled:true); var frames=FrameMeasurement(); for _ in 1...30 { native.record(eventSeconds:ProcessInfo.processInfo.systemUptime,positions:[]); let s=native.stamp!; frames.input(sequence:s.sequence,ticks:s.inputTicks); frames.frame(sequence:s.sequence,ticks:s.inputTicks+1,interval:1,selectionMatches:true,calibrated:true) }; print("unchangedPositions=[] acceptedOperations=\(frames.inputs.count) passed=\(frames.passed)"); if frames.passed { exit(1) } }'
```

出力: `unchangedPositions=[] acceptedOperations=30 passed=true`。これは実画面性能の測定ではなく、件数判定の不正な成功を示す合成の再現。製品ソースは変更せず既存ビルドの公開型を実行した。

## 初回の目標判定（履歴）

| Target ID | Source | Expected | Actual | Evidence | Owning Stage | Verdict |
|---|---|---|---|---|---|---|
| NFR2.24 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/scalability-requirements.md:7 | 復元と確定は単一セッションで競合させず、書込みは1件ずつ。古い世代の復元結果を採用しない ／ 遅延応答・重複開始・切替/取消のテスト | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.24 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/scalability-requirements.md:8 | 破損退避は同じ原本bytesに対し重複を増やさず、1 MiBの既存読込/保存上限を維持 ／ 反復失敗/再試行で同一内容の退避再利用と過大入力拒否を確認 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR2.31 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:9 | 本人Mac、ローカル画像取得済み100枚以上、選択/解除30回以上の95%以上が入力イベント→実画面反映200ms以内 ／ 実入力と描画の時刻対応。状態更新時間だけで代用しない | 不変の30操作がpassed=true（実測も未確認） | P-MEASURE再現 | build-and-test | Not Met |
| NFR2.32 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:10 | 先頭末尾10往復後、不要要求0が15秒以内、必要集合外の保持が増え続けない ／ 各往復の必要数、保持数、要求数、bytesを比較 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR2.33 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:11 | 全生存画像と予約256MiB以下、最大8要求（表示4/検証4）、画像最大512物理pixel ／ Fakeの上限/取消/外部参照試験と実測 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR2.34 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:12 | 各画像と4枚全体15秒の絶対期限、待機列込み、通信false ／ 注入時計境界と実画像不可確認。認可ダイアログ/書込時間は対象外 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR4.31 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:13 | 許可→複数フォルダ→アルバム→写真→確定/再試行をキーボードのみで完了 ／ 矢印、Space、Tab、可視フォーカス、領域退出と復帰 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR4.32 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:14 | VoiceOverで名称・展開・選択順・枚数・保存結果・復元と理由を確認 ／ 取得不可も理由へ到達、色のみに依存しない | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR4.33 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:15 | 1280×800pt、640×560pt、820pt境界で全操作に到達 ／ 4枠と操作を保持、長名全名、領域/フォーカスID保持 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR4.34 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:16 | 通常文字4.5:1、大文字/操作要素3:1以上 ／ ライト/ダークとコントラスト設定で測定 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR2.7 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/scalability-requirements.md:9 | 2フォルダ以上・3階層以上、100枚以上の写真を受け入れ用データとする。固定の全件切捨てを設けない ／ Fakeと本人の実データで確認。100枚は最大件数ではなく検証の下限 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR2.8 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/scalability-requirements.md:10 | 階層探索は訪問済みIDを管理し、同じフォルダ/アルバムの重複と循環を打ち切る。UIの画像要求は必要な範囲へ限定する ／ 深い階層・親子重複・同名異ID・循環・遅延を自動テスト | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR2.9 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/scalability-requirements.md:11 | 確定保存の同時実行は最大1件。画像要求は有限の同時数と有限の保持予算で制御 ／ 重複確定と高速切替のテスト。同時数の具体値はNFR Designで決定 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.21 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/observability-requirements.md:7 | TDD・製品全体行カバレッジ80%以上・統合前ローカルビルド/自動テストを維持する。CIは省略済み ／ U2専用テストと全単位テストで対象/コミット/結果を記録 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.22 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/observability-requirements.md:8 | 診断は失敗分類のみ。本人の保存/再起動/欠損確認と自動検証を区別し、未確認を成功にしない ／ 日本語手順・未確認欄・匿名指標。個人ID/名称/画像なし | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR3.31 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/security-requirements.md:9 | 写真ライブラリ変更なし、画像取得通信なし、写真本体の恒久保存/外部送信なし ／ 境界と呼出しのコード確認、取得不可時の動作 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.32 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/security-requirements.md:10 | 保存置換の実成功と確定の写し/保存状態を一致させ、完了直後の認可変化・呼出し取消で成功を保存失敗へ変えない ／ 遅延保存Fakeで権限喪失/取消を競合、正常完了と実書込失敗を別検証 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.33 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/security-requirements.md:11 | 破損・未知版の原本保護、明示確定時の検証済み破損退避、symlink/過大拒否を維持 ／ U1/U2回帰。UIから直接書込しない | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.31 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/security-requirements.md:12 | 通常診断は最小失敗分類のみ。性能計測は本人の測定時に集計値だけ扱い、ID・名称・画像・原本bytesを出力しない ／ 計測出力/通常ログ確認 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.1 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/observability-requirements.md:12 | 通常は失敗の分類のみを診断へ記録し、操作履歴を常時蓄積しない ／ ログ捕捉で写真ID・名称・画像・低水準エラー文字列を除外確認 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.2 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/observability-requirements.md:13 | 検証時だけ入力から画面反映までの経過時間・要求開始/完了/取消数・現在の不要要求数・画像保持推定量を一時計測 ／ ローカル計測。持続時間には単調時計を使う。通常の製品ログから性能達成を推定しない | 不変の30操作がpassed=true（実測も未確認） | P-MEASURE再現 | build-and-test | Not Met |
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
| NFR2.23 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/performance-requirements.md:9 | 復元の探索・I/OでUIを不要に停止しない。復元途中の編集は禁止。画面反映95%以上200msと10往復測定はU3 ／ 遅延Fakeで独立状態案内を確認。U3最終実測を代替しない | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR1.21 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/tech-stack-decisions.md:7 | 既存SwiftUI/macOSアプリと5責務・C1〜C4へ追加し、別DB・外部依存・サービスを追加しない ／ 導入済みXcode/Swift6でビルド、U1互換の版1形式を継続 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR1.1 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:12 | アプリ ／ Swift・SwiftUIのmacOSネイティブアプリ。表示名ひとつづり、Xcode Hitotsuzuri、アプリ型HitotsuzuriApp ／ アプリプロジェクトは未生成。ビルド・起動は後続で確認 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR1.2 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:13 | ツールチェーン ／ 本人の現在のMacと導入済みXcodeを使う。今回読取りでXcode 27.2 build27B52、Apple Swift6.4.2、arm64/macos27.2 targetを確認 ／ 上流の27.1/6.4は以前の観測。最新版への更新作業は行っていない。最低OS・言語モードはNFR Designで具体化 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR1.3 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:14 | ライブラリ ／ OS標準の写真APIを読み取り用途で使用し、5責務をFakeに置換できる境界を保つ ／ 認可・階層・順序・画像オプションを対象SDKでコンパイルし、実写真の順序とローカル取得は本人確認 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR1.4 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:15 | 保存 ／ 外部DBを追加せず標準の構造化シリアライズと専用ファイルを使う。版付きの設定と確定を分離 ／ JSONを第一候補として、固定パス・日時・原子的置換・退避をNFR Designで確定。未検証の原子性を保証しない | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.6 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:16 | 自動検証 ／ Xcode同梱のSwift Testingを単体/統合テストの第一候補、XCTestを必要なUIテストの候補とする。外部パッケージを必須にしない ／ 実際のテストターゲットとカバレッジ取得・UI計測をCode Generation計画で検証。TDDを維持 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.7 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:17 | CI ／ 既決の専用MacでのCIを利用する。GitHub Actionsのself-hosted runnerを準備候補とする ／ まだ登録・環境構築・実行していない。公開範囲と隔離・実行元制限を設定前に確認 | the plan runs no CI Pipeline | change-decisions/2026-10-31-local-verification.md | build-and-test | N/A |
| NFR2.1 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/performance-requirements.md:9 | 画像取得完了後の選択・解除は入力イベントから表示反映まで、30操作以上の95%以上が200ms以内 ／ 本人のMac・100枚以上のローカル写真。計測器・記録手順をNFR Designで決定しU3で実測。Store更新時間で代用しない | 不変の30操作がpassed=true（実測も未確認） | P-MEASURE再現 | build-and-test | Not Met |
| NFR2.2 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/performance-requirements.md:10 | ローカル画像1要求は受付から15秒以内に最終成功・取得不可・失敗・取消のいずれかへ収束 ／ 仮想時計による境界・遅延テストと実機確認。暫定プレビューで時間を延長しない | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR2.3 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/performance-requirements.md:11 | 確定前4枚の画像検証全体は開始から15秒以内。1件ごとの15秒を足して60秒にはしない ／ 4件の成功・一部停止・期限ちょうどの競合テスト。単調時計の期限以降の応答は不採用 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR2.4 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/performance-requirements.md:12 | アプリ所有のデコード済み表示画像は推定256 MiB以下。一覧・4枠・検証画像を含む ／ 実バッファの推定byte数を一元集計し超過前に解放・要求制御。同一バッファの重複参照は二重計上せず、別コピーは計上。OS内部・プロセス全体のメモリは別記録 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR2.5 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/performance-requirements.md:13 | 100枚以上で10往復スクロール後も保持量は上限以下、不要要求が残り続けない ／ U3で実測。最終スクロール後15秒以内に不要要求0を確認。画像API内部の保持量をアプリ側と混同しない | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
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
| CONTRACT-COVERAGE | 全単位Testing Contract | 全製品行80%以上 | 1113/1311=84.90% | E-ALL | build-and-test | Met |
| CONTRACT-CI | 全単位Testing Contract | 統合前CI | the plan runs no CI Pipeline | 本人承認のCI省略決定 | ci-pipeline（非実行） | N/A |
| CONTRACT-TDD | 各単位tdd-evidence | runner先行・層別Red→Green→Refactor | 記録あり、各RedとGreenのxcresultを保持 | 各単位tdd-evidence.md | build-and-test | Met |


## 未確認

本人の実キーボード/VoiceOver、コントラスト、実Photosでの権限・順序・取得・保存/再起動・外部削除、画面採取/OCRと30操作・10往復の性能はUnverified。後続の性能検証stageがないため、本工程で本人の結果が必要。測定不具合の修正後も自動的に合格へ変更しない。

## Loop-Back Log

### Loop-back 1 — 2026-11-01T03:34:00Z

- Diagnosis: 選択不変でもNativeMeasurement.recordが連番を増やし、FrameMeasurementが同じ選択位置の30件を合格にできる。
- Root-cause stage: code-generation、u3-native-experienceの測定入口と測定対象の不変条件。
- Planned fix: 選択/解除前後の実状態を比較し、成功した変化だけを測定対象へ渡す。測定モデルにも重複・不変状態の防御を置き、初回の基準状態と欠測/連番の意味を保つ。5枚目拒否、不可/凍結、無効ID、正常選択と解除を回帰テストへ追加。U1/U2はKeep、U3はModify、元の21ステップの完成物を保持。
- Estimated impact: 作業量は小規模（主に測定入口・モデル・テストの数ファイル、約20〜40分目安、検証で変動）。追加サービス費用0。通常の4枚選択/保存へのリスクは低く、計測連番と画面照合の互換性に注意して全回帰を実行する。実画面や本人確認の基準は下げない。

## 再検証 2026-11-01 12:50 JST

Loop-back 1の修正後、独立レビューで測定件数の指摘は修正済み、新規指摘なし。旧結果は上の初回履歴であり、現在の判定は以下を正本とする。

| Check | Evidence | Actual |
|---|---|---|
| ビルド | build-instructions.mdの同じbuildコマンド | BUILD SUCCEEDED、exit0 |
| U1専用 | .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.01_12-50-04-+0900.xcresult | 60成功、exit0 |
| U2専用 | .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.01_12-50-08-+0900.xcresult | 48成功、exit0 |
| U3専用 | .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.01_12-50-12-+0900.xcresult | 68成功、exit0 |
| E-ALL | bash scripts/verify-all.sh、.build/All-20261101-125015-88429.xcresult | 全176成功、失敗0、スキップ0、1168/1359=85.95%、exit0 |
| P-MEASURE安全版 | 旧入口がstampを拒否する場合をif-letで扱い、同じ空選択30回を入力 | acceptedOperations=0 passed=false、exit0 |
| 測定補助 | U3修正後の型検査・校正記録 | Swift6成功、キャプチャなし時刻系一致、numer125/denom3 |
| 実機 | manual-acceptance.mdとU3手順 | 本人未確認。実画面/OCR/30操作/10往復、操作支援、Photos |

各単位と全体の件数は二重加算しない。P-MEASURE安全版は元のスクリプトの `let s=native.stamp!` を `if let s=native.stamp { ... }` とし、合格または非ゼロ件数ならexit1、正しく拒否ならexit0とした公開境界の実行。元の不具合がなくなった後にforce unwrapで環境エラーを起こさず、拒否を照合するための変更である。

## Target Verification Matrix

| Target ID | Source | Expected | Actual | Evidence | Owning Stage | Verdict |
|---|---|---|---|---|---|---|
| NFR2.24 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/scalability-requirements.md:7 | 復元と確定は単一セッションで競合させず、書込みは1件ずつ。古い世代の復元結果を採用しない ／ 遅延応答・重複開始・切替/取消のテスト | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.24 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/scalability-requirements.md:8 | 破損退避は同じ原本bytesに対し重複を増やさず、1 MiBの既存読込/保存上限を維持 ／ 反復失敗/再試行で同一内容の退避再利用と過大入力拒否を確認 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR2.31 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:9 | 本人Mac、ローカル画像取得済み100枚以上、選択/解除30回以上の95%以上が入力イベント→実画面反映200ms以内 ／ 実入力と描画の時刻対応。状態更新時間だけで代用しない | 測定不具合は修正済み。実画面性能は未測定 | P-MEASURE修正後と本人実測（未確認） | build-and-test | Unverified |
| NFR2.32 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:10 | 先頭末尾10往復後、不要要求0が15秒以内、必要集合外の保持が増え続けない ／ 各往復の必要数、保持数、要求数、bytesを比較 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR2.33 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:11 | 全生存画像と予約256MiB以下、最大8要求（表示4/検証4）、画像最大512物理pixel ／ Fakeの上限/取消/外部参照試験と実測 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR2.34 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:12 | 各画像と4枚全体15秒の絶対期限、待機列込み、通信false ／ 注入時計境界と実画像不可確認。認可ダイアログ/書込時間は対象外 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR4.31 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:13 | 許可→複数フォルダ→アルバム→写真→確定/再試行をキーボードのみで完了 ／ 矢印、Space、Tab、可視フォーカス、領域退出と復帰 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR4.32 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:14 | VoiceOverで名称・展開・選択順・枚数・保存結果・復元と理由を確認 ／ 取得不可も理由へ到達、色のみに依存しない | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR4.33 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:15 | 1280×800pt、640×560pt、820pt境界で全操作に到達 ／ 4枠と操作を保持、長名全名、領域/フォーカスID保持 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR4.34 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/performance-requirements.md:16 | 通常文字4.5:1、大文字/操作要素3:1以上 ／ ライト/ダークとコントラスト設定で測定 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR2.7 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/scalability-requirements.md:9 | 2フォルダ以上・3階層以上、100枚以上の写真を受け入れ用データとする。固定の全件切捨てを設けない ／ Fakeと本人の実データで確認。100枚は最大件数ではなく検証の下限 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR2.8 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/scalability-requirements.md:10 | 階層探索は訪問済みIDを管理し、同じフォルダ/アルバムの重複と循環を打ち切る。UIの画像要求は必要な範囲へ限定する ／ 深い階層・親子重複・同名異ID・循環・遅延を自動テスト | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR2.9 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/scalability-requirements.md:11 | 確定保存の同時実行は最大1件。画像要求は有限の同時数と有限の保持予算で制御 ／ 重複確定と高速切替のテスト。同時数の具体値はNFR Designで決定 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.21 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/observability-requirements.md:7 | TDD・製品全体行カバレッジ80%以上・統合前ローカルビルド/自動テストを維持する。CIは省略済み ／ U2専用テストと全単位テストで対象/コミット/結果を記録 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.22 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/observability-requirements.md:8 | 診断は失敗分類のみ。本人の保存/再起動/欠損確認と自動検証を区別し、未確認を成功にしない ／ 日本語手順・未確認欄・匿名指標。個人ID/名称/画像なし | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR3.31 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/security-requirements.md:9 | 写真ライブラリ変更なし、画像取得通信なし、写真本体の恒久保存/外部送信なし ／ 境界と呼出しのコード確認、取得不可時の動作 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.32 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/security-requirements.md:10 | 保存置換の実成功と確定の写し/保存状態を一致させ、完了直後の認可変化・呼出し取消で成功を保存失敗へ変えない ／ 遅延保存Fakeで権限喪失/取消を競合、正常完了と実書込失敗を別検証 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR3.33 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/security-requirements.md:11 | 破損・未知版の原本保護、明示確定時の検証済み破損退避、symlink/過大拒否を維持 ／ U1/U2回帰。UIから直接書込しない | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.31 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u3-native-experience/nfr-requirements/security-requirements.md:12 | 通常診断は最小失敗分類のみ。性能計測は本人の測定時に集計値だけ扱い、ID・名称・画像・原本bytesを出力しない ／ 計測出力/通常ログ確認 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.1 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/observability-requirements.md:12 | 通常は失敗の分類のみを診断へ記録し、操作履歴を常時蓄積しない ／ ログ捕捉で写真ID・名称・画像・低水準エラー文字列を除外確認 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.2 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/observability-requirements.md:13 | 検証時だけ入力から画面反映までの経過時間・要求開始/完了/取消数・現在の不要要求数・画像保持推定量を一時計測 ／ ローカル計測。持続時間には単調時計を使う。通常の製品ログから性能達成を推定しない | 測定不具合は修正済み。実画面性能は未測定 | P-MEASURE修正後と本人実測（未確認） | build-and-test | Unverified |
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
| NFR2.23 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/performance-requirements.md:9 | 復元の探索・I/OでUIを不要に停止しない。復元途中の編集は禁止。画面反映95%以上200msと10往復測定はU3 ／ 遅延Fakeで独立状態案内を確認。U3最終実測を代替しない | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR1.21 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u2-session-reliability/nfr-requirements/tech-stack-decisions.md:7 | 既存SwiftUI/macOSアプリと5責務・C1〜C4へ追加し、別DB・外部依存・サービスを追加しない ／ 導入済みXcode/Swift6でビルド、U1互換の版1形式を継続 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR1.1 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:12 | アプリ ／ Swift・SwiftUIのmacOSネイティブアプリ。表示名ひとつづり、Xcode Hitotsuzuri、アプリ型HitotsuzuriApp ／ アプリプロジェクトは未生成。ビルド・起動は後続で確認 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR1.2 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:13 | ツールチェーン ／ 本人の現在のMacと導入済みXcodeを使う。今回読取りでXcode 27.2 build27B52、Apple Swift6.4.2、arm64/macos27.2 targetを確認 ／ 上流の27.1/6.4は以前の観測。最新版への更新作業は行っていない。最低OS・言語モードはNFR Designで具体化 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR1.3 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:14 | ライブラリ ／ OS標準の写真APIを読み取り用途で使用し、5責務をFakeに置換できる境界を保つ ／ 認可・階層・順序・画像オプションを対象SDKでコンパイルし、実写真の順序とローカル取得は本人確認 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR1.4 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:15 | 保存 ／ 外部DBを追加せず標準の構造化シリアライズと専用ファイルを使う。版付きの設定と確定を分離 ／ JSONを第一候補として、固定パス・日時・原子的置換・退避をNFR Designで確定。未検証の原子性を保証しない | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.6 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:16 | 自動検証 ／ Xcode同梱のSwift Testingを単体/統合テストの第一候補、XCTestを必要なUIテストの候補とする。外部パッケージを必須にしない ／ 実際のテストターゲットとカバレッジ取得・UI計測をCode Generation計画で検証。TDDを維持 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR5.7 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/tech-stack-decisions.md:17 | CI ／ 既決の専用MacでのCIを利用する。GitHub Actionsのself-hosted runnerを準備候補とする ／ まだ登録・環境構築・実行していない。公開範囲と隔離・実行元制限を設定前に確認 | the plan runs no CI Pipeline | change-decisions/2026-10-31-local-verification.md | build-and-test | N/A |
| NFR2.1 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/performance-requirements.md:9 | 画像取得完了後の選択・解除は入力イベントから表示反映まで、30操作以上の95%以上が200ms以内 ／ 本人のMac・100枚以上のローカル写真。計測器・記録手順をNFR Designで決定しU3で実測。Store更新時間で代用しない | 測定不具合は修正済み。実画面性能は未測定 | P-MEASURE修正後と本人実測（未確認） | build-and-test | Unverified |
| NFR2.2 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/performance-requirements.md:10 | ローカル画像1要求は受付から15秒以内に最終成功・取得不可・失敗・取消のいずれかへ収束 ／ 仮想時計による境界・遅延テストと実機確認。暫定プレビューで時間を延長しない | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR2.3 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/performance-requirements.md:11 | 確定前4枚の画像検証全体は開始から15秒以内。1件ごとの15秒を足して60秒にはしない ／ 4件の成功・一部停止・期限ちょうどの競合テスト。単調時計の期限以降の応答は不採用 | 自動試験/コード確認の該当境界は成功 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Met |
| NFR2.4 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/performance-requirements.md:12 | アプリ所有のデコード済み表示画像は推定256 MiB以下。一覧・4枠・検証画像を含む ／ 実バッファの推定byte数を一元集計し超過前に解放・要求制御。同一バッファの重複参照は二重計上せず、別コピーは計上。OS内部・プロセス全体のメモリは別記録 | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
| NFR2.5 | aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/u1-integrated-selection/nfr-requirements/performance-requirements.md:13 | 100枚以上で10往復スクロール後も保持量は上限以下、不要要求が残り続けない ／ U3で実測。最終スクロール後15秒以内に不要要求0を確認。画像API内部の保持量をアプリ側と混同しない | 自動試験の寄与あり、本人実機結果は未確認 | E-ALLと各単位tdd-evidence/manual-verification | build-and-test | Unverified |
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
| CONTRACT-COVERAGE | 全単位Testing Contract | 全製品行80%以上 | 1168/1359=85.95% | E-ALL | build-and-test | Met |
| CONTRACT-CI | 全単位Testing Contract | 統合前CI | the plan runs no CI Pipeline | 本人承認のCI省略決定 | ci-pipeline（非実行） | N/A |
| CONTRACT-TDD | 各単位tdd-evidence | runner先行・層別Red→Green→Refactor | 記録あり、各RedとGreenのxcresultを保持 | 各単位tdd-evidence.md | build-and-test | Met |


## 現在の保留

2026-11-02本人回答b8768846: フォルダの左右キー展開・Command複数選択・写真のキーボード選択は失敗。NFR4.31はNot Met。既存176件の成功は実入力経路の成立を証明しない。基本フロー成功は撤回せず、今回の入力不具合と区別する。

2026-11-02本人回答d4963b19: 起動・写真アクセス・4枚保存・終了再起動での復元について「成功」。基本フローの実機成功として記録する。操作支援・性能・コントラスト・外部変更/拒否等の異常系や数値は未報告であり、まとめて成功へ変更しない。詳細はmanual-acceptance.md。

ソース不具合によるNot Metは解消した。実機結果は引き続きUnverifiedで、本人の観察結果が必要。ループバックを繰り返して実機未確認を消そうとせず、同じ品質基準の確認を進める。Loop-Back Logは上の履歴を保持し、再実行で削除していない。

### Loop-back 2 — 2026-11-02

- Diagnosis: 本人実機でフォルダの左右キー展開、Command複数選択、写真のキーボード選択が成立しない。既存の計算モデル/描画テストは実入力とフォーカスの経路を通していない。
- Root-cause stage: code-generation、u3-native-experienceのPickerContent/ネイティブ入力接続とUI回帰テスト。フォルダ行の独自focusとList選択の干渉、写真ボタンのキーボードフォーカス不成立が疑われるが、具体原因は実入力テストで確定する。
- Planned fix: Debug限定の合成ライブラリで実アプリを起動できるUI試験構成を用意し、左右キー展開/折畳み、Commandクリック複数選択、写真へのフォーカス移動と矢印/Space/Tabを先にRedで再現。ネイティブの選択/フォーカス経路へ統一し、必要なら標準AppKitコントロールの薄い橋渡しを使う。状態計算だけで成功にしない。U1/U2はKeep、U3はModify。
- Estimated impact: 中規模（表示・入力接続、Debug限定fixture、Xcode UIテスト構成、回帰）。作業目安40〜90分、実行環境の成立確認により変動。追加サービス費用0。写真/保存処理への影響は限定し、フォーカス・複数選択・VoiceOverの回帰リスクを実UIテストと全件回帰で確認する。OS設定変更を前提にせず、本人の実写真やアクセス権限をUI試験に使わない。



