# U2 原本保護設計

根拠: [性能](../nfr-requirements/performance-requirements.md)、[保護](../nfr-requirements/security-requirements.md)、[容量](../nfr-requirements/scalability-requirements.md)、[信頼性](../nfr-requirements/reliability-requirements.md)、[診断](../nfr-requirements/observability-requirements.md)、[技術選定](../nfr-requirements/tech-stack-decisions.md)、[機能仕様](../functional-design/functional-spec.md)、[契約](../../../inception/contract-design/contract-summary.md)。CIは[本人の変更決定](../../../change-decisions/2026-10-31-local-verification.md)により省略。以下は設計であり未実装。

## S21 認可と入力

対応NFR3.21、NFR3.22。復元前と参照検証の入口で認可を確認し、許可なしならC2/C3を呼ばず原本を保持する。起動中の自動変更監視は追加しない。書込前と再試行前には現在の認可・所属・4画像を確認する。画像要求の通信false、ライブラリ変更なし、画像本体保存なしを維持する。

保存形式はschemaVersion1の既存JSON。構文と意味を読込境界で検証し、空ID・重複・4枚数不正・不正日時をcorruptDataとして扱う。未知版とI/O失敗はcorruptDataと別分類。いずれも起動だけで置換しない。

## S22 退避範囲

対応NFR3.23、NFR3.24。専用保存ディレクトリ内のquarantineへ、破損原本bytesのSHA256に基づく固定方式の名前で退避する。個人の名称/IDをパスへ含めない。ハッシュは衝突時も既存ファイルbytesを比較し、不一致なら失敗として置換を行わない。同じbytesは検証した既存退避を再利用し、再試行のたびに増やさない。

通常ファイルと専用領域内のパスだけを扱い、symlinkを拒否する。通常JSONと退避原本は1 MiB以下。上限超過/読取不能は保護して失敗とし自動回復しない。退避ファイルも個人データなのでログ・Git・外部送信の対象にしない。退避一覧UI・履歴機能は追加しない。

