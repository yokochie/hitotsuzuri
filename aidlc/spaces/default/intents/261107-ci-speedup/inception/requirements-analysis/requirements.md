# CI高速化の要件

## Intent analysis
本人がPRの結果を待つ時間を短縮し、品質を維持して変更を早く統合できるようにする。全チェック完了を優先し、失敗の早期検出も改善対象とする。[desc][Q1]

## Sources
- [desc] Initial description: CIを早くしたいです
- [scope] Workflow-selected scope: infra
- [Q1] `requirements-analysis-questions.md` Q1=C。
- [Q2] 同ファイルQ2=B、要約確認=Looks correct。
- [memory:M1] `../practices-discovery/team-practices.md`: TDD、80%以上、統合前CI、有料サービスを前提にしない方針。
- `../practices-discovery/evidence.md`: 現行CIの観測。Core後にsmoke・全機能、groupごとのxcodebuild。実測前なので原因は未確定。
- `aidlc/spaces/default/codekb/hitotsuzuri/business-overview.md`: 本人Macで使う写真・記事制作アプリ。旧画像取得改善の記述は今回の追加要件にしない。
- `aidlc/spaces/default/codekb/hitotsuzuri/architecture.md`: 単一macOS App/Core、外部backendなし。
- `aidlc/spaces/default/codekb/hitotsuzuri/code-structure.md`: tests、scripts、.githubの責務。

## Functional requirements
| ID | 優先度 | 要件・受入条件 |
|---|---|---|
| FR1 | Must | 変更前CIの実行時間と待機時間を分け、対象commit、run、環境、試験対象、キャッシュ条件、成否を記録する。Given 現行CI、When 計測する、Then 全体・job・主要区間を比較可能な単位で記録する。失敗・取消・欠損データは成功時間へ混入せず、理由を明記する。 |
| FR2 | Must | PRの全必須チェック完了を優先して短縮し、最初の失敗が判明するまでの時間も評価する。Given 同等の条件、When 変更後を測る、Then 前後の全体時間と失敗検出時間を区別して示す。失敗事例がなければ後者は未測定とし、成功runから推測しない。 |
| FR3 | Must | Core、必須smoke、機能UI、試験実行の実在確認と全製品カバレッジ検査を維持する。Given 変更後CI、When 正常実行する、Then 必要な試験の実行証跡とカバレッジ結果を得る。試験未実行・結果欠損・不合格を成功として扱わない。重複の整理は同等の検出能力を証明する計画で扱う。 |
| FR4 | Must | runnerの実機台数、共有状況、同時実行枠、費用、変更権限を調査する。Given 調査結果、When 実行環境変更を提案する、Then 本人と変更範囲を決めてから適用する。情報を取得できない場合は不明として報告し、増設・枠増加を承認済みと扱わない。 |
| FR5 | Must | PRとmain更新の既存必須検証を保ち、CI失敗・取消・時間切れを明確にする。Given 同一refの更新や中断、When 再実行する、Then 以前の実行の途中成果を今回の成功として使わず、正しいcommitの完了判定を行う。 |
| FR6 | Must | 前後比較、未達・未確認、再実行方法、戻し方を日本語で記録する。Given 変更差分、When 復旧が必要になる、Then 変更前構成へ戻す対象と確認手順を特定できる。ローカル試験と遠隔CIの成功を区別する。 |

## Non-functional requirements
| ID | 優先度 | 基準・検証 |
|---|---|---|
| NFR1 | Must | 全チェック完了までの時間を変更前比30%以上短縮することを初期目標とする。短縮率=(変更前−変更後)/変更前。計測後に実現性を確認し、比較条件・標本数・集計方法を実装前の設計で明示する。キュー待ちと実行時間を別記し、どちらを30%の判定対象にするかも計測結果に基づき本人確認する。変更前0・欠損・条件不一致なら判定不能、30%未満なら未達とする。目標変更は本人と相談する。[Q2] |
| NFR2 | Must | 全製品80%以上の行カバレッジと統合前CIを維持する。80%未満、欠損、未実行は不合格。既知問題と新規回帰を区別する。[memory:M1] |
| NFR3 | Must | 有料サービス・ツールを前提にしない。既存の最小権限、認証情報非保持、Actions依存の固定などの保護を維持する。秘密情報・実写真を比較記録やCI成果物に追加しない。[memory:M1] |
| NFR4 | Must | 初回・キャッシュなしでも必須検証が完了し、古い・不整合なキャッシュから誤った成功を返さない。キャッシュ・並列化を採用する場合は隔離と復旧を設計し、欠損時も通常経路で検証する。[FR3][FR5] |

## Constraints
- TDDの順序、要件・実装計画の本人確認、フェーズ完了時のコミット、日本語記録を維持する。
- アプリの機能、写真ライブラリ、配布方式、外部クラウドを追加・変更する目的ではない。
- VoiceOverの追加設計・検証は要求しない。
- 他作業の未コミット変更を保護する。

## Assumptions & Open Questions
- 実測値、runnerの構成・権限は未確認。FR1/FR4で解決する調査事項であり、成立済みの前提ではない。
- 30%目標の測定区間・標本数・集計方法はNFR1に従って実装前に具体化する。目標達成の証拠がない段階で達成と記録しない。

## Out of scope
- 試験やカバレッジ基準を弱めること、追加費用を前提とする構成、未承認のrunner増設。
- アプリ機能追加、写真取得仕様の変更、配布公開、通知サービス。
- CI高速化と無関係なUI、認証、検索、業務データ保存の再設計。CIの並行実行・キャッシュ・結果欠損・取消・権限・初回実行はFR3〜FR5/NFR3〜NFR4で扱う。
