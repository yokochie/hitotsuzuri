# Constructionの検証

- このinfra計画ではUnits、Code Generation、Build and Testを実施しないため、Unit間の追跡表は対象外。既存のCIコマンドと試験選択を構成ファイル・スクリプトで照合した。
- 試験選択契約28件が成功。変更後のUIテストはbuild-for-testingで生成できた。
- 変更前のローカルsmokeはアプリ前面化で失敗。変更後の必須CI・カバレッジ・性能比較はGitHub Actionsで確認が必要。
- 構成とローカルで確認できた範囲は `../construction/ci-pipeline/ci-config.md`、残りの合格条件は `../construction/ci-pipeline/quality-gates.md`。
