# U2 performance-requirements

根拠: [機能仕様](../functional-design/functional-spec.md)、[ルール](../functional-design/rules.md)、[要件](../../../inception/requirements-analysis/requirements.md)、[契約](../../../inception/contract-design/contract-summary.md)、[CI省略](../../../change-decisions/2026-10-31-local-verification.md)。本書は要求であり動作確認結果ではない。

| ID | 条件 | 検証 |
|---|---|---|
| NFR2.21 | 復元の4枚画像検証は全体15秒、各要求15秒との早い方で期限判定。受付・キュー待ちを含む絶対期限ちょうど以降は成功不採用 | 注入時計で期限前/同時/後・遅延応答を検証 |
| NFR2.22 | 復元・再確定の画像も既存256 MiB予算と最大8同時要求へ含める。生存する全バッファと予約を計上 | 返却画像保持・取消・世代切替・小予算の回帰 |
| NFR2.23 | 復元の探索・I/OでUIを不要に停止しない。復元途中の編集は禁止。画面反映95%以上200msと10往復測定はU3 | 遅延Fakeで独立状態案内を確認。U3最終実測を代替しない |

既決の条件を維持するため、追加の製品質問はない。具体的な実行境界・退避方式・テスト構成を次の技術設計で決める。本人のMacだけを対象とし、クラウドのSLA・水平拡張・遠隔監視は非該当。復元UIの完成条件をU3の最終操作支援と混同しない。

