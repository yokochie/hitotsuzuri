# U1 技術選定の境界

入力は`aidlc/spaces/default/codekb/hitotsuzuri/technology-stack.md`、`../functional-design/functional-spec.md`・`rules.md`、`../../../inception/contract-design/contract-summary.md`。既存構成の観測と今回の採用方針を区別する。

| 項目 | 方針 | 理由・代替 |
|---|---|---|
| 言語/アプリ | 既存Swift 6.0設定、SwiftUI/AppKit、macOS27.0対象、Sandboxを維持 | Web化や別アプリは不要、既存選択/写真権限と接続 |
| 並行処理 | 既存actor/Task/単調時計を基準に、UIとI/O/画像の責務を分離 | 同期UI処理は応答性/取消を損なう。具体APIはNFR Designで確認 |
| 写真/変換 | PhotoKitの読取専用取得とOS標準画像変換を候補にする | 追加第三者パッケージ/外部変換サービスを使わない。現在編集画像・縮小・資源のAPI成立性は次の設計で一次資料/試作により検証 |
| 保存 | 独立記事領域、不変操作レコード＋確定参照の切替、既存Codable JSON/標準ファイル機構を出発点 | 単一巨大封筒は全履歴再書込を招く。データベース追加より小さい差分。ただし原子性/排他/耐障害性はOS上で実証するまで成立済みとしない |
| 指紋 | 既存CryptoKit SHA256を第一候補とし版付き共通符号化をWorkspace所有にする | U1/U2別実装を防ぐ。確定するバイト表現とテストベクトルはNFR Designの責務 |
| 試験/CI | 既存XCTest/UIと承認済み検証スクリプト、GitHub標準xcode-27 | 外部有料追加なし、合成fixture、80%以上と統合前CIを維持 |

NFR5.2: 新規依存/有料ツール/サービスを追加せず、clean checkoutから標準ツールで検証可能にする。OS/SDK依存APIを未検証のまま確定コードへ持ち込まず、対応版と失敗分類・試験証拠をNFR/Infrastructure Designへ記録する。

既存CodeKBはインストール済み環境の証明ではない。本人Macで確認したmacOS27.2/Xcode27.2(27B52)、CIは実行時版を記録する。画像APIとファイル確定の詳細な実装コードはこの段階で生成しない。
