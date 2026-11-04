# U2 統合前ローカル検証

根拠: [性能](../nfr-design/performance-design.md)、[保護](../nfr-design/security-design.md)、[容量](../nfr-design/scalability-design.md)、[信頼性](../nfr-design/reliability-design.md)、[診断](../nfr-design/observability-design.md)、[論理構成](../nfr-design/logical-components.md)、[構成要素](../../../inception/domain-design/components.md)、[機能仕様](../functional-design/functional-spec.md)、[契約](../../../inception/contract-design/contract-summary.md)、[CI省略](../../../change-decisions/2026-10-31-local-verification.md)。追加環境の構築結果ではなくU2の構成設計。

## 実行順序

1. 既存アプリのテストを基準として確認する。対象ファイルと差分を計画し、U2専用テストターゲットを追加して実行可能にしてからTDDを始める。
2. 読込/意味検証・退避/原本保護・復元/編集競合・案内表示をRed→Green→Refactorで進める。テストデータは合成画像と専用一時領域だけ。
3. U2単位テストに加えU1回帰を実行し、アプリ+Coreの全手書きSwiftのカバレッジ80%以上を確認する。対象を除外して通さない。
4. 保存→終了→再起動、欠損・取得不可・権限なしの本人確認手順を記録する。破損回復の自動テスト結果と個人ライブラリでの確認を分ける。
5. 検証したソースと結果を対応づけて統合し、フェーズ完了時にコミットする。CIは作らない。

| 段階 | 必須条件 | 記録 |
|---|---|---|
| 計画 | 変更ファイル/テスト/既存回帰 | 本人の計画承認 |
| 自動検証 | U2とU1成功、製品80%以上 | コミット/実行結果/対象範囲 |
| 実機 | 正常復元と回復案内 | 日本語の未確認/確認済み欄 |
| 統合 | 必須失敗を残さない | 対象ソースと結果の対応 |

既存承認コマンドbash scripts/verify-u1.shはU1のみを選択する。U2を含む最終検証コマンドへ変更するときは専用確認で本人の承認を得る。コード計画ではU2専用コマンドを具体化するが、それを最終検証承認の代替としない。既存コマンドのスクリプトを黙って別用途へ変更しない。

起動・署名は既存Xcode構成を維持し、新しい権限や外部アカウントを要求しない。戻す際は対象の変更を特定し、正常JSONと退避原本を自動削除しない。未知版の旧アプリ読込み可否を確認する。Git reset/cleanで本人作業を消す復旧は行わない。

