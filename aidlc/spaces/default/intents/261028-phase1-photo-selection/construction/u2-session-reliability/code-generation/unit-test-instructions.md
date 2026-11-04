# U2 テスト手順

## 構成

Xcode標準のXCTestを使うhostless macOSターゲットHitotsuzuriU2Testsを共有schemeへ登録する。外部依存は追加しない。Step 2でrunnerを実行確認してから、各層のRedへ進む。Photosの実データや権限操作は使わず、Fakeのライブラリ・画像・保存担当と注入時計で決定的に検証する。

## U2専用実行コマンド

```bash
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriU2Tests -enableCodeCoverage YES -derivedDataPath .build/DerivedData CODE_SIGN_IDENTITY=- test
```

最初のRedの前にこのコマンドが実行可能であることを確認する。XCTest起動権限による失敗を期待するRedと数えない。各Red/Greenの実行結果とxcresultをtdd-evidence.mdへ記録する。

## テスト範囲

U2ModelTests、U2PersistenceTests、U2RestoreTests、U2RecoveryTests、U2PresentationTestsの各責務で5〜8件を基準に、正常系と2件以上のエラー/境界条件を含める。主要な保存・再起動・復元の境界はU2IntegrationTestsで確認する。全件成功後も仕様上の追加条件に応じて件数を増やす。

保存テストはテストごとに隔離した一時ディレクトリを作り、合成JSONと固定IDを使い終了時に削除する。個人のApplication Supportや写真ライブラリを触らない。ファイル操作失敗、退避衝突、原本変更は注入可能な境界で再現する。時計で期限を進め、実時間15秒待機を通常テストにしない。

## カバレッジと回帰

目標は全製品Swiftコードの行カバレッジ80%以上。U2専用実行だけでは全体閾値を判定しない。Build and TestでU1/U2の組合せ結果を計測し、App/Coreの全ソースを分母に含める。U1の60件も回帰確認し、既存テストを弱めない。統合前検証は承認済みCI省略決定に従いローカルで行う。

## 本人による確認

保存して終了後の再起動、実際の写真削除後の再起動、Photos権限変更、実保存先への書込失敗と回復は手動確認項目として分離する。Fakeの成功で実機確認済みとは記さない。

