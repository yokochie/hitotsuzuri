# U1 データ保護設計

根拠: [性能要件](../nfr-requirements/performance-requirements.md)、[保護要件](../nfr-requirements/security-requirements.md)、[容量要件](../nfr-requirements/scalability-requirements.md)、[信頼性要件](../nfr-requirements/reliability-requirements.md)、[診断要件](../nfr-requirements/observability-requirements.md)、[技術選定](../nfr-requirements/tech-stack-decisions.md)、[機能仕様](../functional-design/functional-spec.md)、[内部契約](../../../inception/contract-design/contract-summary.md)、[確認回答](nfr-design-questions.md)。本段階は設計であり、製品のビルド・動作を確認済みとしない。

## SD1 読み取り境界

対応: NFR3.1、NFR3.2。LibraryAccessとImageAccessの入口で認可を確認し、未許可なら処理しない。本人の許可操作でのみ.readWriteを要求するが、変更操作のAPIを製品の境界へ公開しない。PhotoKitのperformChanges等の呼出しが製品ソースにないことをレビューする。画像要求オプションのisNetworkAccessAllowedを必ずfalseとし、失敗時の再要求も同じ規則。ネットワーククライアントを追加しない。

## SD2 専用保存と入力

対応: NFR3.3、NFR3.4。App Sandboxを有効にし、写真参照用の説明文と必要な写真アクセスentitlementを対象SDKで検証する。書込はコンテナ内Application Support/Hitotsuzuri配下の固定名settings.jsonとselection.jsonだけ。選択の画像はメモリのみ。名称・写真ID・フォルダIDをパスに埋め込まない。専用領域のシンボリックリンクや通常ファイルでない保存対象は拒否し、意図しない場所を上書きしない。

読込は最大1 MiBの版付きJSONを境界で検査する。書込も同じ上限で検査し、超過は失敗案内とする。schemaVersion=1、必須属性と型、重複なし4枚、空でないID、日時の形式を検証。不透明IDは大小文字・Unicodeを正規化しない。未知フィールドは既知の必要属性が有効なら無視可能、未知版は拒否。復元検証とは分離し、正常にデコードできても参照が有効とは見なさない。上限は破損データ対策で、写真枚数の上限ではない。

## SD3 診断とCI

対応: NFR3.5、NFR5.1、NFR5.7。低水準エラー全文ではなく定義済み分類だけをLoggerへ渡す。ID・名称・画像・パス・認可の個人情報をメッセージへ連結しない。CIは個人ライブラリを参照しないFakeと隔離されたテスト保存先。CI登録・実行元制限・専用Macの隔離はInfrastructure Design/CIの計画で具体化し、トークンを成果物へ残さない。

## SDK確認と未実証事項

現在のMacOSX.sdkのPHImageManager.hで通信オプション、degraded/取消/エラーキー、取消メソッドとmacOSのNSImage応答を確認した。これはヘッダ確認であり、Swift6の隔離適合や実際の権限取得を実証していない。コード生成時の型検査・ビルドと本人の許可/拒否確認が必要。[Apple通信オプション](https://developer.apple.com/documentation/photos/phimagerequestoptions/isnetworkaccessallowed)も参照。
