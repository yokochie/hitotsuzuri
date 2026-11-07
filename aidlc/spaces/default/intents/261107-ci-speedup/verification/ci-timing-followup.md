# CI高速化の追加計測手順

初回の必須CIは全件合格。変更後標本は1件で、30%短縮の判定は保留中。[初回の実行記録](../operation/deployment-execution/deployment-log.md)

1. 変更前は既存の成功PR記録から、PR更新時刻、該当するhead、初回attempt、必須ジョブの最終完了時刻を照合する。変更前のCIは再実行しない。
2. 変更後は同等条件の実際のPR更新で、初回attemptの成功を追加で記録する。同じ更新の再実行、失敗、取消は別記する。現時点で最低2件の追加成功記録が必要。
3. 標本ごとにPR、head、run URL、OSとXcode、runner条件、試験集合、キャッシュ条件、開始前待機、必須ジョブ完了を記録する。不明項目は不明とし、比較不能なら判定保留。
4. 両群3件以上が揃ったら「PR更新から全必須チェック完了」の中央値を比較する。短縮率は（変更前中央値−変更後中央値）÷変更前中央値。30%以上なら目標達成。未達なら機能UIジョブの試験本体・準備・回収の内訳から次の改善箇所を選ぶ。

状態とログは [PR #5](https://github.com/yokochie/hitotsuzuri/pull/5) の Checks、または [Actionsの初回実行](https://github.com/yokochie/hitotsuzuri/actions/runs/42330520754) から確認できる。
