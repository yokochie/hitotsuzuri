# Project-Level Rules

> Project-specific specialisation and corrections. Loaded after `org.md` and
> `team.md` as strict-additive guidance; contradictions with broader policy
> are rejected. Populated by practices-discovery and the self-learning loop.
>
> Use sparingly: most teams don't need a project layer. Reach for it
> only when this specific project needs stable, durable guidance beyond the
> team practice (for example, package-specific release checks or an additional
> regression suite for a legacy component).

## Way of Working

<!-- Project-specific specialisation. Example: -->
<!-- This monorepo requires package-scoped branch names and a package owner -->
<!-- review in addition to the team's normal merge policy. -->

- AI-DLCの各フェーズ完了時に、そのフェーズの成果物と関連変更をGitにコミットする。 (learned 2026-10-28) <!-- cid:261028-phase1-photo-selection:intent-capture:1acdb008f63ae2ba3b8720bd6e7429b282011566f529a001eb0e9dd635add5ce -->

## Walking Skeleton

<!-- Project-specific specialisation. Example: -->
<!-- The walking skeleton must exercise the legacy service adapter as well -->
<!-- as the new service boundary. -->

## Testing Posture

<!-- Project-specific specialisation. -->

## Guard Policy

<!-- Project-specific. Mode: strict, relaxed, or off. Strict here holds for every intent, whatever one person asks in chat; relaxed or off here applies to every intent whose policy came from its scope, unless the person sets another; changing this line changes it. A section under the retired Change Control heading, written by an earlier release, is still read. -->

## Deployment

<!-- Project-specific specialisation. -->

## Code Style

<!-- Project-specific specialisation. -->

## Tech Stack

<!-- Technology choices locked for this project. -->

## Decided

<!-- Decisions made in earlier stages that should not be re-asked. -->
<!-- Format: DECIDED: [decision] (Stage [slug], [date]) -->

## Scope Overrides

<!-- Custom scope rules for this project. -->

## Forbidden

<!-- Populated by practices-discovery affirmation gate. -->
<!-- Format: NEVER [behavior] (affirmed [date]) -->
<!-- Example: NEVER throw exceptions across service layer boundaries (affirmed 2026-05-17) -->

- NEVER アプリから写真ライブラリ内の写真・アルバム・フォルダを変更する。 (affirmed 2026-10-29)

- NEVER アプリから画像取得のための通信を要求する。 (affirmed 2026-10-29)

- NEVER 今回のPhase 1へnote連携・記事生成・動画生成・SNS投稿・クラウド機能・毎週の自動実行と通知・写真本体の恒久複製・履歴管理を追加する。 (affirmed 2026-10-29)

- NEVER 設計資料の技術選定や参考コードを、成立性を検証せず確定仕様として扱う。 (affirmed 2026-10-29)

## Mandated

<!-- Populated by practices-discovery affirmation gate. -->
<!-- Format: ALWAYS [behavior] (affirmed [date]) -->
<!-- Example: ALWAYS use Result<T,E> for fallible operations in service layer (affirmed 2026-05-17) -->

- ALWAYS アプリ表示名を「ひとつづり」、リポジトリ名を`hitotsuzuri`、Xcodeプロジェクト名を`Hitotsuzuri`、Swiftアプリ型名を`HitotsuzuriApp`とする。 (affirmed 2026-10-29)

- ALWAYS Phase 1をSwiftUIによるmacOSネイティブアプリとして実装し、まず本人の現在のMacでのローカル実行を確認する。 (affirmed 2026-10-29)

- ALWAYS システム写真ライブラリ1つの中にある複数の写真フォルダを対象とする。 (affirmed 2026-10-29)

- ALWAYS 要件と実装計画の本人確認後にConstructionへ進む。 (affirmed 2026-10-29)

- ALWAYS 要件・設計判断・進捗・検証結果を日本語Markdownへ残し、Swift・Xcodeの経験を前提にしない実行・検証手順を用意する。 (affirmed 2026-10-29)

- ALWAYS 写真アクセス等、本人による実機確認が必要な項目を明示する。 (affirmed 2026-10-29)

- ALWAYS AI-DLCの各フェーズ完了時に、そのフェーズの成果物と関連変更をGitにコミットする。 (affirmed 2026-10-29)

## Corrections

<!-- Project-specific corrections from human feedback. -->
<!-- Format: NEVER/ALWAYS [behavior] (learned [date]) -->
- VoiceOverの考慮は不要とする。今後の本プロジェクトの作業でも、VoiceOverの追加設計・検証を要求しない。 (learned 2026-11-04) <!-- cid:261104-phase2-article-support:rough-mockups:7b01b011ff3977cb3371a24b58d270ac71fd3e4bae99f88e0ae1631e117066ea -->
