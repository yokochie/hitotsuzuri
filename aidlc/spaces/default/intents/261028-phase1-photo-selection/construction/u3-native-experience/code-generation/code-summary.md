# U3 実装結果 — アルバムの上下キー操作

## 今回の変更対象

本人905a320cの報告と計画承認7ac7b654に従いStep46〜51を実施した。今回のsource-manifestはPickerContent.swift、DebugFixture.swift、NativeInputTests.swiftの3パス。前回197件・90.29%は変更前基準として保持する。NativeFolderBrowser、U3FocusTests、Xcode構成、保存形式、4枚ルール、5責務/C1〜C4は今回変更していない。

## 原因と最小修正

アルバムListに追加したfocusableが一覧の枠へ焦点を作り、標準行選択へ上下キーが届かなかった。実TabでAの12枚を表示した後、DownでCの8枚へ変わらないRedを確認した。focusableを1か所外しただけでA12→C8→E4→末尾4維持→C8→A12→先頭12維持の実Down/Upが成功した。標準Listの行選択を使い、手書きの上下選択やNSTableView等の新しい橋渡しは追加していない。

狭幅で写真から逆TabしてListを再挿入する境界は、接続前の焦点設定ではUpが届かなかった。既存の写真用接続後焦点復帰を共通化し、狭幅Albumにも適用した。遷移番号・領域・認可・Album/Folder/編集/対象存在・非凍結の照合を維持し、初回の未選択Albumだけは既存Tab先頭選択との整合を確認する。固定sleepを使わず、画像応答から焦点要求を作らない。

## 合成データと観測

従来fixtureはすべてのAlbumが同じ12写真を返し、写真が見えるだけでは切替を検出できなかった。Debug限定でAlbum A/B/C/D/Eに別IDと12/10/8/6/4枚を割り当てた。既存の「写真1」等のラベルと4枠意味、AlbumAの12枚は保つ。写真領域のアクセシビリティ値には実workflow.assets.countを示し、各キー入力後に正しいAlbumの写真枚数へ変わったことを観察する。モデル関数呼出しや別行クリックでDown/Upを代行しない。

実Photos、個人保存領域、OS設定、公開AX全列挙probeは操作していない。標準Listの行選択とWorkflowを同じBindingで接続し、上下の表示追随を実アプリで確認する。行focusの内部状態を取得したふりはせず、識別できる写真表示の変化を証拠とする。

## TDDと最終結果

初回runnerのautomation初期化timeoutでは停止し、本人24244e54のUI操作許可後に単独runnerを再実行して成功した。その後のみ準備patchとRedへ進んだ。Album-Red-20261103.xcresultは実assertion失敗1件、Album-Green-20261103.xcresultは1変更で成功。通常幅の再入/逆Tab/編集保持と空一覧は成功し、狭幅再挿入の失敗を記録して上記の焦点共通化を行った。Album-Connected-20261103.xcresultで上下/通常再入/狭幅の3件が成功した。詳細はtdd-evidence.md。

新規は実UI4件。承認済み bash scripts/verify-native.sh はexit0、**全201件成功・失敗0・skip0**（前回197＋4）。結果:
 /Users/yokochie/works/yokochie/hitotsuzuri/.build/Native-20261103-075736-25503.xcresult

同スクリプト内の既存check-coverage.swiftで **1451/1610行＝90.12%**。PickerContent545/556、DebugFixture33/38。App入口、UI、fixture、Photosアダプタを含み、分母/80%閾値/既存assertion/スクリプトを弱めていない。全201件を実行し、今回追加した試験に未実行はない。全体検証開始後にソース変更していない。

## 既存動作と本人確認

マウスで非先頭Albumを選んだ後の上下移動、通常/狭幅の再入と逆Tab、同じAlbumで写真編集を保つこと、実際に別Albumへ変わると従来どおりクリアすることを確認した。写真へのTabはfocusだけでSpace時に選ぶ規則、未選択時の先頭選択、Folder複数選択、見出しTab除外を全既存回帰で保持する。空Albumの実Up/Down無操作と、凍結/権限等の既存C1保証も確認した。凍結時の本人実操作を新たに実施したとは扱わない。

本人の基本フロー/既存3操作の成功は保持し、今回のAlbum上下キー修正後の本人再確認はmanual-verification.mdの未確認欄へ分けた。VoiceOver/コントラスト/実画面性能等の未確認と、既知の子折り畳み選択問題の現状継続判断も変更しない。ソースと成果物を凍結し、独立レビュー・unit complete・コミットは主担当へ引き継ぐ。

## 本人requested追記 — 狭幅の確定到達（38ec67b9）

上記201件の正式checkpoint後、狭幅Album/Photoから確定へTab到達できないとの本人報告を直接修正した。新計画・再承認・reopen等のworkflow操作は行わない。変更sourceはPickerContent.swift/NativeInputTests.swiftだけ。

狭幅で確定が有効な場合だけ、Album前進Tabを非表示Photoへの移動から確定焦点へ変更。Photoも同じ確定入口を使い、未完了の領域復帰を取消す。確定の逆Tabは表示中Paneの記憶IDへ戻し、region変更や同じAlbumの再選択をしない。通常幅とdisabled分岐、onAppear自体は維持した。

Redは3件中2失敗・1成功、最小Greenは新規UI4件成功。詳細はcompact-confirm-fix-20261103.md。全体コマンドを一度実行し、**全205件成功・失敗0・skip0、1474/1634行＝90.21%**。結果 .build/Native-20261103-234223-36633.xcresult。通常幅、disabled、既存上下/Tab/写真編集の回帰を維持し、既知子折り畳み問題は無変更。全体開始後のsource変更なし、本人再確認は未確認としてsource/記録を凍結した。
