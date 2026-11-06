# U1 ビルド・試験と統合の環境設計

入力は`../nfr-design/`の6文書、`../functional-design/functional-spec.md`、`../../../inception/domain-design/components.md`、`../../../inception/contract-design/contract-summary.md`、`../../../inception/delivery-planning/bolt-plan.md`。CIは変更時の自動ビルド/試験で、配布/公開基盤は今回含まない。

## 実行設定
| 項目 | 設定 |
|---|---|
| リポジトリ | yokochie/hitotsuzuri、publicをAPI確認済み |
| runner | 標準xcode-27（arm64/macOS27）。xlarge等の大型runnerなし |
| 起動 | pull_request、codex/作業ブランチpush、workflow_dispatch。pull_request_targetなし |
| 権限 | contents: read。checkoutの認証情報永続化なし、秘密情報注入なし |
| 同時実行 | 同workflow/refの古い実行を取消し、異なる必要試験を黙って成功へ変えない |
| 上限 | job timeout 30分を初期設定。timeout/取消/skipを成功としない |
| コマンド | 本人承認済みbash scripts/verify-native.sh。Phase2試験を既存対象へ組込むか、同スクリプトの対象追加をコード計画で明示 |
| 署名 | 既存ad-hoc/ManualとCODE_SIGN_IDENTITY=-。証明書/公証不要 |
| 保存 | 追加キャッシュ/成果物アップロードなし、標準実行ログで結果確認。ローカルxcresultは検証記録へ要約 |
| 依存 | checkout等を利用する場合は公式actionの確認済みcommit SHAを実装時に固定。第三者action/有料追加なし |

## 実行順序と合否
1. 対象コミットを取得し、sw_vers/xcodebuild -version/選択Developer Directoryを表示。Xcode27/必要SDKの存在を確認する。CI環境が本人環境27.2と完全同一とは仮定しない。
2. clean checkoutでプロジェクト参照と共有schemeを検査する。新規別formatter/linterを勝手に導入せず、ビルド/コンパイラ診断と設定/権限の検査を使う。
3. 承認済みコマンドで、既存回帰＋Phase2単体/統合/UI経路を実行。CIのUIは合成選択/写真/保存先のfixtureを注入し、本人ライブラリやiCloud/写真権限ダイアログに依存させない。実アダプタへの変換/ファイルI/Oも合成ファイルで通し、すべてFakeの試験だけを統合実証としない。
4. 製品全体の行カバレッジ80%以上を既存check-coverageで判定する。新コードを計測対象から除外して達成させない。試験失敗/未実行/測定不能は失敗にする。
5. commit SHAと実行URL・結果を記録。同じ変更の成功がなければ統合しない。初回CI設定はU1コード差分に含め、最初のU1統合前に実行する。後段CI Pipelineでも構成全体を確認する。
6. 本人Macで実写真/編集/回転/色/位置情報除去/オフライン/元写真非変更/Sandbox/再起動を確認し、日本語記録へ残す。U1は1枚検証、4枚セット/noteはU3。自動fixture成功を本人確認へ広げない。

| Gate | 必須証拠 | 失敗時 |
|---|---|---|
| コード変更前 | 既存baseline、本人承認コード計画、TDD方針 | 新規回帰と既知問題を分離 |
| ローカル検証 | 指定試験/全製品80%以上、正常/失敗/取消証拠 | 修正し再検証。未達は未達 |
| 統合前CI | 同commitの自動実行成功 | runner/SDK/GUI差を調べ、試験や対象OSを黙って下げない |
| 最小実動作確認 | U1本人デモと検証コマンド | 未確認を承認と推定しない |
| main統合 | 必須証拠と本人判断 | CI未達ならブランチに保持 |

## 起動・戻し方・費用
自動デプロイ/ストア配布/blue-green等は対象外。Xcodeから本人がローカル起動する。旧版を確認するときは別作業領域/既知のアプリ成果物を使い、現在の下書き/選択/出力を保護する。mainや本人の保存データを破壊的に戻さない。試験用rootは本人データと分離し、終了後に当該fixtureだけを片付ける。

標準runnerは公開リポジトリで実行無料。[GitHub公式](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)、[xcode-27のmacOS27対応](https://github.blog/changelog/2026-10-15-xcode-27-runner-image-generally-available/)を2026-11-04確認。大型runner・有料追加・キャッシュ/成果物アップロードを使わない。公開設定が変われば無料条件を再確認し、自動で課金構成へ切替えない。AWS等の新規費用0、本人Macの既存資源を使用する。

この段階ではCI設定の設計だけで、workflowの実行成功はまだない。GitHub Actions設定/実行が拒否された場合はその条件を明示し、手動実行をCI成功と記録しない。GitHubのmerge protectionを変更済みとは仮定せず、必要な設定変更は具体的なルール案を作ってから本人の権限と意図を確認する。
