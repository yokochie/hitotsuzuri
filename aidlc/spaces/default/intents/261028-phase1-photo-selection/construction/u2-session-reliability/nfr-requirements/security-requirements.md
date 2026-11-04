# U2 security-requirements

根拠: [機能仕様](../functional-design/functional-spec.md)、[ルール](../functional-design/rules.md)、[要件](../../../inception/requirements-analysis/requirements.md)、[契約](../../../inception/contract-design/contract-summary.md)、[CI省略](../../../change-decisions/2026-10-31-local-verification.md)。本書は要求であり動作確認結果ではない。

| ID | 条件 | 検証 |
|---|---|---|
| NFR3.21 | 権限未許可では復元のライブラリ参照を進めない。写真変更・画像取得通信・画像恒久保存・外部送信なし | Fake呼出し検査とコード確認 |
| NFR3.22 | 破損/未知版/読込失敗は原本保護。破損確定の退避は本人の新しい確定操作に限り、未知版上書きは常に拒否 | 正常/構文破損/意味破損/未知版/I/O失敗の原本bytes比較 |
| NFR3.23 | 退避は専用領域の固定方式で原本bytesだけを保持し、名称やIDからパスを組み立てない。個人内容はログに記録しない | パス型とログ捕捉検査。退避を履歴UIへ拡張しない |

既決の条件を維持するため、追加の製品質問はない。具体的な実行境界・退避方式・テスト構成を次の技術設計で決める。本人のMacだけを対象とし、クラウドのSLA・水平拡張・遠隔監視は非該当。復元UIの完成条件をU3の最終操作支援と混同しない。

