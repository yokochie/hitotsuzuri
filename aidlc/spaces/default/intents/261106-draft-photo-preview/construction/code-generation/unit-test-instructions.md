# 写真表示復帰の検証手順

## 前提と対象

XCTest/XCUITest、既存Xcode project/共有scheme、scripts/native-test-runner.pyを使用する。通常の検証先は既存GitHub Actionsのxcode-27 runner。依存の追加やローカル認可操作は不要。新classは `ArticlePhotoRestorationUITests` とし、Xcodeの既存synchronized groupとrunnerのclass発見を確認する。

## 今回の回帰だけを再現するコマンド

リポジトリrootで実行する。CIの全機能実行にも同じclassが含まれるため、通常は全機能の同一SHAの結果を利用し、別のローカルUI実行を重ねない。

```bash
bash scripts/verify-native.sh ArticlePhotoRestorationUITests
```

既存の表示/資源部品を絞って確認する場合のコマンド:

```bash
bash scripts/verify-native.sh ArticleImageTests ArticlePreviewRetryTests ArticleResourceTests
```

既存の出力/保存契約を絞って再現する必要がある場合:

```bash
bash scripts/verify-native.sh ArticleExportSessionTests ArticleExportIntegrationTests ArticleDraftSessionTests ArticleNavigationTests
```

これらは必要時の対象指定であり、CI全機能が同じ検証を済ませた後に全部繰り返す指示ではない。全体coverageは部分実行の率で判定しない。

## Red / Greenと既存CI

変更前はd3feef4のCI42030797393のCore/native成功とソース一致を利用する。先にテスト/DEBUG注入をpushし、出力終端後の実画像または実要求に関する失敗を確認する。通常表示の復帰処理はRed観測前に変更しない。ビルドやfixture自体の失敗は直して再観測する。

修正後も既存 `.github/workflows/verify.yml` を使用する。全Core成功後に起動smokeと全機能/coverageが実行され、新回帰が含まれることをログで確認する。新テストが未発見・skipなら合格としない。テスト選択、除外、80%閾値を緩めない。pushとPRの重複runは同一SHAの有効な一方を証拠とする。

## 期待値

計画T1–T10を確認する。画像取得カウントだけでなく、4枚の画像要素と番号ごとの状態を確認する。再試行では対象番号の要求増加と画像表示を確認する。他番号・本文・順序は保持する。時間待ち固定で成功を仮定せず、状態/要求/終端を待って上限で失敗させる。

画像失敗・取消・出力の遅延・保存先取消・容量/保存/入力失敗は合成adapter/DEBUG専用注入で決定的に作る。通常実装と同じCoordinatorの入口と終了処理を通し、fixture側で勝手にプレビューを復帰させない。通常データへfallbackしない。資源と遅い応答の検証は既存部品の制御可能なclock/gateも利用する。

## カバレッジと隔離

全手書きApp/Core Swiftの行カバレッジ80%以上を、統合した全スイートの既存CIで検証する。部分実行に全体coverage合格を求めず、値を代用しない。合成写真/専用UUID root/試験pasteboardのみを使い、終了時に所有確認付きでcleanupする。実写真、本人記事、一般pasteboard、OS設定を読み書きしない。

## 本人のMacでの確認（最終段階）

Xcodeで通常Runし、下書きを開いて4枚表示、出力または取消後の4枚表示、必要時の再試行、本文と写真順序の保持をまとめて確認する。写真アプリで事前読込が必要な出力画像の可用性と、表示要求の欠落を区別する。結果はCIとは別に本人の報告として記録する。
