# 記事制作の操作仕様

## 入力・共通規則
`mockups.md`、`../../ideation/rough-mockups/wireframes.md`、同`user-flow.md`、`../user-stories/stories.md`、`../requirements-analysis/requirements.md`、`../practices-discovery/team-practices.md`に対応する。以下のStates/Inputs/Responsive Behaviour/Accessibilityは部品仕様の共通形式。VoiceOver追加設計・試験は対象外とし、Keyboardと見えるラベルを扱う。

## ArticleEntry / DraftPicker
| Field | Value |
|---|---|
| Component | 記事ボタン、記事メニュー、下書き選択シート |
| Description | 現在の確定済み選択または保存済み下書きを開く |
| Category | navigation |

### States
defaultは開ける記事/候補、disabledは未確定または未選択、loadingは読込中、emptyは下書き0件、errorは読込失敗。hover/focusはOS標準。errorをemptyへ変換しない。
### Props / Inputs
確定選択、候補一覧（記事ID・タイトル・元名・更新日時）、読込状態。外部IDは不透明な値。新規と再開の結果は記事IDで特定する。候補のソートは更新日時降順・記事IDで安定化。
### Responsive Behaviour
選択シートは最小480pt、親幅に収まる範囲。長名は折返し、一覧は縦スクロール。
### Accessibility
可視ラベルを付ける。Tabで一覧/操作へ、矢印で行移動、選択後に開くボタンを実行。Escape/キャンセルは変更なし。閉じたら起点へ、開いたら編集見出し後の最初の操作へ焦点を移す。VoiceOver追加仕様なし。

## ArticleEditor / MetadataFields
| Field | Value |
|---|---|
| Component | 本文フォーム、日付候補と撮影情報 |
| Description | 写真と対応した記事を編集する |
| Category | input |

### States
defaultは保存済み入力、editingは未保存、savingは保存中、errorは保存失敗または日付不正、partialは写真取得不能。空本文は有効。focus/hoverはOS標準。
### Props / Inputs
記事ID、順序写真ID、本文各欄、撮影日候補/確認済み日付、自由撮影情報、dirty状態、保存結果。自由入力は保持し、日付だけ有効年月日を検証する。日付候補と手動入力を暗黙に確定しない。
### Responsive Behaviour
960pt以上は写真280pt＋間16pt＋フォーム、未満は縦配置。最小640×560pt、上下16ptの余白と8/16ptの間隔。最小幅でボタンが収まらなければ折返し。
### Accessibility
項目の上の可視ラベル、写真番号と文章番号を一致させる。Tab/Shift-Tabで見た目順に移動し、複数行編集ではReturnを改行として扱う。フォーカスリングを残し、移動先をスクロールで表示。色だけのエラーにしない。

## DraftSave / LeaveConfirmation
| Field | Value |
|---|---|
| Component | 手動保存と未保存確認 |
| Description | 入力を保護して保存・離脱を判断する |
| Category | feedback / action |

### States
clean、dirty、saving、saved、failed。文字表示を状態の唯一の事実源にし、実保存完了前にsavedへ進めない。既にcleanなら離脱確認不要。
### Props / Inputs
記事の編集リビジョンと保存結果、離脱先の操作。保存中の重複を止め、保存後に新しい入力があればdirtyを維持する。
### Responsive Behaviour
シート内の説明は折返し、3操作は狭幅で縦並び可。背景フォームを破棄しない。
### Accessibility
確認中はシート内の操作をキーボードで選べる。Escapeは編集継続。明示破棄以外で文章を捨てない。Command-Sを「下書きを保存」に割り当てる案とし、対象が記事編集時に限り有効。保存失敗時はエラーと再試行へ到達可能にする。

## Preview / Copy
| Field | Value |
|---|---|
| Component | 編集・プレビュー切替、本文コピー |
| Description | 現在の入力または完了出力本文を確認・コピーする |
| Category | display / action |

### States
編集、プレビュー、コピー成功、写真一部取得不能。切替は保存を行わず入力状態を維持する。
### Props / Inputs
本文・写真順・撮影メモの投影、未保存状態。編集/プレビューのコピーは現在入力、出力成功画面のコピーはその出力スナップショット。コピー成功後も保存状態を変えない。
### Responsive Behaviour
プレビュー最大720pt、左右16pt以上。画像はfit、長文は折返しと縦スクロール。
### Accessibility
切替・コピーにTab到達、Space等で実行。画像取得不能も番号と文字で示す。プレビューはnote上の一致保証を示す表示にしない。

## ExportPanel / FinderAction
| Field | Value |
|---|---|
| Component | 書出し、進捗、結果、Finder表示 |
| Description | 保存済みの固定内容を一式にして受け渡す |
| Category | action / feedback |

### States
idle→必要なら保存確認→保存先選択→running→succeeded/failed/cancelled。保存・出力先選択の取消はrunningへ進まない。cleanup失敗は失敗理由を残す。Finder失敗はsucceededを取り消すものではなく別の表示失敗。
### Props / Inputs
記事と保存リビジョン、写真順、固定出力設定、選択先、ジョブID、進捗と終端結果。古いジョブの応答は表示を置き換えない。running中は編集/保存/記事切替/重複出力を無効化し、キャンセルは有効。
### Responsive Behaviour
進捗・保存先・理由は折返し、操作も折返す。OS保存先パネルは標準表示を使い、独自のファイルブラウザを作らない。
### Accessibility
現在有効な操作へキーボード到達可能。取消要求後は処理中を示し、完了通知まで成功表示にしない。失敗は原因と次の操作を文字で示す。完了のFinderは当該出力だけを開く。

## 状態・検証の対応
US1.1はM1、US1.2/US1.5/US1.6はM2/M3、US1.3はM4、US1.4はM2のpartialとM5の失敗、US1.7/US1.8はM4/M5へ対応する。要件FR1〜FR18をこれらの画面操作で検証する。NFR1の元ライブラリ非変更は全処理で維持し、出力用加工は成果物だけへ行う。その他の品質条件・実画像確認とCIは要件と実装計画に従う。
