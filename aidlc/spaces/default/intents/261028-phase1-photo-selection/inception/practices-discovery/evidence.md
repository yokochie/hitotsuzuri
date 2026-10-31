# 開発・検証方針 — 根拠と確認待ち事項

## 状態

本人への5領域の確認と要約確認が完了し、回答に基づく最終統合を実施した。段階の承認・規約への反映は未実施。対象はGreenfieldで、active spaceは`default`、現在段階はPractices Discovery。

## 調査者と調査範囲

Pipeline & Deploy担当が下記資料と限定的なリポジトリ一覧を確認した。今回の参加者設定では協力担当はなく、別担当の調査や承認を実施済みとは記さない。

| 入力・証跡 | 確認したこと |
|---|---|
| `../../aidlc-state.md` | Greenfield、mvp、Standardの深さとテスト戦略、Ideation完了・Inception開始、まだPractices Affirmed Timestampなし |
| `../../../../memory/org.md` | Way of Working、Walking Skeleton、Testing Posture、Deployment、Code Styleの既定候補。test-after、mvpで80%以上の行カバレッジと統合前のCI実行 |
| `../../../../memory/team.md` | 5領域はコメントによる未記入テンプレート。チームの確定慣行として扱える内容なし |
| `../../../../memory/project.md` | フェーズ完了ごとのGitコミットは本人指示で記録済み。他の5領域はテンプレート |
| `../../../../memory/phases/inception.md` | 検証可能な要件、Given/When/Thenの受け入れ条件、判断の根拠と追跡性 |
| `../../ideation/scope-definition/scope-document.md` | ローカル実行、中核と復元・性能確認、対象外機能、実連携を早期確認する順序、日本語手順、実装開始前の確認条件 |
| `../../ideation/feasibility/feasibility-assessment.md` | Xcode 27.1・Swift 6.4での限定的コンパイル確認と、写真アクセス等の実機未検証事項 |
| `README.md` | `hitotsuzuri`という名称のみ。開発・テスト規約の記述なし |
| リポジトリ一覧の限定検索 | アプリ用Xcodeプロジェクト、Package.swift、Swift整形設定、CIのYAMLは検出されなかった。AI-DLC設定や検証用Swiftは製品アプリの慣行に数えない |
| `git log -1` | 最新コミット`7ad30aae87d1ff19ca33d899101c698b2679fdf6`、件名「docs: ひとつづりPhase 1のIdeation成果物を記録」 |

パスはこの文書からの相対位置。ただし`README.md`とGitコマンドはリポジトリルートが基準。テンプレートの例文を確定規約として採用していない。

## 本人が既に決めた内容

- 各AI-DLCフェーズ完了時のGitコミット、要件と計画の確認後のConstruction開始。
- 本人のMacでローカル実行、写真ライブラリを変更しない、画像取得通信を行わない、今回の外部公開やクラウド機能は対象外。
- 実機確認は本人が行い、経験を前提にしない日本語の手順・記録を残す。

これらは再質問して選び直しを求めず、各領域の提案の制約として引き継ぐ。

## 本段階で確認した決定

| 領域 | 確認された方針 | 根拠 |
|---|---|---|
| Way of Working | main中心と短い作業用ブランチ、検証後にまとめて統合。フェーズ完了時のコミットを継続 | 質問ファイルQ1=A、要約確認 |
| Walking Skeleton | 実ライブラリ参照・ローカル画像取得を早期確認し、選択・保存まで一通り動く最小構成を先に作る | Q2=A、要約確認 |
| Testing Posture | テストを先に書き、失敗を確認して実装するtdd。80%と統合前CIは維持 | Q3=B、要約確認 |
| Deployment | Xcodeでのローカル実行・確認を中心に日本語手順を残す。外部公開なし | Q4=A、要約確認 |
| Code Style | Swift標準的記法を基本とし、追加ツールは必要性を計画で明示 | Q5=A、要約確認 |

記録先は[practices-discovery-questions.md](practices-discovery-questions.md)。Consolidated Summary Confirmationの回答は`Looks correct`。初稿のtest-afterは提案であり、本人が選択したtddへ置き換えた。テストの作成順序とカバレッジ・CI条件を混同せず、既定の品質条件を維持している。

## 未解決の点

- GitリモートやCI実行先は本稿で未確認。CI方式や提供元を勝手に確定しない。外部公開不要とCI不要は同義ではない。
- カバレッジの具体的な対象と取得コマンドは、アプリ構成・検証計画が決まってから定義する。
- 最小の一通り動く実装の範囲は、承認済みの優先順位と実装単位の計画に合わせる。PhotoKitの実機確認をFakeの成功だけで代替しない。
- 本稿では法令適合性の新たな評価や、既存の規約を弱める判断はしていない。

## 次の手順

親担当が最終統合版を本人の承認へ提示する。承認後の所定の規約反映を親担当が実施する。本担当は規約への反映・段階承認・Gitコミットを実施していない。
