# 進め方の調査根拠

## 調査範囲
リリース担当が既存規約、Git履歴・ブランチ、検証スクリプトと既存実装の調査文書を静的に読んだ。本人の回答・要約確認後にこの4文書へ統合した。今回ビルド・テスト・CI・実写真操作は実行していない。参加者はリリース担当のみで、追加担当者の意見があったとは記さない。

## 確認済み方針と観測事実
| 領域 | 本人確認済みの基準 | 観測した根拠・限界 |
|---|---|---|
| 作業と統合 | main中心の短い作業ブランチ、squash統合、フェーズ末コミット | `memory/team.md`。現在ローカルブランチはmain。直近履歴はPhase1実装 `d68db4d` とPhase2企画記録 `d2b98c7`。履歴だけで全ての統合手順を保証しない |
| 小さく動かす順序 | 既存選択の引継ぎ・記事画像1枚を早期検証する | 本intent `ideation/scope-definition/scope-definition-questions.md` Q3と承認済みscope-document、intent-backlog |
| テスト順序 | TDDのred-green-refactor、80%以上の行カバレッジ、統合前CI | `memory/team.md`の明示的Methodology/Ordering。テストコードの存在から推測した方針ではない |
| 既存検証 | Xcode/XCTest、全製品Swiftの行カバレッジ80%検査 | `scripts/verify-native.sh`、`scripts/check-coverage.swift`。前者は4テストtarget、後者はApp/Coreの未計測ファイルを拒否する。今回の実行成功やPhase2対応を証明しない |
| CI | 現行基準は統合前CI | 製品用CI構成は探索結果にない。`code-quality-assessment.md`も未構成と評価。Phase1の個別免除は今回の免除にしない |
| 配置 | 本人のMacでローカル実行、外部公開・独自クラウドなし | `memory/team.md`、本intentの確認済み範囲と制約。外部の実行環境・アカウントは今回確認していない |
| 記法 | Swift標準の命名、日本語の記録、追加整形ツールは計画で判断 | `memory/team.md`、`code-structure.md`。短い圧縮記法は実装の観測であり強制規約ではない |
| 変更の境界 | 通信禁止、ライブラリ非変更、手動保存、VoiceOver追加対応不要 | `memory/project.md`、本intentの本人回答。既存アクセシビリティ処理を削除する承認ではない |

## 参照した既存実装の調査文書
`aidlc/spaces/default/codekb/hitotsuzuri/`の以下6点を読んだ。
- `code-structure.md`: App/Core・4試験target、コード分類と命名の観測。
- `technology-stack.md`: Swift 6.0、macOS 27.0設定、SwiftUI/AppKit/PhotoKit、XCTest。実際のインストール版は未確認。
- `dependencies.md`: ローカル画像・許可・保存領域への依存。記事出力先の権限は未検証。
- `code-quality-assessment.md`: CI・独立した整形/静的検査設定の不在、既存カバレッジ検査と検証の限界。
- `architecture.md`: プロトコル注入、MainActor・actor、画像成功に依存した選択復元。
- `business-overview.md`: 写真4枚の探索・確定・保存・復元が現在の機能。記事・動画・投稿は未実装。

## 本人確認と残る未確定事項
`practices-discovery-questions.md` Q1で、本人はCI実行環境をまだ用意できないと回答した。Q2では、今は環境を決めず要件・設計を進め、実装計画で実行先・設定・費用を具体化して本人確認する案を選んだ。要約の`Looks correct`も記録されている。

統合前CIの条件は維持し、満たすまでは統合完了と扱わない。ローカルで手動実行したテストをCI実行済みと記録しない。CI実行先・実行元・権限・個人ライブラリとの分離・実行条件は未確定であり、runner登録や外部サービス設定を今回実施したとは記さない。

既存の作業・小さく動かす順序・TDD・配置・記法の方針は質問ファイルの要約で引き継ぎ確認した。回答と要約確認は、本段階全体の承認やルール反映を代替しない。
