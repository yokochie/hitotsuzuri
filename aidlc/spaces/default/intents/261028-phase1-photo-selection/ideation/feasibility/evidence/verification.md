# コンパイル検証記録

確認日: 2026-10-29 JST。Xcode 27.1 (27A9275)、Apple Swift 6.4、macOS 27.2、arm64で実施。ライブラリへのアクセス、許可要求、生成コードの実行は行っていない。

## 対象と結果

| 対象 | 検証方法 | 結果 |
|---|---|---|
| photokit-design-probe.swift | Swift 6モード、arm64-apple-macos14.0でtypecheck | 終了コード0 |
| photokit-design-probe.swift | 同じ設定で-c（オブジェクト生成） | 終了コード1。escaping closure captures 'inout' parameter 'visited' |
| photokit-api-probe.swift | 同じ設定でtypecheck、制限環境内 | マクロ用プロセスのsandbox_applyがOperation not permittedで失敗。コードの非互換と断定しない |
| photokit-api-probe.swift | 同じ設定でtypecheck、制限外 | 終了コード0 |
| photokit-api-probe.swift | 同じ設定で-c、制限外 | 終了コード0 |

## 再実行方法

リポジトリのルートから実行する。typecheckだけでは検出しなかったエラーがあるため、-cも実施する。以下は検証コードをコンパイルするだけで、写真ライブラリにはアクセスしない。

```sh
xcrun swiftc -c -swift-version 6 -target arm64-apple-macos14.0 -module-cache-path aidlc/spaces/default/intents/261028-phase1-photo-selection/.aidlc-engine/swift-module-cache aidlc/spaces/default/intents/261028-phase1-photo-selection/ideation/feasibility/evidence/photokit-design-probe.swift -o aidlc/spaces/default/intents/261028-phase1-photo-selection/.aidlc-engine/photokit-design-probe.o
```

上記は設計案の既知のエラーを再現し、失敗することが期待値である。

```sh
xcrun swiftc -c -swift-version 6 -target arm64-apple-macos14.0 -module-cache-path aidlc/spaces/default/intents/261028-phase1-photo-selection/.aidlc-engine/swift-module-cache aidlc/spaces/default/intents/261028-phase1-photo-selection/ideation/feasibility/evidence/photokit-api-probe.swift -o aidlc/spaces/default/intents/261028-phase1-photo-selection/.aidlc-engine/photokit-api-probe.o
```

後者は成功した。Observationマクロがプロセス制限で起動できない環境では、実行環境の制限とソースのエラーを区別する。

## 検証した範囲

- 設計案の子コレクション取得・再帰処理の最小再現。
- クロージャを使わない走査、トップレベル取得、権限API、写真のみの取得と撮影日時ソート、ネットワーク取得禁止の画像要求とキャンセル。
- SwiftUIの3領域表示とObservationの最小利用。

## 検証していない範囲

設計案全コード、完全なアプリ、リンク・署名・Sandbox権限・利用目的表示、認可の全状態、変更監視と並行処理、実ライブラリ、保存・復元、画面操作、性能、macOS 14実機での動作。これらの成功を本記録から推定しない。
