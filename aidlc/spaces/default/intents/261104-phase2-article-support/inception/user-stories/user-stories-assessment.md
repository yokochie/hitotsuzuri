# 利用場面整理の必要性

## Decision
Execute。

## Rationale
写真選択から記事制作へ進む利用者向け機能であり、保存・再開・再確定時の選択・画像取得不能・出力取消などの分岐がある。要件だけでなく、本人がどの状況で何をして何を確認できるかを整理する価値がある。

## Factors Considered
- Brownfield。既存選択の復元は画像取得成功に依存し、再確定でIDが変わる。記事の文章再開とは分けた受け入れ条件が必要。
- 本人1種類の利用者で8場面、全てMust Have。新しい製品範囲や正式Unitは追加しない。
- `../requirements-analysis/requirements.md` の18FR・7NFRを基準とする。
- `aidlc/spaces/default/codekb/hitotsuzuri/business-overview.md` と `component-inventory.md` は既存の写真選択・保存・表示用画像・UIの境界を確認する入力であり、記事機能が実装済みという証拠ではない。
- `../practices-discovery/team-practices.md` のTDD・80%基準・統合前CIを維持し、自動と本人確認を区別する。

## 計画と検証の境界
`user-stories-questions.md` の確認済み計画により、P1の操作の流れに沿った8場面を作成する。INVESTを確認し、各場面に独立したfixtureで検証できる条件を置く。画像処理の期限・予算・画面幅・CI環境は既に指定された後続段階で具体化し、ここで未検証値を保証しない。
