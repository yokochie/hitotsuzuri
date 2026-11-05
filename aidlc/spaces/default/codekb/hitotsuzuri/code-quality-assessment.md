# コード品質と今回の不具合

## 静的評価
| 項目 | 評価 | 根拠 |
|---|---|---|
| 命名・境界 | good | 選択・記事・画像・出力に型とprotocolを設ける |
| 関数・ファイル規模 | fair | Coordinatorと一部UIに複数のOS/DEBUG責務が集中する |
| I/O保護 | good | nofollow、fd相対操作、digest、排他、unknown/corrupt保護、原子的公開 |
| エラー案内 | fair | typed failureはあるがpermissionDeniedが写真と保存先共通で、失敗段階が不明 |
| 試験の存在 | good | model・保存・回復・出力・UIとrunner契約の試験あり |
| 実環境の再現範囲 | fair | 通常保存先と合成一時rootの差を検証していない |
| 重複・dead code | fair | 旧Phase1とPhase2の試験/入口が併存。未使用コードの完全な到達性検査は未実施 |

## 記事読込の原因候補と確度
報告画像の文言は `ArticleFailure.permissionDenied.message` と一致する。 `ArticlePresentation.swift:86–106` は確定選択を読んだ後、記事一覧を照会してから記事を準備する。 `ArticlePersistence.swift:32–35` の一覧処理はまず `ArticleDirectory.open(directory, create:false)` を呼ぶ。通常保存先は `HitotsuzuriApp.swift:21` と `ArticleAppCoordinator.init` のArticles子directoryである。

**コードから確認できた事実**: `ArticleFileSystem.swift:11–26` は絶対パスを `/` から全祖先について読取openする。create指定時には存在確認の結果にかかわらず各祖先にmkdiratを発行する。EACCES/EPERMは115行でpermissionDeniedへ変換される。この経路の失敗は写真取得を開始する前に記事表示を止める。よって画像の案内だけから写真認可不足と断定できない。

**強い仮説**: Sandboxからアクセス可能な保存先までのパスで、許可外の祖先をディレクトリ読取としてopenすること、または既存祖先へのmkdir試行が拒否されている。末端へ到達する検索権限と、祖先ディレクトリを読取・作成する権限は別の条件である。

**未確認**: 本人の失敗syscall・errno・保存先URL、Sandboxの実際の拒否箇所は未取得。通常データやOS設定を開いておらず、この仮説を実機再現・修正完了と扱わない。

## 既存の回帰境界
- `ArticleRecoveryTests.testRealWritePermissionLossKeepsOldArticle` は合成directoryのPOSIX mode変更で拒否を確認する。書込拒否の保護であり、アクセス可能な末端に対して祖先だけ読取不能の場合の成功を保証しない。
- `testSymlinkRootIsRejected` は保存rootのsymlink拒否を確認する。出力Writerの実体identity・差替え・所有/既知ファイルdigestによる削除保護も維持対象。
- CoreのArticleFixturesはrepo内 `.build/article-tests` を使用する。通常app containerの祖先権限とは異なる。
- `DebugFixture.ownedRoot` はOSのtemporaryDirectoryを解決した合成rootを使用する。UIの保存先もfixture内Outputであり、通常 `applicationDirectory()` の経路・実際のパネルgrantの再現ではない。UI成功でも今回の通常保存先アクセスの保証にはならない。

## 後続の要件・回帰設計への引継ぎ
1. 許可された保存先に対して、祖先の列挙/作成権限を要求せず記事一覧・新規・保存・再開が成立する条件を用意する。先に意図した失敗を示す回帰を計画する。
2. 合成root配下に検索可能だが読取不能の祖先を設けるCore fixtureは、OS設定や実写真を使わず原因候補を狭める案となる。ただしPOSIX fixtureだけではApp Sandbox policyと等価ではない。
3. 必要ならCIのapp内で合成データを通常Application Support経路へ隔離生成し、記事読込と再開を検証する案を検討する。通常データと混ざる設計にしない。実行は今行わない。
4. 入口修正はnofollow・symlink中間成分/末端拒否と差替え防御を保持し、権限拒否を空一覧や新規として握り潰さない。無関係な保存形式変更・権限拡張・Sandbox無効化は必要ない。
5. ArticleDirectoryの全利用者（保存/両出力/両journal/Finder前検査）を影響範囲に含める。自動試験はCI優先とし、ローカルUIの反復を避ける本人方針を引き継ぐ。

## 検証状況
本調査は静的読取のみ。build・試験・実写真参照・OS設定変更を実行していない。coverage設定の存在と80%floorは確認したが、新しい実行成功率/coverage数値はない。従来のCI実績は別の検証記録に属し、今回の原因再現・修正証拠にはしない。
