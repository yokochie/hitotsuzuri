# CI高速化の実装

## 実行構成

GitHub Actionsの `.github/workflows/verify.yml` から既存のxcode-27で実行する。PR・mainのチェックは `native-core` → `native` の順。Coreで試験選択契約を検証し、後段でsmoke・機能回帰と全製品カバレッジを判定する。権限はcontents読取、checkout認証情報は保存せず、Actionsの参照はcommit固定。CIの版管理は現行YAMLと試験コードで行う。

## 変更

- `HitotsuzuriUITests/FixtureLaunch.swift` は回収成功の表示がすでにあれば即座に確認し、未表示なら既存の10秒の待機を使う。
- `HitotsuzuriUITests/ArticleDraftUITestCase.swift` はシートとダイアログを一つの待機条件で確認する。表示済みなら即座に返し、未表示なら最大6秒。表示されない場合はテストを失敗させる。
- 過去run 42321598795で回収確認は81回。起動中の回収も検討したが、準備・保存・出力の非同期処理が終了したことを全ケースで保証できる共通の境界がない。ケース所有のrootをアプリ終了後に回収する既存の方式を維持し、確認待ちを短縮した。

## 実行・復旧

同一refの古いrunは既存の設定で取り消す。ジョブ上限はCore 15分、機能45分。取消・時間切れ後に当該runの試験プロセスが残っていると確認した場合は、次のGUI試験前にrunner側で終了を確認する。別runのプロセスを一括停止しない。異常が出た場合は今回の2ファイルの差分を戻し、必須チェックで再確認する。

## 参照

- `../nfr-design/performance-design.md`
- `../nfr-design/security-design.md`
- `../nfr-design/reliability-design.md`
- `../nfr-design/observability-design.md`

## ローカル検証

試験選択契約28件が合格。Xcodeのbuild-for-testingは終了コード0で、変更後のUIテストバンドルとxctestrunを生成した。変更前のsmokeはアプリを前面化できず、ローカルでのUI完走は確認できていない。GitHub Actions上の品質判定と短縮率は未計測。
