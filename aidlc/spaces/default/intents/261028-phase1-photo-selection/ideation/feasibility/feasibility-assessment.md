# ひとつづり Phase 1 — 成立性評価

## 評価の基準

上流資料は[目的の文書](../intent-capture/intent-statement.md)。対象は本人用の写真選択アプリで、探索・4枚選択・保存を優先する。復元・変更対応・性能はInceptionで範囲を再検討する。本段階は成立性の評価であり、構成や実装方式の確定ではない。

利用条件は[確認済み回答](feasibility-questions.md)Q1〜Q5による。システム写真ライブラリ1つ、現在の本人のMac、ライブラリを変更しない実装、画像取得通信なしを前提とする。

## 結論

**条件付きで実現可能と評価する。** ローカルの開発環境と主要APIの利用可否は確認できた。設計案の再帰探索コードにはコンパイルエラーがあり、そのまま採用できない。走査方法を変えた検証コードはコンパイルできたが、権限・実データ取得・画像のローカル利用可否は実機での確認が必要である。

## 確認できた事実

| ID | 確認事項 | 結果・根拠 | 限界 |
|---|---|---|---|
| F-01 | 開発環境 | 2026-10-29 JST、Xcode 27.1 (27A9275)、Apple Swift 6.4、macOS 27.2、arm64、AI-DLC 2.11.2 | Xcodeアプリプロジェクトは未作成。アプリ全体のビルド結果ではない |
| F-02 | フォルダと子コレクションの取得 | Apple資料とローカルSDKのPHCollection.hで取得APIを確認。設計例のPHCollectionListからの継承API呼び出しも型チェックを通過 | 入れ子の実データと重複排除の動作は未確認 |
| F-03 | 読み取り用途と権限名 | PHAccessLevelにはaddOnlyとreadWriteがあり、読み取り専用区分はない。Q3でreadWrite要求と変更処理を持たない実装を確認済み | OS権限として書き込みを禁止する保証ではない |
| F-04 | SwiftUI・Observation・PhotoKitの主要API | 検証用コードをSwift 6言語モード・arm64・macOS 14ターゲットで型チェックし、オブジェクト生成まで成功 | 検証コードのみ。全設計例・署名・UI・権限ダイアログ・実データは未検証 |
| F-05 | 設計例の再帰探索 | 型チェックは成功したが、オブジェクト生成でescaping closure captures 'inout' parameter 'visited'が発生 | 型チェック成功だけではコードの成立性を断定できない |
| F-06 | 再帰探索の代替表現 | インデックスによる順次走査に変えた検証コードはオブジェクト生成成功 | 動作の正しさはFakeによる探索テストと実機で別途確認する |
| F-07 | 画像取得通信の指定 | 検証コードのisNetworkAccessAllowed=falseはコンパイル成功。Q4により設計例のtrueは採用しない | PhotosやOSが独立に行う同期の停止までは保証しない |

## 実現を左右する制約

- 写真ライブラリへのアクセス許可は本人による操作が必要。拒否・制限時の案内と、許可前に取得しない動作を検証する。
- Sandbox、利用目的文字列、署名後の権限設定の組み合わせは、アプリの実行で確認する。Picturesフォルダのファイルアクセス権とPhotos Library権限を混同しない。
- ライブラリのメタデータが存在しても、要求した画像がローカルで取得できるとは限らない。取得できない写真を確定できるか、どの表示にするかはRequirements Analysisで決める。
- 現在のMacでの実行を最優先とする。最低macOSは**14を候補**とする。主要APIのコンパイル根拠はあるが、macOS 14実機での動作保証はまだない。対象OSはInceptionで決定する。
- Swift 5.9以降という設計案の記述だけでは言語モードを確定しない。確認済みのツールチェーンはSwift 6.4、検証に使った言語モードは6である。
- 本人用・ローカル実行の範囲にAWSの実行基盤やアカウントは必要と評価しない。AI-DLCの採用はAWSへの配置を意味しない。

## 次段階への推奨

1. 範囲定義で探索・4枚選択・保存を中核とし、復元・起動中の変更追従・性能の最低限を比較して決める。
2. 要件分析で保存対象と成功表示の条件、写真取得失敗時の確定可否、ローカル画像の扱い、4枚の順序と解除、フォルダ・アルバム変更時の扱いを明文化する。
3. 実装計画でアクセス許可・実フォルダ取得を早期検証に置く。Fakeでのテストと本人による実機確認を分ける。
4. 初回の実行手順、写真アクセス確認手順、結果記入欄を日本語で用意する。本人のSwift・Xcode経験を前提にしない。
5. アプリコードにはConstruction前の承認後に着手する。今回のSwiftファイルはコンパイラ検証専用で、実行していない。

## 検証資料

- [コンパイル検証記録](evidence/verification.md)
- [設計例の最小再現](evidence/photokit-design-probe.swift)
- [API・代替走査の検証コード](evidence/photokit-api-probe.swift)
- [制約一覧](constraint-register.md)、[リスク・未確定事項](raid-log.md)

## 参照した一次資料

- [Apple: PHCollectionList](https://developer.apple.com/documentation/photos/phcollectionlist) — 階層とコレクション取得。
- [Apple: PHAccessLevel](https://developer.apple.com/documentation/photos/phaccesslevel) — アクセス区分。
- [Apple: Photos Library Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.personal-information.photos-library) — 写真ライブラリ用の権限設定。
- ローカルSDK: `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/Photos.framework/Headers/PHCollection.h`、`PHPhotoLibrary.h`。

## Assumptions & Open Questions

- 最低macOS 14は提案であり未決定。現在のMac以外の実行確認は未実施。
- 写真がローカルにあると判断する条件と、取得できない写真の確定可否は未決定。
- 保存形式・保存先・復元・ライブラリ変更追従・性能の範囲はInceptionで決定する。
