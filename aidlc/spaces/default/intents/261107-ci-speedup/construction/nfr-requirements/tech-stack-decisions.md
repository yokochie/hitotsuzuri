# 技術選定の境界

## Sources
`../../inception/requirements-analysis/requirements.md`、`aidlc/spaces/default/codekb/hitotsuzuri/technology-stack.md`、本人確認済み質問・要約。

## Context
既存はGitHub Actions、xcode-27 runner、XCTest/XCUITest、xcodebuild、xcresulttool/xccov、Bash/Python標準ライブラリ。実機構成・実際の版は未調査。

## Decision
既存ツールを出発点とする。新言語、DB、クラウド、商用計測サービスは追加しない。キャッシュ、build-for-testing等の具体手法は計測と後続設計で比較する。本段階でrunnerの増設・版変更は決定しない。

## Consequences
新規依存と費用を抑えられるが、UI起動や既存runnerの制約で30%に届かない可能性がある。未達の場合は実測を示して相談する。

## Alternatives Considered
- runner増設・別CIへの移行: 構成、費用、権限が不明なので現時点で採用しない。
- 試験削減・カバレッジ低下: 品質維持の要件に反するため採用しない。
- 現行構成の無変更: 比較の出発点にはするが、高速化の達成策とはみなさない。
