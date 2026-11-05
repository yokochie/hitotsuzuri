# U3 品質設計の確認事項

## 引継ぎ
本人の追加判断は不要。既存のC2/C3、Mac性能/機能CI分離、都度選択の保存先、記事正本非変更を維持する。ジョブ専用記録、親を開いた相対操作、一式の非置換確定と確定後同期失敗の照合を具体化する。

## 根拠と限界
現行ArticleFileSystem.swiftは親descriptor、nofollow、排他、ファイル同期と非置換renameを持つ。ArticleProbeDelivery.swiftは1枚検証専用であり四枚の成功経路へ偽装しない。Apple資料で排他的renameのボリューム能力とsecurity-scope寿命を確認した。fsyncだけで電源断耐久性を絶対保証せず、物理成立性と失敗注入は実装計画へ残す。

## Assumptions & Open Questions
None.
