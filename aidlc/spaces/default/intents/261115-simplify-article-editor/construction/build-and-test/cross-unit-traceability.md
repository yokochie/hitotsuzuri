# 要件と検証の対応

判定は合格。修正後の全機能試験で記事画面・出力・既存データの要件を確認した。統合前CIは今後の統合作業で確認する。

| ID | 所管 | 実装・試験 | 確認状況 |
| --- | --- | --- | --- |
| FR1 | Code Generation | `Hitotsuzuri/ArticleView.swift` | 新規・既存下書きのUIで入力欄の非表示を確認。 |
| FR2 | Code Generation | `Hitotsuzuri/ArticleMetadataFields.swift` | 日付候補の表示、確定、解除、再起動後の保持を確認。 |
| FR3 | Code Generation | `HitotsuzuriCore/ArticleProjection.swift` | プレビューのダミー文、本文コピー、Markdown、完成出力を確認。 |
| FR4 | Code Generation | `HitotsuzuriU3Tests/ArticleExportIntegrationTests.swift` | 旧下書き・中断出力の復旧試験成功。 |
| NFR1 | Build and Test | `scripts/verify-native.sh --functional` | 製品全体の行カバレッジ91.96%。統合前のGitHub Actionsは未実行。 |

単一の変更として検証し、Unitの分割はない。
