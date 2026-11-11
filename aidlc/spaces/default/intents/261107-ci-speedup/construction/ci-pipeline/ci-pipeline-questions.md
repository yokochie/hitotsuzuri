# CIの実装方針

## Consolidated Summary Confirmation

- GitHub Actionsの既存2ジョブを使い、Coreが成功した後に必須smoke・機能回帰・全製品80%以上のカバレッジを検証する。
- 過去ログで試験データ回収の確認待ちが81回あった。毎回のアプリ再起動を伴うため、まず試験用データの回収を同じアプリ起動中に行えるか、小さな変更で検証する。ケースごとの領域隔離、回収成功の確認、既存の検証内容を保つ。成立性を確認してから対象を広げる。
- 性能比較ではPR更新ごとの初回実行を1件とし、同じ更新の再実行は別記する。変更前は過去データ、変更後は同等条件の3件以上を使う。判定基準はPR更新から全必須チェック完了までの中央値30%以上短縮。
- 取消・時間切れ時は中断した実行の結果を無効とし、当該実行の試験プロセスが終了してから次のGUI試験を始める。実際に終了を確認できる範囲を記録する。

Does this all look correct before I generate the artifact?

- Looks correct
- Request changes

[Answer]: Looks correct
