# U3 論理構成と検証の割当

根拠: [性能と操作支援](../nfr-requirements/performance-requirements.md)、[保護](../nfr-requirements/security-requirements.md)、[技術](../nfr-requirements/tech-stack-decisions.md)、[機能仕様](../functional-design/functional-spec.md)、[契約](../../../inception/contract-design/contract-summary.md)。以下は実装前の設計であり、未測定を合格としない。

## 所有と障害範囲

| 対象 | 所有者 | 失敗の範囲 |
|---|---|---|
| 幅・フォーカス・読み上げ・4枠 | PickerPresentation | 表示のみ、選択ルールは複製しない |
| 保存結果と認可案内の整合 | SelectionWorkflow | C4成功を反映し認可を独立案内 |
| 必要集合・取消・予算 | ImageAccessと進行担当 | 古い表示を採用せず上限超過を案内 |
| 実Photos参照・原本保護 | 既存LibraryAccess/SelectionPersistence | U3で変更APIや別保存形式を追加しない |
| 任意測定 | 測定用起動と本人確認手順 | 通常動作へ診断画像や恒久ログを持ち込まない |

## 検証と配置

NFR1.31、NFR5.32、NFR5.33。同じmacOSアプリへ追加し、共有C1〜C4と5責務を維持する。TDDで操作状態・表示・資源・保存完了競合を検証し、U1/U2を回帰確認する。全製品Swiftの加重行80%以上を保つ。本人の現行MacでVoiceOver/キーボード/画面描画/実Photosを確認し、日本語のXcode中心手順へ残す。CIは本人決定により省略し、専用ランナーやクラウドを追加しない。

