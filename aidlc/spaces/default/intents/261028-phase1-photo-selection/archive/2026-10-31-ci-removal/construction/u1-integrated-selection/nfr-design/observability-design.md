# U1 診断と検証の設計

根拠: [性能要件](../nfr-requirements/performance-requirements.md)、[保護要件](../nfr-requirements/security-requirements.md)、[容量要件](../nfr-requirements/scalability-requirements.md)、[信頼性要件](../nfr-requirements/reliability-requirements.md)、[診断要件](../nfr-requirements/observability-requirements.md)、[技術選定](../nfr-requirements/tech-stack-decisions.md)、[機能仕様](../functional-design/functional-spec.md)、[内部契約](../../../inception/contract-design/contract-summary.md)、[確認回答](nfr-design-questions.md)。本段階は設計であり、製品のビルド・動作を確認済みとしない。

## OD1 通常診断

対応: NFR5.1、NFR3.5。標準Loggerへエラー分類だけを記録する。固定文字列のみを許す境界を作り、NSError全文・URL・写真名を渡せない構成にする。独自の診断ファイル・操作履歴・外部送信は作らない。OSログの保持はOS管理とし、アプリ独自の保存期間を持たせない。

## OD2 一時計測

対応: NFR5.2、NFR2.1、NFR2.5。検証時にだけ有効な計測器を依存注入する。要求受付/開始/取消/終端の件数、現在の必要集合外の要求数、固有バッファと予約byte数、単調時計の経過を集計する。要求の内部相関IDはセッションだけで使い、外部の写真IDと対応づけたログを残さない。終了時に匿名の件数・最大値・判定を日本語Markdownへ記録する。U3ではInstrumentsの描画観測と画面記録を用いて200ms条件を測り、内部状態変更時刻で代用しない。指標を取れなければ未測定とする。

## OD3 再現と品質

対応: NFR5.3〜NFR5.7。Xcodeの単体/統合テストターゲットでFakeライブラリ・Fake画像・Fake時計・失敗注入保存を使用する。TDDは失敗原因が期待した振る舞いであることを確認してから最小実装し成功させる。行カバレッジ80%以上は製品Swiftソース全体を基本に計測し、生成コード等の除外はCode Generation計画へ根拠を残す。単体ロジックだけの値を製品全体の値と見せない。

専用Mac CIでビルド・自動検証を統合前に実行し、実機の写真アクセスは本人の日本語手順の結果として別に残す。具体的な検証コマンドは最初の検証前に本人確認する。本設計はその承認を代替しない。CI登録とリポジトリ実行元制限の設定は次段階で計画し、未設定を成功と表示しない。
