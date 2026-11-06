# Team-Level Rules

> This team's affirmed practices and corrections. Loaded after `org.md` as
> strict-additive guidance; contradictions with broader policy are rejected.
> Populated by the practices-discovery affirmation gate. Edit at the gate,
> not directly.

## Way of Working
- `main`を中心に短い作業用ブランチを使い、検証後に変更をまとめて統合する。実装作業の起点・統合先は`main`、作業単位は1つのコミットへまとめる（squash merge）。
- AI-DLCの各フェーズ完了時に、そのフェーズの成果物と関連変更をGitへコミットする。実装ブランチの統合とフェーズ単位の記録は区別する。
- 要件と実装計画の本人確認後に実装へ進む。既存の保存済み選択と成果物を保護し、既知問題と新規回帰を区別する。
- 進捗・判断・検証結果は、このチャットと日本語Markdownで確認する。定時報告は要求しない。

## Walking Skeleton
- 最初に、部品をつないだ最小の一連の操作を動かし、実ライブラリ参照・ローカル画像取得・保存までの接続を確認する。
- Phase2では、既存選択の引継ぎと記事用画像1枚の書出しを早期に検証する。最小の一連の操作を確認してから、下書き・撮影情報・4枚出力・例外処理を完成させる。
- 最初の動く実装の範囲、本人が承認する検証コマンド、本人の実機確認項目は実装計画で定める。設計文書の確認だけを動作の実証と扱わない。

## Testing Posture
- **Methodology**: tdd
- **Methodology evidence**: 現行の`memory/team.md`で本人確認済み。Phase2でも維持する。テストファイルの存在だけからTDDと推定したものではない。
- **Ordering**: 各テスト可能な層で、先にテストを書いて意図した失敗を確認し、最小限の実装で成功させ、成功を保ちながら整理するred-green-refactorの順序で進める。
- 製品全体の80%以上の行カバレッジと統合前CIを維持する。既存のXCTest・Xcode・カバレッジ検査スクリプトを出発点とし、Phase2の計測対象と必要な追加を計画で明示する。
- CI構成は現行リポジトリで確認できず、本人も実行環境はまだ用意できないと回答した。今は実行先を決めず要件・設計を進め、実装計画でCI実行先・設定・費用の有無を具体化して本人確認する。実行元・権限・隔離・実行条件もその計画で扱う。
- Phase1のCI省略の個別決定を、Phase2の免除として引き継がない。統合前CIの条件を満たすまでは統合完了と扱わず、ローカルで手動実行したテストをCI実行済みと記録しない。
- 保存・復元・順序・日付候補・出力・失敗・取消等の自動試験と、実写真・写真アプリの編集結果・Sandbox・noteへの手動受渡しを確かめる本人の実機確認を区別する。未確認を自動試験の成功で補完しない。
- 本人指定によりVoiceOverの追加設計・検証は要求しない。既存実装を削除する方針にはしない。キーボード・狭幅・長文・状態の文字表示は今回の確認対象に残す。

## Guard Policy

<!-- Affirmed by the team. Mode: strict, relaxed, or off. Strict here holds for every intent, whatever one person asks in chat; relaxed or off here applies to every intent whose policy came from its scope, unless project.md or the person sets another; changing this line changes it. A section under the retired Change Control heading, written by an earlier release, is still read. -->

## Deployment
- 本人のMacでローカル実行を完成させる。配布の確定・公開、AWS等への配置、独自クラウド機能はPhase2の範囲に含めない。
- 本人向けの起動・確認手順はXcodeでの操作を中心に日本語で残し、自動試験の再現コマンドは別に記す。
- ビルド・自動試験を通したアプリを本人が起動して実機確認する。OS・Xcode・署名設定と、戻す必要がある場合の手順を計画・検証記録に残す。
- 有料サービス・有料ツールを前提にしない。CIも外部公開やクラウド配置を追加する理由とはしない。

## Code Style
- Swift・SwiftUIの標準的な命名と記法を使い、既存のプロトコル境界・型付き失敗・並行処理の責務を理解して差分を加える。
- 現行コードに圧縮記法が多いことは観測事実であり、新規コードを読みにくく詰める規約ではない。目的と処理の境界が読める記述を優先する。
- 独立したformatter/linter設定は確認できない。追加ツールを導入済み・採用済みとせず、必要な場合は計画で理由と実行方法を明示する。
- コメント・実行手順・判断・検証結果は日本語で残し、Swift・Xcodeの経験を前提にしない。識別子やAPI名はコードの表記を保持する。
## Forbidden

<!-- Team-specific forbidden patterns -->

## Mandated

<!-- Team-specific mandates -->

## Corrections

<!-- Self-learning loop appends here. -->
