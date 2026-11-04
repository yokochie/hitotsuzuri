# U2 技術選択

## 入力・観測との区別
`../functional-design/functional-spec.md`、`../../../inception/requirements-analysis/requirements.md`、`../../../inception/contract-design/contract-summary.md`、`aidlc/spaces/default/codekb/hitotsuzuri/technology-stack.md`から既存構成を継続する。CodeKBは調査時点の構成であり、現在の実行版/試験成功の証拠とはしない。具体的な変更対象と検証コマンドは後続Code Generation計画で示す。

| 選択 | 判断・根拠 | 代替と影響 |
|---|---|---|
| Swift 6、macOS 27を継続 | 既存製品の対象を変更せず、型付き値・失敗・並行処理境界を共用 | Web/Electron化・OS拡張は今回の価値に不要 |
| 既存SwiftUI/AppKitの画面境界 | 全欄・レスポンシブ配置はSwiftUI、ウィンドウ閉鎖/終了の既存AppKit接続を保持。単一編集セッションを再配置から分離 | 独自ブラウザ描画はMarkdown実行/権限の新境界を増やすため不採用 |
| ArticleWorkspace/C1と既存JSON保存 | UIが保存実装を重複せず、元操作の照合・競合・未知版保護を使う。既存永続schemaの変更なし | DB導入や自動保存へ変えない |
| I/Oのない本文投影、共通指紋 | 記事ID付き不変文脈、source/contentから共通SHA256規則。画面本文と出力本文を同じ規則へ | 別々の投影実装・大域active article検索をしない |
| OS操作ポート/Fake | C3はU2が型と呼出しを定義、U3がクリップボード/出力/Finderを実装。U2単独試験を可能にする | 未接続の成功stubは製品では使わない |
| PhotoKitの既存非通信読取境界 | 写真表示と保存を独立させ、表示用と成果物用を区別。保持量を測り、キャンセル世代を照合 | 写真ライブラリ書込や通信取得は不採用 |
| XCTest・既存Bash検証/カバレッジ | TDDと全製品80%以上・既存UI回帰を維持。追加の外部パッケージ/formatter/linterなし | 確認済みCIは標準の公開macOS環境を継続、有料大型runnerは追加しない。CIの既知失敗は未解決として残る |
| 分類だけのローカル診断 | 私的な記事/写真識別情報を出さず、必要な失敗原因と計測値を示す | 外部analytics・クラウド・アラートは追加しない |

## 構成と検証の境界
選択はNFR1.20〜21、NFR2.20〜24、NFR3.20〜25、NFR4.20〜23、NFR5.20〜21、NFR6.20〜23、NFR7.20〜21を実現するための既存技術の継続。性能・ログ非漏えい・閉鎖保留が成立したと本書だけで断定しない。具体的なタスク分離、保持の責任、OS終了の保留、純粋投影のエスケープはNFR Designで設計する。
