# Phase2 設計判断

入力：`components.md`、確認済み`domain-design-questions.md`、`../requirements-analysis/requirements.md`、`../user-stories/stories.md`、既存CodeKBのarchitecture・component-inventory、`../practices-discovery/team-practices.md`。以下は責務・所有と呼出しの決定で、配布構成や新規技術の採用を確定するものではない。

## ADR-001 写真選択と記事の正本を分離する
### Context
既存選択は再確定で新IDを持ち、UI復元は4枚の画像成功を要求する。記事は写真取得不能でも文章を再開し、再確定時に本人が新規か既存か選べなければならない（US1.1/US1.4）。
### Decision
ExistingSelectionを既存選択の所有者として残し、ArticleWorkspaceがArticleProjectの唯一の正本所有者となる。選択読込は保存境界から取得し、画面に公開されたlastCommittedだけへ依存しない。記事は来歴の選択IDと当時の名称・写真順を保持する。既存記事の再開では記事IDを保ち、再確定選択との関連は記事管理で明示的に扱う。
### Consequences
画像取得から独立した文章の再開と旧形式の保護を試験しやすい。一方、選択と記事の来歴対応・複数候補の選択と保存形式差分を設計する必要がある。既存選択読込の失敗を新規記事作成で隠さない。セキュリティ上は写真ID等を通常ログへ出さず、記事保存の権限を既存選択の破壊的書込へ広げない。個人ローカル利用と通信禁止を維持する。
### Alternatives Rejected
- 既存SelectionWorkflowへ記事状態も集約：初期接続は少ないが、写真成功依存と既存復元への変更が大きくなるため不採用。
- 写真の組合せだけを記事IDにする：再確定時に新規記事を作る本人の選択や、同じ組の複数下書きを表せないため不採用。

## ADR-002 未保存編集と出力の固定コピーを別の寿命にする
### Context
手動保存・未保存離脱確認と、保存成功した内容を固定する出力が必要（US1.2/US1.3/US1.7）。コピーは現在入力を扱う一方、完了画面では当該出力本文を扱う。
### Decision
ArticlePresentationがArticleEditSessionを所有し、ArticleWorkspaceへ手動保存する。ArticleDeliveryは成功した保存内容の固定コピーとExportJob/ExportManifestを所有し、記事正本へ書き戻さない。Presentationが操作順を調整して保存→固定出力を開始し、出力中の対象編集・保存・切替を防ぐ。通常コピーも固定出力コピーも、記事管理が定義した同じ本文投影規則の結果をOS受渡しへ渡す。
### Consequences
dirty判定と古い応答の排除、出力の整合が明確になる。一方、保存版・編集版・ジョブIDの対応を明示する必要がある。コピーやFinderだけの失敗で記事正本を破棄しない。画像や個人情報の自動送信を追加せず、manifestはローカル管理用に限定する。
### Alternatives Rejected
- UIの可変状態を出力側が随時参照：出力途中に本文・順序が変わり得るため不採用。
- 記事保存と成果物出力を同じ正本書込として扱う：取消や容量不足が下書きまで巻き込む責務になるため不採用。

## ADR-003 記事用画像を表示用画像から分離する
### Context
既存画像は512px・2MiB予約等の表示専用契約。記事では編集・回転・色・JPEG・縮小・位置情報除去と進捗・取消が必要（US1.4/US1.7）。
### Decision
ArticleImagesを記事用の読取・変換責務とし、ArticlePresentationとArticleDeliveryから呼ぶ。ArticleImageRequestは用途・固定設定・期限・結果を持つ。通信を要求せず、元写真・アルバム・フォルダを成功・失敗・取消でも変更しない。表示用画像取得と同じ実装を無条件で高解像度化せず、共通化可能な内部処理は後続設計で判断する。
### Consequences
表示と成果物の画質・資源制約を混同せず、失敗・取消を個別試験できる。OSアダプタの重複は増え得るため、境界より下の再利用を検討する。利用者の写真権限の範囲で読取り、不要メタデータを出力へコピーしない。取得方式・色変換方式は実証が必要であり、現時点の成立保証にはしない。
### Alternatives Rejected
- 表示用キャッシュをそのままJPEG化：必要解像度と編集結果の条件を満たす保証がないため不採用。
- 既存表示サービスの契約を一律に高解像度へ変更：選択画面のメモリ・期限・応答性まで変えるため不採用。

## ADR-004 呼出しを循環させず、受渡し値で協調する
### Context
画面は記事管理・画像・出力を使うが、出力が記事管理を直接書き換えると保存・取消の状態が相互依存する。
### Decision
呼出しはPresentation→Workspace→ExistingSelection、Presentation→Images、Presentation→Delivery→Imagesとする。画像結果や進捗は要求への応答として返す。データ上の参照は呼出し依存と区別し、DeliveryのArticleProject参照は固定入力の来歴であってWorkspaceへの呼出しではない。型・API・エラー形式はContract Designで具体化する。
### Consequences
循環のない依存と一意の所有を検証しやすい。Presentationは調整責務を持つため、UI描画と操作調整の内部分離を後続で設計する。権限やファイルアクセスはOS境界に限定し、下書きや画像内容を不必要に層間ログへ出さない。
### Alternatives Rejected
- DeliveryからWorkspaceへ保存を呼び戻す：UIの保存と出力の保存が二重経路になるため不採用。
- グローバル共有の可変記事を全責務が参照：所有・保存版・競合判定が曖昧になるため不採用。
