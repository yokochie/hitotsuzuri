# 統合対象の検証

[Build and Test結果](../../construction/build-and-test/test-results.md)の初回CI成功後、先行PR #4を含むmainを取り込んだhead162f2bcdでも[CI42321598795](https://github.com/yokochie/hitotsuzuri/actions/runs/42321598795)が全成功した。

native-core job128247200458とnative job128247663346の両方がcompleted/success。既存smoke、Core、UI機能回帰、製品全体カバレッジ検査を通過。マージ対象headを指定して統合し、未検証のheadへすり替わらないことを確認した。

今回の成果物はCI設定と契約試験の更新であり、アプリの配布・実写真での操作確認を実施したという意味ではない。
