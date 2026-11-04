# U1 記事基礎の試験手順

## フレームワークと準備
既存XCTest/Xcode共有schemeを使用。本人環境macOS27.2/Xcode27.2、CIは標準xcode-27。コード計画Step2で新規試験を既存HitotsuzuriU1TestsとHitotsuzuriUITestsへ登録し、専用スクリプトを準備してから最初のRedを行う。0件試験を成功証拠にしない。

runner準備の確認だけは、既存の正確な1クラスを指定する。

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriU1Tests/U1IntegrationTests -derivedDataPath .build/ArticleRunner CODE_SIGN_IDENTITY=- test
```

## Unit専用コマンド
Step2で準備するスクリプトを使う。全体suiteは含めない。

```bash
bash scripts/verify-article-foundation.sh
```

スクリプトは厳密な以下のクラスだけを-only-testingで指定し、XCTest実行失敗と未実行を失敗で返す。テスト結果bundleは毎回別名にする。実装時の層別Red/Greenはこの集合の該当クラスfilterへさらに狭めて記録できる。

- HitotsuzuriU1Tests/ArticleModelTests
- HitotsuzuriU1Tests/ArticlePersistenceTests
- HitotsuzuriU1Tests/ArticleRecoveryTests
- HitotsuzuriU1Tests/ArticleWorkspaceTests
- HitotsuzuriU1Tests/ArticleSessionTests
- HitotsuzuriU1Tests/ArticleImageTests
- HitotsuzuriU1Tests/ArticleResourceTests
- HitotsuzuriU1Tests/ArticleProbeTests
- HitotsuzuriU1Tests/ArticleIntegrationTests
- HitotsuzuriUITests/ArticleFoundationUITests

各テスト可能層で先に失敗出力、最小実装後成功、整理後成功を記録。5責務各5〜8件を基準に、必要境界は追加する。8件以上の実ファイル/実変換統合と6件以上UIを含める。第三者runner/有料追加なし。

## カバレッジ
製品全体の重み付き行カバレッジ80%以上は全suiteを組み合わせたBuild and Test/完了検証で判定する。このUnit専用runで未対象の既存コードまで80%を要求しない。既存check-coverage閾値や計測対象を変更しない。専用runには全体coverage検査を連結しない。全体の承認済み検証コマンドは別のintent記録で管理され、このUnit手順の実行コマンドへ混ぜない。

## データと境界
テスト用UUID/日本語/絵文字/改行、旧選択版1、破損/未知版/リンク/外部変更、合成JPEG/HEIF可能fixture、メタデータ、操作履歴を専用一時rootへ生成する。本人Application Supportや写真ライブラリへ触れない。PhotoKitは読取driverのFakeでnetwork=falseと変更非呼出しを検査し、Image I/Oと保存/出力の統合は実合成ファイルで確認する。

Clock/ファイル同期/確定点/容量/権限/遅延応答/片付けを注入し、operationID再試行の順序、絶対期限同時/逆順配送、取消後実処理残存とゲート、grant選択前なしを試験する。通常ログに特徴ある私的テスト値が出ないことを確認。

性能条件は100記事/対象1000操作/タイトル200文字/各本文1万文字、30試行以上とcold10回別集計。画像1件30秒・書込込み40秒・直接256MiB/プロセス増分512MiB・取消受理0.5秒/論理終端2秒を測定し、測定不能/未達を明記する。実写真の編集/回転/色/位置情報除去、元ライブラリ非変更、Sandbox実操作は本人確認を別に必要とする。VoiceOver追加検証なし。
