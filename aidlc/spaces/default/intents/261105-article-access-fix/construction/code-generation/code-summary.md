# 記事アクセスエラーの修正結果

## Changes
- `HitotsuzuriCore/ArticleFileSystem.swift`: 全祖先を読取openする処理を、対象パスの直接openへ変更した。`O_NOFOLLOW_ANY`で全パス成分のsymlinkを拒否する。NULを含むパス・非fileURL・非絶対パスを入口で拒否し、ENOENTかつcreate指定時だけ不足部分を親fd相対で作成する。既存の子も先にopenし、必要な場合だけmkdiratする。
- `HitotsuzuriU1Tests/ArticleDirectoryAccessTests.swift`: 検索のみ可能な祖先下の既存記事・新規記事、本当の読取拒否、書込拒否後の保存再試行、中間/末端symlink拒否の6件を追加した。OS呼出しでfixtureの権限条件を先に確認し、失敗時も権限復元とUUID領域の掃除を行う。
- `Hitotsuzuri/DebugFixture.swift`: DEBUG限定のApplication Support保存モードを追加した。通常と同じ保存先解決APIの配下で専用UUID rootだけを使用し、token・device・inodeの所有照合を行う。未知の保存モードや解決失敗を他の保存場所へ置き換えない。
- `HitotsuzuriUITests/FixtureLaunch.swift`: 保存モードを起動・再起動・teardownへ保持し、app自身による当該rootのcleanupと成功表示を確認する。
- `HitotsuzuriUITests/ArticleSandboxStorageUITests.swift`: Sandbox有効のappで隔離Application Supportを使い、記事開始→タイトル/本文保存→再起動→同じ候補識別子と本文の再開を1件で確認する試験を追加した。
- `ArticlePersistence.swift`は変更不要。保存先を開く段階の実際の権限拒否は既に伝播している。保存形式、通常の写真選択・記事UI、entitlements、Xcode project、scheme、runner、CI workflowは変更していない。

## Implementation Decisions
パス全体をカーネルのnofollow検査に委ね、その後の処理は既存の親fd相対操作を継続する。作成可否の判断はENOENTに限定し、権限拒否・symlink・不正参照を新規作成や空一覧へ変換しない。write/sync/lock/rename、出力所有照合、排他、競合、結果不明時の照合は変更していない。

通常データの移行・削除、Sandbox解除、追加権限、OS設定変更は行わない。通常Application Supportを使う試験も合成データと専用UUID領域だけに閉じる。本人の実機で失敗したsyscallは未観測であり、コード上の原因再現と本人環境の直接原因の確定を区別する。

## Validation
詳細は同ディレクトリの`ci-evidence.md`。

- Baseline: 対象8229a1dのCIでsmoke2件・主bundle517件成功、製品行coverage91.08%。記録コミット8727406まで製品同一を確認した。
- Red: 製品未変更の2241780、CI42021621097のCoreで新規6件中2件が期待したpermissionDeniedにより失敗し、残り4件と既存Core454件は成功した。コンパイル失敗やfixture条件不成立ではない。
- Green: 修正88978d6の[CI42022838099](https://github.com/yokochie/hitotsuzuri/actions/runs/42022838099)が成功。Core先行460件、smoke2件、主bundle524件（Core460＋UI64）が全成功・0skip。製品全体5284/5798=91.13%。新しいSandbox UIも27.277秒で成功し、保存・同記事再開とapp内cleanupを確認した。
- ローカルではPython選択契約28件（4.318秒、1回）と静的クラス検出・差分整形を確認した。native/build/UI/性能をローカルで実行していない。
- 追加UI本文はASCIIにしてIME入力の別問題を混ぜず、Unicode byte保持はCore回帰で確認する。

## Manual Verification — 本人のMacでまとめて確認
**状態: 未確認。CIの成功で補完しない。** 次の一連の確認を修正ビルドで一度に行う。

1. Xcodeで`Hitotsuzuri.xcodeproj`を開き、scheme「Hitotsuzuri」、実行先「My Mac」を選ぶ。古いappを停止し、通常起動で実行する。試験用の`--article-test-fixture`/`--ui-test-fixture`等を起動引数へ追加しない。
2. 通常の写真選択を使い、確定した写真4枚から「選択した写真の記事を開く」を実行する。既存記事が対応する場合はそれを開き、タイトル・本文・写真順序が保持されていることを確認する。
3. 必要な文章を入力し「保存」を実行する。保存成功を確認してappを終了し、通常起動で再び同じ記事を開く。保存した文章と写真順序が保持されていることを確認する。
4. エラーが残る場合は、その操作と表示文言をこのチャットへ伝える。保存データの削除・再インストール・権限リセットで回避せず、データを保持して次の切り分けを行う。

この確認のために写真ライブラリ自体を書き換える操作は不要。以前のPhase2で残した実写真編集・Finder/note・性能等の未確認事項を、本修正の成功で解消済みにはしない。

## Cleanup and Rollback
Coreは合成UUID領域の権限を復元し、そのrootだけを削除する。新しいUIはapp内のowner receiptを照合し、当該rootだけを削除して不在を確認する。CI bundleはCI側の証拠であり、ローカルに存在すると記録しない。Python選択契約試験が作成した空の`.build`（0B）は内容がないことを確認してrmdirで削除した。過去のbuild/xcresultは復元しておらず、default.profrawも不在。本人のデータを掃除していない。

保存形式は変更していない。戻す場合は、本人の保存作業を済ませappを終了してから、今回の製品修正コミットをrevertする手順を使う。未保存変更のreset/checkout/cleanや保存データ削除は行わない。既知のアクセスエラーへ戻る可能性を本人へ説明してから実行する。

## Deviations and Remaining Work
ArticlePersistenceは任意変更候補だったが変更不要と判断した。計画したCore6件＋Sandbox UI1件を維持し、テスト対象や80%閾値は緩めていない。全追加試験と既存機能試験はこの段階のCIで実行済み。Refactorは既存fd相対I/Oを保つ読みやすさの確認で完了し、成功後の無関係な製品変更は加えていない。6要件の実装/試験への追跡検査に欠落なし。本人実機確認は上記のとおり未確認である。
