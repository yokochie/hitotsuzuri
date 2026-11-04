# U2 診断と検証

根拠: [性能](../nfr-requirements/performance-requirements.md)、[保護](../nfr-requirements/security-requirements.md)、[容量](../nfr-requirements/scalability-requirements.md)、[信頼性](../nfr-requirements/reliability-requirements.md)、[診断](../nfr-requirements/observability-requirements.md)、[技術選定](../nfr-requirements/tech-stack-decisions.md)、[機能仕様](../functional-design/functional-spec.md)、[契約](../../../inception/contract-design/contract-summary.md)。CIは[本人の変更決定](../../../change-decisions/2026-10-31-local-verification.md)により省略。以下は設計であり未実装。

## O21 記録と試験

対応NFR5.21、NFR5.22。復元状態と失敗分類だけを通常診断へ記録し、写真ID・名称・原本bytes・退避パスを出力しない。復元/画像の時間は単調時計で検証時だけ測る。外部監視を追加しない。

U2専用の復元/回復テストを追加し、Fakeの権限・参照・画像・時計・失敗注入I/Oで各失敗をTDD検証する。U1回帰も全体で実行し、製品全Swiftの行カバレッジ80%以上を維持。統合前はローカルビルド/全単位テスト/カバレッジを実施する。既存の承認コマンドはU1だけを選択するため、U2を含む検証へ変更する時は本人へ新コマンドを提示し、勝手に承認済み扱いにしない。

本人向け手順は保存→終了→再起動の正常復元と、写真アプリ側での変更→再起動を区別する。個人データの削除や権限リセットは自動で行わない。テスト済みと本人確認待ちを記録で分ける。

