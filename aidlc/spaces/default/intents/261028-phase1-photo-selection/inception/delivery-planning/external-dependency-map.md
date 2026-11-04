# 外部依存と未実施事項

> 2026-10-31 本人承認による変更: 今回のPhase 1ではCIを省き、統合前のローカルビルド・自動テスト・行カバレッジ80%以上を必須とする。本文のCI実行・専用Mac・ランナー準備に関する旧条件は適用しない。TDD・本人の実機確認は維持する。[変更記録](../../change-decisions/2026-10-31-local-verification.md)。


入力: [要件](../requirements-analysis/requirements.md)、[ストーリー](../user-stories/stories.md)、[詳細画面](../refined-mockups/mockups.md)、[構成要素](../domain-design/components.md)、[単位定義](../units-generation/unit-of-work.md)・[依存](../units-generation/unit-of-work-dependency.md)・[対応表](../units-generation/unit-of-work-story-map.md)、[内部契約](../contract-design/contract-summary.md)、[開発規約](../practices-discovery/team-practices.md)、[確認回答](delivery-planning-questions.md)。

1回の実装・検証を動く増分にする区切りをBoltと呼ぶ。本人のMacとPhotos、CI登録の権限が主要な外部依存。クラウドアプリ基盤・外部投稿APIは使わない。

| 依存 | 所有者 | 必要な時点 | リードタイム | 遅れた場合 |
|---|---|---|---|---|
| Xcode・SDK・署名とSandbox設定 | AIが設定案、本人が環境確認 | B1設計/ビルド/起動 | 未定 | 自動テスト可能部分を進め、実起動は未確認とする |
| システム写真ライブラリ・OS許可 | 本人 | B1の統合実機確認 | 未定 | 手順を提示して待機。Fakeを実機結果に置き換えない |
| 複数フォルダ・3階層・順序確認データ | 本人 | B1 | 未定 | 非破壊の確認用構造を本人が用意 |
| 正常復元・欠損確認用データ | 本人 | B2 | 未定 | 専用の確認データで実施。アプリの変更機能は作らない |
| 100枚以上のローカル写真 | 本人 | B3性能 | 未定 | 対象と取得状態を記録し確認待ちにする |
| 専用CI環境・登録権限・信頼条件 | 本人とAI構成担当 | B1からのmain統合前 | 未定 | ローカル検証は行えるがCI条件を満たすまで統合しない |
| 総合検証コマンドの承認 | 本人 | 最初の単位検証前 | 未定 | 正確な実コマンドを提示して確認。未設定のまま代替実行しない |

## CI設定の未実施事項

専用実行アカウント/隔離方式、GitHub上のリポジトリ公開範囲と実行許可、runner登録・一時トークン・起動方法・停止解除、署名不要の自動ビルド、ログと成果物の保持をInfrastructure Designで具体化する。インストール・常駐化・認証変更はこの計画作成では行っていない。

[GitHub公式資料](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners)に沿ってリポジトリ所有者の登録権限とMacの管理条件を確認する。公開リポジトリの信頼されないコードを本人Macで実行させない。専用環境にPhotosの私用ライブラリへの権限は与えず、自動テストはFakeを使用する。

## 確認待ちの扱い

設計・コードに必要な具体値と、本人の実機データ・CI登録を分ける。権限・データ・CI未成立の項目は結果を保留し、基準を下げて完了扱いにしない。Phase 1完成前に全要件と本人の確認結果を照合する。
