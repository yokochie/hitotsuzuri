# U1 論理構成と実行境界

根拠: [性能要件](../nfr-requirements/performance-requirements.md)、[保護要件](../nfr-requirements/security-requirements.md)、[容量要件](../nfr-requirements/scalability-requirements.md)、[信頼性要件](../nfr-requirements/reliability-requirements.md)、[診断要件](../nfr-requirements/observability-requirements.md)、[技術選定](../nfr-requirements/tech-stack-decisions.md)、[機能仕様](../functional-design/functional-spec.md)、[内部契約](../../../inception/contract-design/contract-summary.md)、[確認回答](nfr-design-questions.md)。本段階は設計であり、製品のビルド・動作を確認済みとしない。

## LC1 所有者と隔離

対応: NFR1.1、NFR1.2、NFR1.3、NFR2.6。

| 所有者 | 実行境界の方針 | 失敗の範囲 |
|---|---|---|
| PickerPresentation | SwiftUI、UI状態の参照と操作送信のみ | 表示・フォーカス |
| SelectionWorkflow | MainActor上で編集・保存状態・世代を一元所有 | 現セッションの進行 |
| LibraryAccess | 専用の直列バックグラウンド実行でPhotoKitオブジェクトを保持し、Sendableな値へ写して返す | 許可・階層・所属検証 |
| ImageAccess | 要求状態と予算を一箇所で直列管理。コールバックを管理境界へ戻して照合 | 該当画像要求と表示 |
| SelectionPersistence | 直列バックグラウンドI/O。版付きデータと操作結果だけを返す | 設定/確定レコード |

最低OSは本人環境に合わせmacOS27.0、Swift6言語モードを設計値とし、Xcode27.2/Swift6.4.2でビルド確認する。後方互換性を追加の受け入れ条件にしない。UIの隔離とPhotoKitのコールバック注釈はコード生成時の型検査で確認し、非SendableなPHAsset/NSImageを無根拠に境界越しに送らない。境界内保持または明示的に所有するバッファへ変換する。安全性の根拠なしにunchecked Sendableで警告を抑えない。

## LC2 画像結果の具体的表現

C3の意味を損なわない結果型をimage/unavailable/cancelled/failureで区別し、共通のrequestID・assetID・generationを持たせる。imageだけがバッファとpreview/final品質を持つ。unavailableは理由が判明すれば分類、cancelledは画像と通常失敗を持たず、failureは分類を持つ。タイムアウトはfailureのtimedOutとして一度だけ終端化する。機能設計のImageResultではこの区別が十分に明記されていないという上流指摘への具体的な対応方針であり、上流のレビュー状態を変える記録ではない。

## LC3 共有資源と検証

写真ライブラリは読み取り元1つ、編集セッション1つ、画像予算1つ、保存担当1つ。3下位担当は相互呼出しせず進行担当が調整する。画像要求・世代・保存操作IDを別概念とし、UI更新はMainActorへ戻して現世代を照合する。Foundation/PhotoKitのSDKヘッダでAPIの存在を確認したが、この設計はコンパイル済みコードではない。Xcodeプロジェクトとテスト対象の生成、actor境界、画像デコード時の所有権、保存の中断・失敗を後続で検証する。利用者の写真を使う動作検証は本人が行う。

