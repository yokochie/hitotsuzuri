# ひとつづり Phase 1 引き継ぎ

2026-11-04、未達・既知問題・未確認事項を明示したBuild and Testを本人が承認し、計画内の工程を完了した。

## 起動

リポジトリ直下のHitotsuzuri.xcodeprojをXcodeで開き、scheme Hitotsuzuri、実行先My MacでRunする。通常利用ではRun Argumentsの--measure-nativeを外す。--ui-test-fixtureはDebugの自動UI試験専用で、通常利用には指定しない。

写真アクセスを許可し、写真アプリ内の対象フォルダを複数選ぶ。アルバムを1つ選択、写真4枚を選択順に確定・保存する。終了後も保存済み参照を検証して復元する。保存するのは参照等であり、写真本体ではない。

## 検証

リポジトリルートで `bash scripts/verify-native.sh`。XcodeとmacOSのUI自動操作許可、ロック解除されたGUIセッションが必要。最終205件成功、全製品行カバレッジ90.21%。テストは合成Debug fixtureを使い、実Photosの許可や個人ライブラリを操作しない。

補助測定ツールの使い方・実測値はverification/real-library-measurement-20261104.mdとU3のmanual-verification.mdを参照。測定モードは通常利用の要件ではない。

## 残る事項

速度条件はNot Metのまま受入。親フォルダ折畳み時の子選択/編集中写真の解除は既知問題として未修正。コントラストの数値等はUnverified、横断追跡NFR2/NFR4/NFR5はFAILを維持。詳細と本人承認の範囲はverification/construction-verification.md、現在の全目標表はbuild-and-test/build-and-test-summary.mdに記載する。承認は未達/未確認の解消を意味しない。
