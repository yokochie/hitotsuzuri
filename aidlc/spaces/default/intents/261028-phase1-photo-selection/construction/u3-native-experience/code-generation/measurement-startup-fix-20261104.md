# 測定CLIのGUI初期化修正

本人08ff6b00は --capture 起動時、校正一致125/3の後にCGS_REQUIRE_INIT / Assertion failed(did_initialize), CGInitialization.c:44でabortしたと報告した。current Build and Test中の本人requested修正として、scripts/measure-native.swiftと測定手順だけを変更する。新計画/承認/reopen/review/manifestの操作は行わない。

## 根拠と変更

ローカルXcode SDKのNSApplication.hはsharedApplicationを公開し、CGWindow.h:294〜308はCGPreflightScreenCaptureAccessを既存許可の照会のみ・promptなし、CGRequestScreenCaptureAccessを許可要求APIとして区別している。[NSApplication](https://developer.apple.com/documentation/appkit/nsapplication)と[shared](https://developer.apple.com/documentation/appkit/nsapplication/shared)の初期化の役割に沿って、mainと共通startupをMainActorへ置き、NSApplication.shared→CGPreflight→許可判定→必要時だけScreenCaptureKitという順にした。許可要求APIは呼ばない。

--preflight-onlyを追加した。このモードと--captureは同じstartupを通るが、preflight-onlyは画面列挙/SCStream初期化より前にreturnする。両flagが渡された場合もpreflight-onlyのreturnを優先する。引数なしは従来どおり校正だけで終了しGUI初期化や画面APIを呼ばない。

## 安全な変更前確認

```sh
xcrun swiftc -swift-version 6 -parse-as-library -module-cache-path .build/MeasureModuleCache -F .build/DerivedData/Build/Products/Debug -framework HitotsuzuriCore -Xlinker -rpath -Xlinker "$PWD/.build/DerivedData/Build/Products/Debug" scripts/measure-native.swift -o .build/measure-native-baseline
env DYLD_FRAMEWORK_PATH=.build/DerivedData/Build/Products/Debug .build/measure-native-baseline
```

変更前ソースのビルドexit0、引数なしは校正一致125/3でexit0。次にpreflight-onlyだけを準備し、まだNSApplication初期化を入れない旧順序のバイナリ .build/measure-native-startup-before を同じSwift6コマンドでビルドして --preflight-only を実行した。これも校正一致・既存許可確認済みでexit0だった。したがって安全確認の範囲では本人のassertionを再現できず、CGPreflight自体が原因だったと断定しない。画面列挙/フレーム取得へ進んで再現させることは行っていない。

## 最終ビルドと起動結果

```sh
xcrun swiftc -swift-version 6 -parse-as-library -module-cache-path .build/MeasureModuleCache -F .build/DerivedData/Build/Products/Debug -framework HitotsuzuriCore -Xlinker -rpath -Xlinker "$PWD/.build/DerivedData/Build/Products/Debug" scripts/measure-native.swift -o .build/measure-native
env DYLD_FRAMEWORK_PATH=.build/DerivedData/Build/Products/Debug .build/measure-native --preflight-only
env DYLD_FRAMEWORK_PATH=.build/DerivedData/Build/Products/Debug .build/measure-native
```

すべてexit0。最終preflight出力:

```text
時刻系校正: 一致、numer 125、denom 3
GUI初期化: 完了、main thread true
画面収録許可: 確認済み。画面列挙・フレーム取得は未実行。
```

引数なしは校正の1行だけで終了した。許可未取得の環境での出力分岐は今回は実観測しておらず、OS権限を変更して再現させてもいない。--captureは実行していないため、修正後の実capture/OCR/30操作性能成功も未確認である。非abortの安全startupと、本番capture成功を混同しない。

## 引き継ぎ

最終バイナリは .build/measure-native。本人にはまずリポジトリルートで --preflight-only を実行してもらい、結果確認後にだけ手順のcaptureへ進む。アプリ本体は変更せず、無関係な205件のUI再実行も行っていない。従前の205件/90.21%は前段のアプリ検証値で、今回CLI修正後に全体を再計測した値ではない。sourceと測定手順/本記録を凍結する。
