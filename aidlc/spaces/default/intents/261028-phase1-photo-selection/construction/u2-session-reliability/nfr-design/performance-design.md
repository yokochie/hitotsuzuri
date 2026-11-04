# U2 性能設計

根拠: [性能](../nfr-requirements/performance-requirements.md)、[保護](../nfr-requirements/security-requirements.md)、[容量](../nfr-requirements/scalability-requirements.md)、[信頼性](../nfr-requirements/reliability-requirements.md)、[診断](../nfr-requirements/observability-requirements.md)、[技術選定](../nfr-requirements/tech-stack-decisions.md)、[機能仕様](../functional-design/functional-spec.md)、[契約](../../../inception/contract-design/contract-summary.md)。CIは[本人の変更決定](../../../change-decisions/2026-10-31-local-verification.md)により省略。以下は設計であり未実装。

## P21 復元の期限と画像予算

対応NFR2.21〜NFR2.23。復元開始時に4枚検証の共通単調時計期限を確定し、各要求へ渡す。個別の受付期限と早い方を使い、応答採用境界で現在時刻が期限以上なら拒否。タイマーTaskの実行順で成功を決めない。暫定画像で期限を更新しない。

復元と確定は同じImageAccessを使い、最大8要求・通常4/検証4、256 MiBの生存バッファと予約の合計予算を共用する。キャッシュ外の返却画像や描画プロバイダが保持するバッファも実参照がある間は数える。復元途中の一時画像を成功前に画面へ公開せず、失敗時は全一時参照を解放する。4枚全成功後は同じバッファを画面へ移譲して二重に複製しない。

探索/読込/退避はUI外で実行し、復元状態だけをUIへ公開する。復元中の編集は禁止するが、進行/案内表示を止めない。U3の最終画面反映・100枚以上/10往復測定は未測定と区別する。

