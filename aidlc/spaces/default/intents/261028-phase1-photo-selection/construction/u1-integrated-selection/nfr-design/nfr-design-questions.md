# U1 品質条件を満たす設計の確認

## 入力と判断

[性能](../nfr-requirements/performance-requirements.md)、[保護](../nfr-requirements/security-requirements.md)、[容量](../nfr-requirements/scalability-requirements.md)、[信頼性](../nfr-requirements/reliability-requirements.md)、[診断](../nfr-requirements/observability-requirements.md)、[技術選定](../nfr-requirements/tech-stack-decisions.md)、[機能仕様](../functional-design/functional-spec.md)、[内部契約](../../../inception/contract-design/contract-summary.md)に基づく。

新たな製品判断の回答待ちはない。以下を技術設計の方針とし、具体的な型・SDK可用性と保存操作は対象環境で検証する。製品コード生成は本段階では行わない。

## Consolidated Summary Confirmation

- 画面と選択判断は一つのUI実行境界で管理し、探索とファイルI/Oを別の実行境界へ分ける。要求IDと世代を照合し、切替前の結果を採用しない。
- 画像は表示に必要な範囲だけ取得し、全要求の同時実行数を有限にする。256 MiBの予算に要求中の予約分も含め、超過前に不要画像を解放する。確定検証を優先し、1要求と4枚検証全体に各15秒の期限を適用する。
- 選択可能性はローカルで最終画像の取得成功を確認して判断する。暫定画像だけでは確定を通さず、結果種別を画像・取得不可・取消・失敗として明示する。
- 設定と最後の確定内容を別の版付きJSONとしてアプリ専用領域へ保存する。一時ファイルを準備してから置換し、完了後だけ成功とする。保存中は編集せず、失敗時は旧確定と編集を保持する。
- 未対応版は上書きを拒否する。U1で破損原本を保護し、退避後の再確定と復元の完全化はU2で行う。
- 通常は失敗種別だけをローカル診断へ記録し、検証時だけ時間・要求数・保持量を計測する。写真ID・名称・画像をログへ含めない。
- TDD・80%以上・専用Macの統合前CIを維持する。性能の最終受け入れはU3で実測し、写真権限と並びの本人確認を分離する。具体的な検証コマンドの本人確認は従来どおり検証前に行う。

Does this all look correct before I generate the artifact?

- Looks correct
- Request changes

[Answer]: Looks correct
