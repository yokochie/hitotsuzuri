# Phase2の実現性評価

## 判定
**条件付きで実現可能と評価する。** 承認済みの目的 `../intent-capture/intent-statement.md` と本段階の `feasibility-questions.md` を入力とする。本人用のローカル記事制作で、追加の外部連携・有料サービス・固定期限を前提としない。現時点の評価は既存コードと記録の読解であり、Phase2のビルド・画像書き出し・実機成功を示すものではない。

## 既存実装との照合
| 対象 | 観測した事実 | Phase2への含意 |
|---|---|---|
| 選択データ | `HitotsuzuriCore/Models.swift` の `CommittedSelection` はschemaVersion 1、選択ID、アルバムID・名称、順序付き写真ID4件、確定日時を持つ | 記事への引継ぎ元が存在する。既存選択を再実装せず、新旧データの読込互換性を検証する |
| 保存 | `HitotsuzuriCore/SelectionPersistence.swift` はアプリ専用領域のJSONを扱い、未知版・破損の区別、原子的書込、破損退避の処理がある | 下書き保存の責務と既存選択保存の分離・再利用範囲は後続設計で決定する。既存ファイルを新形式で無断置換しない |
| 画像 | `HitotsuzuriCore/LocalImageAccess.swift` は512pxの要求・縮小と明示的な通信禁止を実装する | 表示用画像を記事成果物に流用しない。記事用解像度、編集結果、回転、色、位置情報除去を別に検証する |
| 実行環境 | `Hitotsuzuri.xcodeproj/project.pbxproj` はmacOS 27.0、Swift 6.0、Sandbox有効。既存entitlementsはSandboxと写真ライブラリを含む | 対応OSを拡大する判断はしない。利用者指定先への書出し権限と設定差分は検証対象 |
| 検証手段 | `scripts/verify-native.sh` はXcodeでU1/U2/U3/UIテストと行カバレッジ検査を行う | Phase2の対象追加と、新しい書出し処理のテスト方法を計画する。本段階では未実行 |

## Phase1の現在地と持越し
前回の `../../../261028-phase1-photo-selection/construction/build-and-test/build-and-test-summary.md` の2026-11-04現在結果には、205件成功・失敗/スキップ0、製品行カバレッジ90.21%が記録されている。これは過去の証拠であり、今回の再実行結果ではない。同記録は速度200ms条件の未達、子フォルダ折畳みによる選択解除、コントラスト等の未確認、横断追跡の未被覆を残す。`manual-acceptance.md` の本人確認は基本保存・復元等の確認範囲に限定する。Phase1の完了状態を、全品質条件の合格と読み替えない。

Phase1ではCI省略の個別決定が記録される一方、現行のチーム規約には統合前CIがある。過去の例外をPhase2の免除として引き継がない。実装計画で適用対象・実行環境を確定し、規約の80%基準とTDDを維持する。

## 成立条件と検証方針
- 選択ID・写真IDと順序を保持し、既存の保存済み選択を読み込めること。新しい下書きが再起動後も復元され、旧正常データを失わないこと。
- ローカルで取得可能な実画像について、現在の編集結果・回転を反映した記事用画像を生成できること。資料の画像設定値は提案であり、ここでは確定しない。
- 書出し先の権限、4枚と本文の対応、相対画像参照、重複出力、容量不足、権限取消、キャンセルを検証し、不完全な成果物を成功扱いしないこと。
- noteへの受け渡しは本文コピーと画像の手動操作で本人が確認する。直接インポートや自動投稿の成立は前提にしない。
- 写真アプリで事前取得した画像を使い、記事用取得も通信禁止を維持する。表示用画像が取得できても記事用画像が取得可能とは限らないため、取得不能を案内する。

## 未検証事項と次の判断
画像書出しの実証、保存先へのSandboxアクセス、Phase2の保存方式、旧データの引継ぎテスト、CI実行環境と対象、本人の実機確認手順を後続の要件・計画で具体化する。実装開始前に要件と計画の本人確認を受ける。詳細な設計や技術選定は本評価では確定しない。

## 参照
- 目的: `../intent-capture/intent-statement.md`
- 本人確認: `feasibility-questions.md` Q1〜Q3と要約確認
- コード: `HitotsuzuriCore/Models.swift`、`HitotsuzuriCore/SelectionPersistence.swift`、`HitotsuzuriCore/LocalImageAccess.swift`
- 設定・検証: `Hitotsuzuri.xcodeproj/project.pbxproj`、`Hitotsuzuri/Hitotsuzuri.entitlements`、`scripts/verify-native.sh`
- 前回記録: `aidlc/spaces/default/intents/261028-phase1-photo-selection/construction/build-and-test/build-and-test-summary.md`、同 `manual-acceptance.md`
