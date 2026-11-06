# Construction Phase Verification

## 判定
**品質条件の全面通過ではない。既知の未確認を保持して計画内作業を終了した。**

本人a861c7f7がBuild and TestのAccept failureを選択した。自動機能検証は成功しているが、実写真・実Sandbox/Finder/note、最小高さ等の一部実測と初期TDD証拠は未確認のままである。目標を下げたり、未確認を合格へ書き換えたりしていない。

実行計画のOperationは全てSKIPで、配布・デプロイ・Operationへの移行は行っていない。ワークフローのCompleted/Construction Verifiedという状態値は計画の記録・了承済み終了を表し、全AC/NFRや本人確認の合格を意味しない。未確認は以下の記録を正とする。engine所有の状態・監査行を手で変更していない。

## ソースとCI
- 検証済み製品ソース：4a3b71d1e15795fedcba4e8a808addfff3ef2308、codex/phase2-u2-draft-experience。
- [CI41994393925 attempt2](https://github.com/yokochie/hitotsuzuri/actions/runs/41994393925/attempts/2)：runner28、Core前提454、別smoke2、主bundle517が全成功/0skip。
- 全製品加重行coverage：5227/5739=91.08%、同一主bundle、既存80%/checker/計測範囲を保持。
- 本人0c6f9332が承認した完了確認は、HEAD一致/指定範囲のgit diffなし/CI終了成功を一回確認しexit0。ローカルUIは再実行していない。
- CIは既存verify.ymlでCore→全機能/80%を実行できるため、ci-pipelineは追加作成・大きな変更不要として条件に従いスキップした。新しい設定・有料runner・権限変更・追加runはない。
- U3の独立確認では片付け所有保護・中断回復・固定コピーの前回指摘の解消と新規所見なしを確認。試験成功を実写真/実OS手動受渡しへ広げない。

## Unit別の追跡表
| Unit | Upstream IDs | Coverage rows | GAP IDs | OK参照先欠落 |
|---|---:|---:|---|---:|
| u1-article-foundation | 59 | 59 | NFR2.4, NFR2.6, NFR2.7, NFR3.2, NFR3.3, NFR3.4, NFR3.5, NFR4.1, NFR4.2, NFR5.1, NFR6.3, NFR7.1 | 0 |
| u2-draft-experience | 58 | 58 | なし | 0 |
| u3-article-export | 46 | 46 | AC1.8.4, NFR7.30, BR3.12 | 0 |

各表の出典は各Unit/code-generation/traceability.json。U1の過去のCI/性能未確認のGAPは元文書で保持し、現候補のCI/後続Mac測定はBuild and Testの現在証拠として分ける。元表を通過させるための書換えは行わない。U3のAC1.8.4/NFR7.30/BR3.12は本人の実写真・保存先・Finder・noteに関する未確認。

## Cross-Unit Gate
sensor-traceability --stage build-and-testの実出力はpass=false、62行。未対応：FR12, FR15, FR18, NFR2, NFR3, NFR4, NFR5, NFR6, NFR7, AC1.8.4。

FR12/FR15/FR18はAC1.8.4の未確認を含む。NFR2〜7には元U1追跡表のGAPと本人確認が残る。要件と設計・コード・試験の追跡表が存在することと、全条件の実証済みを区別する。詳細はconstruction/build-and-test/cross-unit-traceability.md。

## 目標と未確認の所在
construction/build-and-test/build-and-test-summary.mdに詳細NFR65＋契約9＋全製品coverage＋cross-unitの76項目を記録。Met53、Not Met1、Unverified19、後続CI義務N/A3。全目標に最終状態がありPendingはない。CI義務は当該時点の後続Stage所有としてN/Aで、実行そのものは上記runで成功済み。CIを追加構築しなかったことを失敗や未実行と扱わない。

## 再開・本人確認
construction/build-and-test/performance-test-instructions.mdと各Unit/code-generation/user-verification.mdへ実機で確認すべき項目をまとめた。本人の実写真、元ライブラリの前後比較/オフライン、回転/色/位置情報、実保存先とFinder、note本文貼付け/四枚順、最小640×560pt、一部実時間/実中断の結果を一度の機会に記録する。過去のTDDのアサーションRedを実装後に創作しない。全体の正常ソース/閾値/試験を変更する場合だけ該当候補のCIを取り直す。

## 記録コミットと今後のコマンド
今回のフェーズ終了コミットは検証記録だけを追加/更新し、製品ソースを変えない。成功済みCIの対象SHAは上記4a3b71dのままである。verification-command.txtのHEAD固定1行は記録コミット前のチェックポイントで実行済みの証拠であり、新しい記録のみのHEADへ無断で書換えたり、そのSHA差だけで全UIを再実行したりしない。mainへの統合/配布は未実施。
