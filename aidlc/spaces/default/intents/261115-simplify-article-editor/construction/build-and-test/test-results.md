# テスト結果

| 確認 | 結果 | 証跡 |
| --- | --- | --- |
| Xcodeアプリビルド | Xcodeサービスへのアクセスを許可した再実行で終了0 | `.build/ArticleEditorVerification/Build/Products/Debug/Hitotsuzuri.app` |
| 指定の対象Core | 75件成功、失敗・スキップ0、終了0 | `.build/ArticleEditorVerification/Logs/Test/Test-Hitotsuzuri-2026.11.15_13-10-10-+0900.xcresult` |
| `bash scripts/verify-all.sh` | XCTestは493件すべて成功、スキップ0。Coreのみの行カバレッジが3675/6376行（57.64%）のため、スクリプトは終了1 | `.build/All-20261115-130933-83878.xcresult` |
| `bash scripts/verify-native.sh --functional` | Core事前チェック486件成功。UIスモーク2件ともアプリの前面化で失敗、終了65 | `.build/Smoke-20261115-131221-f12894ee8ec746aeb5297609e5438e5c.xcresult` |

Coreの対象・全体・CI相当の件数は重複する。合算していない。Xcodeサービスにアクセスできなかった制限環境のビルドは終了65。サービスアクセスを許可することで同じ構成のビルドは成功した。

## UI停止箇所

`FixtureLaunch.swift:35` でアプリを前面表示する際に `Failed to activate application (current state: Running Background)`。macOSのコンソールがロック中であることを確認した。実装時の試験でも同じ箇所で停止した。変更対象の画面試験と全機能UIは実行できず、製品全体の80%基準は未判定。コードの差し戻しで解消できる根拠は現時点でない。

ログイン済みで画面をロック解除したMac上で、対象UIのコマンドと `bash scripts/verify-native.sh --functional` を再実行できる。追加費用は発生しない。

## ロック解除後の再試験

- CI相当の手順でUIスモーク2件が成功した。全機能試験は566件中556件が成功し、記事UIの10件が失敗、スキップ0件、終了65だった。結果は `.build/Native-functional-20261115-191123-ffbc22541ac0447d9e16b6d64b24e5ba.xcresult`。
- 同じ結果バンドルに `swift scripts/check-coverage.swift` を実行し、製品全体で5846/6376行（91.69%）、終了0を確認した。
- 日付候補の表示確認では、macOSのアクセシビリティ要素の `label` が空だった。候補の文言を `label` と `value` の両方から検査する。
- 下書き選択では、アプリ全体から検索したラジオボタンに別画面の操作も含まれていた。対象を下書き候補のシート内に限定し、開くボタンの有効化を待つ。
- 写真の再取得・復帰では、画面のスクロール位置に依存する要素検索に失敗した。各画像の表示範囲と状態を照合し、必要に応じて写真領域のスクロールとレイアウトを修正する。

修正候補は日付・下書きのアクセシビリティ検索と写真の表示・スクロール。変更範囲を記事画面とその試験に絞り、失敗ケースの再試験後に全機能試験を実行する。実装と検証の見積もりは約1〜2時間、追加費用なし。写真のフォーカス順や復帰時の表示に影響するため、既存の画面操作も再検証する。

## Loop-Back Log

### Loop-back 1 — 2026-11-15T10:34:44Z

- Diagnosis: 記事UIの10件が失敗。日付の値取得、下書き候補の検索範囲、写真の要素を探すスクロールに問題がある。
- Root-cause stage: code-generation
- Planned fix: 状態を取得するアクセシビリティ要素を特定し、写真の復帰と表示範囲を検証してから対象・全機能テストを再実行する。
- Estimated impact: 約1〜2時間、追加費用なし。フォーカス順と画像復帰の回帰を確認する。

## 修正後の全機能試験

- `caffeinate -di bash scripts/verify-native.sh --functional` は終了0。Core事前チェックとUIスモークを通過し、全機能試験は566件すべて成功した。前回失敗した記事UIの10件も成功した。
- 製品の行カバレッジは5866/6379行（91.96%）。結果は `.build/Native-functional-20261115-195825-1695ec17575842b28c26bfd171fa622d.xcresult`。
- ローカル実行結果。GitHub Actions、実写真ライブラリ、別区分の性能計測はこの再試験の対象外。
