# 操作仕様

入力: [画面概略](../../ideation/rough-mockups/wireframes.md)、[利用フロー](../../ideation/rough-mockups/user-flow.md)、[ストーリー](../user-stories/stories.md)、[要件](../requirements-analysis/requirements.md)、[開発規約](../practices-discovery/team-practices.md)、[確認回答](refined-mockups-questions.md)。

## FolderSidebar

| Field | Value |
|---|---|
| Component | FolderSidebar |
| Description | 対象フォルダを階層表示し複数行選択する |
| Category | navigation / input |

### States

未選択・選択済み・展開/折り畳み・読み込み・空・取得失敗・保存中無効を区別する。

### Props / Inputs

フォルダID・名前・子階層・選択ID集合・読み込み状態・保存中フラグ。名前が同じでもIDで区別する。

### Interaction

展開ボタンと行選択を分離する。通常クリックは単独選択、Commandクリックは追加/解除。キーボードの一覧移動・展開と複数選択はネイティブ一覧の操作に合わせ実機確認する。フォルダ変更で現在アルバムが対象内なら編集選択維持、対象外ならクリア。対象変更だけで最後の確定内容を上書きしない。

### Responsive Behaviour

820pt以下の領域切替でも選択と展開状態を維持。戻った際は直前の行へフォーカスを復帰する。

### Accessibility

領域名「フォルダ」、各行の名称・選択・展開状態を読み上げ可能にする。長い名前はツールチップとVoiceOverで全名を確認する。

## AlbumList

| Field | Value |
|---|---|
| Component | AlbumList |
| Description | 対象アルバムから1つ選択 |
| Category | navigation / input |

### States

未選択・選択済み・読み込み・空・失敗・保存中無効。

### Props / Inputs

重複排除済みアルバムIDと名前、選択ID、取得状態、保存中フラグ。

### Interaction

行選択で写真を取得する。同じIDでは編集選択を消さず、別IDなら消す。検索・枚数・代表画像・手動更新を追加しない。写真へ移ると最初の操作可能写真へフォーカス可能にするが、非同期完了だけでユーザーのフォーカスを奪わない。

### Responsive Behaviour

3領域または切替表示。長い名称を省略しても全名への到達手段を残す。

### Accessibility

領域名「アルバム」、名称と選択状態を示す。矢印で一覧を移動し、標準の確定操作で選択する。

## PhotoGrid

| Field | Value |
|---|---|
| Component | PhotoGrid |
| Description | 写真を閲覧し最大4枚選ぶ |
| Category | display / input |

### States

読み込み・未選択・選択順1〜4・取得不可・空・保存中無効。

### Props / Inputs

アルバムID、順序付き写真ID、表示画像取得状態、選択ID配列、保存中フラグ。古いアルバムの遅延応答を現在のセルへ表示しない。

### Interaction

クリック/Space等で選択・解除。5枚目を追加せず文言で案内。解除後に番号を詰め、再選択を末尾へ追加する。画像取得中は選択不可、取得失敗時はその理由と準備・再起動を案内。写真の並びはFR3に従い、撮影日時順へ置き換えない。グリッドの移動・選択と下部枠は同じ選択状態を参照する。

### Responsive Behaviour

セルは表示幅に応じ列数を変え、概ね140〜220ptを目安とする。写真は領域内スクロール。下部選択欄を隠さない。

### Accessibility

写真にアルバム内位置・取得可能な撮影日時等のラベル、選択状態・順序を付ける。番号・枠・読み上げで選択を伝える。矢印移動、Spaceで選択、Tabで領域退出できるようにし、ネイティブ実装で確認する。

## SelectionTray

| Field | Value |
|---|---|
| Component | SelectionTray |
| Description | 4枠プレビュー、枚数、確定・失敗回復 |
| Category | display / feedback / input |

### States

未確定・4枚未満・4枚・検証中・保存中・保存済み・未保存変更・参照無効・書込み失敗・復元中・復元欠損。

### Props / Inputs

選択ID配列と対応画像、保存済みスナップショット、保存状態、エラー種別、確定可否。

### Interaction

4枚のときのみ確定可能。検証・保存中は選択変更と再確定を無効にする。成功時だけ保存済みへ遷移。失敗時は操作を戻し、書込み失敗には再試行を用意する。無効参照では再起動を案内し、古い内容のまま確定を再実行しない。通常確定前に追加ダイアログを出さない。保存中の終了やOSによる中断でも以前の確定内容を壊さないことを保存設計へ渡す。

### Responsive Behaviour

写真領域の下部に固定し、4枠と操作を最小幅内に収める。文言は折り返し、確定ボタンと回復操作を画面外へ押し出さない。

### Accessibility

各枠に選択順と写真識別名。枚数・保存結果・失敗と回復手段を読み上げ可能にする。無効化理由を文言で補足。保存終了後は元の操作位置へ戻し、失敗で再試行へ移る場合は文言と関連づける。

## PermissionAndRestore

| Field | Value |
|---|---|
| Component | PermissionAndRestore |
| Description | 初回許可と再開時の状態 |
| Category | feedback / input |

### States

未許可・拒否・制限・復元中・正常復元・欠損・保存なし・破損。

### Props / Inputs

認可状態、保存データ読込み結果、参照検証結果。

### Interaction

許可ボタンは本人操作で実行し、拒否・制限を区別する。復元中は選択を未確定とし、全参照と画像取得が有効なときのみ確定状態を復元する。一部欠損なら写真全体をクリアし有効なフォルダを残す。破損は案内し安全な初期状態へ。保存内容を自動上書きしない。

### Responsive Behaviour

説明を中央に配置し、狭い幅では折返す。主操作は説明直下。

### Accessibility

主見出し、説明、主操作の順で読み上げる。拒否案内から操作可能な場所へ戻れ、キーボードを閉じ込めない。
