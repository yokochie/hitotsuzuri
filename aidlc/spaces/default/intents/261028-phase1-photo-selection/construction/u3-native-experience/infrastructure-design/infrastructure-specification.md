# U3 ローカル実行環境

根拠: [性能設計](../nfr-design/performance-design.md)、[保護設計](../nfr-design/security-design.md)、[論理構成](../nfr-design/logical-components.md)、[機能仕様](../functional-design/functional-spec.md)、[構成要素](../../../inception/domain-design/components.md)、[契約](../../../inception/contract-design/contract-summary.md)。[CI省略](../../../change-decisions/2026-10-31-local-verification.md)を適用する。

## Deployment

| Facet | Choice | Rationale |
|---|---|---|
| Compute | 本人Mac上の既存アプリ、Swift6/SwiftUI/PhotoKit | 新たな配置先なし |
| Networking | アプリによる画像通信なし | 読み取り専用方針 |
| Storage | 既存Application Supportの設定と確定参照 | 保存形式/場所を増やさない |
| Environments | 開発/本人の現行Macのみ | 配布公開は範囲外 |
| IaC | 非適用 | 外部サービスなし |
| Sizing | 画像256MiB/8要求/512pixelを維持 | 所有画像と予約を計上 |
| 任意測定 | 本人Macの画面フレームと入力時刻を照合 | 測定時だけOS許可を本人操作 |

## Infrastructure Services

| Service | Role | Configuration | Notes |
|---|---|---|---|
| 既存ローカル画像管理 | cache/queue | 必要集合、表示4/検証4、絶対期限15秒 | 外部キャッシュなし |
| 既存専用保存領域 | storage | 設定/確定と保護された退避 | UIから直接変更しない |
| ローカル測定補助 | diagnostics | 入力時刻/連番とwindow server表示時刻の照合、画像はメモリ内で破棄 | 通常起動では無効、外部送信なし |

## Shared Infrastructure

| Shared Resource | Owner Unit | Consumer Units | Access Boundary |
|---|---|---|---|
| 同じmacOSアプリとCore | U1 | U2/U3 | C1〜C4 |
| 設定・確定JSON | U1/U2が完全化 | U3は状態のみ利用 | 永続化担当 |
| 画像予算と要求制御 | U1 | U2/U3 | 進行・画像担当 |

## 計測候補の成立性

ローカルXcode SDKのScreenCaptureKit/SCStream.hのSCStreamFrameInfoDisplayTimeには、フレームについてwindow serverで表示されたmach absolute timeと記されていることを確認した。入力側も同じ単調時刻基準を使う候補とし、実装計画で型検査と同一時刻系の校正、実フレームの連番/選択表示の対応を先に確認する。ヘッダ確認だけで性能測定済みとはしない。OS許可や実フレーム取得ができなければ本人確認項目を未確認として残す。

