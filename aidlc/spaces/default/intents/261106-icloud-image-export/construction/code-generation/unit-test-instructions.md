# アプリ内画像取得の試験手順

## 前提

XCTest/XCUITest、既存Hitotsuzuri project/共有schemeとscripts/native-test-runner.pyを使用する。追加依存不要。実行は既存GitHub Actionsのxcode-27 runnerを優先し、同じ目的のローカルbuild/native/UI/性能試験は重複実行しない。新classはsynchronized groupと既存runnerの動的発見で認識させる。

## 対象指定コマンド

CoreのRed/Green（新規2classを作成して実行）:

```bash
bash scripts/verify-native.sh ArticleCloudImageTests ArticleCloudExportTests
```

新しい画面接続のRed/Green:

```bash
bash scripts/verify-native.sh ArticleCloudExportUITests
```

表示復帰との接続を確認する対象指定:

```bash
bash scripts/verify-native.sh ArticleCloudExportUITests ArticlePhotoRestorationUITests
```

これらは今回の変更を絞って検証するコマンドで、最終通常全機能CIが同じ試験を成功させた後に全て再実行する指示ではない。新classが未発見またはskipなら合格にしない。

## TDDと閾値

計画T1–T12/U1–U3を先に記述し、各層の通常動作を変える前に意図した失敗をCIで確認する。compile・fixture・AX観測失敗はRedと区別する。最小変更でGreen後、責務を整理して成功を維持する。Coreが既にGreenの画面ケースを作る際も、未実装の実画面接続のRedを確認する。

全製品の80%行カバレッジは通常の全機能CIで判定する。部分実行のcoverageを代用せず、既存の閾値・除外・試験選択を弱めない。全体機能535件/smoke2/91.49%の既存CI42179866652は変更前ソース同一性を確認して基準に使い、今回の変更後成功へ代用しない。

## データと注入

Readerにはnetwork方針を観測するspy、進捗と完了を別々に保留/配信する制御、要求ID確定前取消、旧通知、PhotoKit相当のerror/input欠落を注入する。adapter options生成とcallback中継も検証し、fakeだけでnetwork=trueを自称する試験にしない。時計を注入し、取得待ちで旧30/40/180秒を超えることを実時間の長時間sleepなしに検証する。

UIは実Coordinator/Session/Deliveryの状態を経由し、実画像要素・要求発行・出力結果/本文を確認する。fixtureがUIメッセージやbusyを代行しない。cancel後は実終端前後を分けて観測する。合成画像と専用UUID領域/試験pasteboardのみを使い、所有cleanupを確認する。実Photos/iCloud、一般clipboard、OS設定は自動操作しない。

## 本人確認

通常Xcode Runで、写真アプリの事前取得なしに未取得写真を含む4枚出力、取得中の表示と取消、再出力成功後の本文/順序/画像復帰を最終段階にまとめて確認する。合成reader成功を実iCloud成功と記録しない。
