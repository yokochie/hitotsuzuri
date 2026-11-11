# Team-Level Rules

> This team's affirmed practices and corrections. Loaded after `org.md` as
> strict-additive guidance; contradictions with broader policy are rejected.
> Populated by the practices-discovery affirmation gate. Edit at the gate,
> not directly.

## Way of Working
- `main`を起点・統合先とする短い作業用ブランチを使い、検証後にsquash mergeする。
- 各フェーズ完了時に成果物と関連変更をGitへコミットする。要件と実装計画の本人確認後に実装する。
- 判断・検証結果・手順を日本語で残し、既存の未コミット変更を保護する。

## Walking Skeleton
- 既存の「最小の一連の操作を先に動かして接続を確かめる」方針を維持する。
- 今回はCIの変更前計測から変更後の実行・テスト結果・カバレッジ確認までを小さく通してから改善を広げる。具体的な順序と検証コマンドは後続の計画で本人確認する。

## Testing Posture
- **Methodology**: tdd
- **Methodology evidence**: 既存の`aidlc/spaces/default/memory/team.md`で本人確認済み。CI高速化の依頼を試験削減の許可とは解釈しない。
- **Ordering**: 各テスト可能な層で、変更を表すテストの意図した失敗を先に確認し、最小の変更で成功させ、成功を維持しながら整理する。
- 製品全体の80%以上の行カバレッジと統合前CIを維持する。Core、必須smoke、機能UI、試験実行の実在確認を維持し、性能測定は本人Macの別区分で扱う。
- 現在はGitHub Actionsの`xcode-27` runnerを使用している。旧記録の「CI未用意」は過去の状態であり、現状の説明には使用しない。
- ローカル試験とGitHub Actionsでの成功を区別する。実行時間・待機時間・環境・対象commitを記録して比較する。
- 実写真やSandbox等の本人Macでの確認を自動試験の成功で代替しない。VoiceOverの追加設計・検証は要求しない。

## Guard Policy

<!-- Affirmed by the team. Mode: strict, relaxed, or off. Strict here holds for every intent, whatever one person asks in chat; relaxed or off here applies to every intent whose policy came from its scope, unless project.md or the person sets another; changing this line changes it. A section under the retired Change Control heading, written by an earlier release, is still read. -->

## Deployment
- 本人Macで利用するmacOSアプリとして扱い、今回のCI改善を外部公開・独自クラウド・配布方式追加の理由としない。
- 有料サービス・有料ツールを前提にしない。CIを動かすMac・台数・同時実行枠の変更範囲は、現状を調べてから本人と相談して決める。現時点で追加機や同時実行枠の増加は決定していない。
- PRと`main`更新の既存CIを出発点に、変更の戻し方と再実行手順を日本語で残す。

## Code Style
- Swift/SwiftUIの既存責務を保ち、CIは既存のYAML、Bash、Python、Swiftの検査スクリプトへ読みやすい差分を加える。
- formatter/linterなどの新規ツールは導入済みと扱わず、必要性があれば計画で明示する。
- 手順・コメント・判断は日本語とし、識別子・API・コマンドは元の表記を保つ。
## Forbidden

<!-- Team-specific forbidden patterns -->

## Mandated

<!-- Team-specific mandates -->

## Corrections

<!-- Self-learning loop appends here. -->
