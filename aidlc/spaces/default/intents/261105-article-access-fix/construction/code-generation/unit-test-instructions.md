# 記事アクセス修正の試験手順

## 対象・前提
今回の単一修正を対象とする。要件は`inception/requirements-analysis/requirements.md`、実装順は同ディレクトリの`code-generation-plan.md`。Xcode 27系、macOS 27系、既存XCTest/XCUITestとPython選択契約試験を使用する。新規依存・手動OS設定は不要。

CI優先で実施する。以下の部分コマンドは再現用の正確な選択を示すもので、同じ試験が既存CIで実行されていればローカルで重ねて実行しない。ローカルUIの実行許可は本書から推定しない。

## Runner Configuration
- `Hitotsuzuri.xcodeproj/project.pbxproj`のfilesystem synchronized groupsが新しい試験ファイルを検出する。共有scheme、ターゲット、entitlements、coverageの設定は変更しない。
- `scripts/native-test-runner.py`は既存4ターゲットのXCTestCase/ArticleDraftUITestCaseクラスを検出する。新しいCore/UIクラスが`native_classes()`に現れることを確認し、既存`python3 scripts/test-native-runner.py`の選択契約を実装Step 1で確認する。
- 実装前baselineはCI [42016213433](https://github.com/yokochie/hitotsuzuri/actions/runs/42016213433)。対象8229a1d、smoke2件・全機能主bundle517件成功、製品全体5227/5739=91.08%。次の記録コミット8727406は製品同一であることを差分確認して使用する。

## Targeted Core Regression
追加ファイル: `HitotsuzuriU1Tests/ArticleDirectoryAccessTests.swift`。

| 試験 | 条件と期待 | 要件 |
|---|---|---|
| testExistingArticleUnderSearchOnlyAncestorCanOpenSaveAndReopen | 合成祖先を0111へ変更。末端は0700で、事前保存した記事のopen・本文保存・再openが成功し、識別子・順序・文章を保持 | FR1 |
| testMissingArticleDirectoriesUnderSearchOnlyAncestorCanBeCreatedAndListed | 許可済み末端の下位記事ディレクトリが未作成。create/list/reopenが成立。祖先自体は書込対象にしない | FR1 |
| testReadDeniedIsNotAnEmptyDraftList | 合成末端を0000とし一覧がpermissionDenied。失敗を空一覧へ変換しない。復元後に同じ保存記事を列挙できる | FR2 |
| testWriteDenialPreservesArticleAndRetrySucceedsAfterRestoration | 記事projectを0500として保存拒否とcurrent bytesの保持を確認。0700へ復元して同じoperationを再試行し重複なく保存できる | FR2 |
| testIntermediateSymlinkIsRejectedWithoutChangingTarget | 中間成分をsymlinkへ置換した合成パスを拒否。リンク先のsentinel/記事に変更なし | NFR1 |
| testLeafSymlinkIsRejectedWithoutChangingTarget | 末端symlinkをcreate false/trueで拒否し、リンク先を作成・削除・上書きしない | NFR1 |

正確な部分実行コマンド:

```bash
bash scripts/verify-native.sh ArticleDirectoryAccessTests
```

Redは製品helperを未変更のまま試験だけをcommit/pushし、既存CIのCoreで先頭2件が意図したpermissionDeniedにより失敗することを確認する。CIは既存の全Coreを選ぶが、その中の今回クラス・メソッドの結果を特定してRedを記録する。コンパイル失敗、root権限で拒否を再現できない場合、chmod/setup失敗、試験未実行はRed成立としない。skipや成功扱いで通さず、原因を調べる。

Greenは最小修正後のCIで6件全成功を確認する。Red/GreenそれぞれSHA・run/job・メソッド・assertion結果・件数を記録する。データアクセス層を変更する前にRed証拠を得る。

## Sandbox Application Support Regression
追加ファイル: `HitotsuzuriUITests/ArticleSandboxStorageUITests.swift`、1件 `testArticleCanStartSaveAndReopenInApplicationSupport`。

- 実行するappは通常のSandbox設定とentitlementsのまま。DEBUGの合成写真・選択・画像adapterを使用する。
- 保存先解決は通常と同じApplication Support APIを使い、その配下の専用接頭辞＋検証済みUUIDのrootだけを使う。通常のHitotsuzuri選択・記事ファイルを読み書きしない。
- 記事を開き本文を変更して保存する。プロセスを終了・同じUUIDで再起動し、記事の本文と対応する選択が再開されることを確認する。
- 保存場所の指定を再起動・teardownでも保持する。最後はapp自身が当該UUID rootだけを削除し、cleanup成功の画面を確認する。任意パスを環境変数で渡す方式にしない。
- 一般クリップボード、実Photos、OS設定、外部サービスは使用しない。既存fixtureが使う標準のapp起動分離だけを継続する。

正確な部分実行コマンド:

```bash
bash scripts/verify-native.sh ArticleSandboxStorageUITests
```

このクラスも既存CIの全機能選択へ自動で含まれる。CIの成功を本人環境の確認済みとは扱わない。fixture接続だけで記事・画面の業務ロジックは変えないため、独立したfrontend機能のTDDサイクルはN/A。

## Existing Safety Regression
FR3/NFR1を既存の試験で検証する。再現用の限定コマンドは以下。全機能CIで同じクラスが実行済みなら追加で実行しない。

```bash
bash scripts/verify-native.sh ArticleRecoveryTests ArticlePersistenceTests ArticleProbeTests ArticleExportWriterTests ArticleExportJournalTests ArticleExportIntegrationTests ArticleExportOSActionTests
```

symlink・差替え・排他・競合・結果不明・取消・他者ファイル保護を維持し、失敗は修正前から存在するものか新規回帰かを区別する。新しい要件へ対応する試験は、Core6件、Sandbox UI1件、既存の共通利用者保護試験、coverage/設定差分と本人確認手順へ計画内で対応付けている。

## Coverage and CI Evidence
部分試験は全製品coverageを判定しない。閾値を緩めず、Build and Testで既存CIの全機能主bundleを使って全製品の行coverage80%以上を判断する。CIはCore成功依存→smoke→全機能の現在の選択契約を継続する。全対象0skipを確認する。性能の一式測定は今回の変更で再実行しない。

CIの通常経路はRed用のCore失敗確認1回、修正後の全機能Green1回を基本とする。失敗・実装変更・未解決の懸念がある場合だけ必要な再実行を行う。push/PR重複runはpush側だけcancelしPR側を確認する。手動rerunによる不要な二重実行はしない。

## Test Data and Cleanup
Core fixtureはプロジェクト内`.build/article-tests/`の生成UUIDだけに作成し、chmodをdefer/teardownで必ず0700へ復元して当該rootを掃除する。失敗時にも権限が残らないようにする。permission fixtureの対象は毎回生成した合成ファイルだけ。

UI fixtureは上記のapp内UUID領域を所有確認して掃除する。通常保存先・他のUUID・他者ファイルを掃除しない。新しいテストや計測のために削除済みの過去xcresultを再作成したとは記録しない。CIの結果bundleはCI上の証拠であり、ローカルに存在するとは主張しない。

本人による最終確認は、修正ビルドで「確定写真→記事を開く→短い文章を保存→終了・再起動→同じ記事の再開」を一度に確認する手順としてcode-summaryへ記す。ここは未確認のまま自動成功で埋めない。
