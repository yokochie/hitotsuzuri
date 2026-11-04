# U1 技術選定と成立性確認

根拠: [機能仕様](../functional-design/functional-spec.md)、[業務ルール](../functional-design/rules.md)、[要件](../../../inception/requirements-analysis/requirements.md)、[内部契約](../../../inception/contract-design/contract-summary.md)、[確認回答](nfr-requirements-questions.md)。以下は受け入れ条件であり、測定・実装済みとの主張ではない。

## 選定

| ID | 対象 | 判断と理由 | 未検証事項 |
|---|---|---|---|
| NFR1.1 | アプリ | Swift・SwiftUIのmacOSネイティブアプリ。表示名ひとつづり、Xcode Hitotsuzuri、アプリ型HitotsuzuriApp | アプリプロジェクトは未生成。ビルド・起動は後続で確認 |
| NFR1.2 | ツールチェーン | 本人の現在のMacと導入済みXcodeを使う。今回読取りでXcode 27.2 build27B52、Apple Swift6.4.2、arm64/macos27.2 targetを確認 | 上流の27.1/6.4は以前の観測。最新版への更新作業は行っていない。最低OS・言語モードはNFR Designで具体化 |
| NFR1.3 | ライブラリ | OS標準の写真APIを読み取り用途で使用し、5責務をFakeに置換できる境界を保つ | 認可・階層・順序・画像オプションを対象SDKでコンパイルし、実写真の順序とローカル取得は本人確認 |
| NFR1.4 | 保存 | 外部DBを追加せず標準の構造化シリアライズと専用ファイルを使う。版付きの設定と確定を分離 | JSONを第一候補として、固定パス・日時・原子的置換・退避をNFR Designで確定。未検証の原子性を保証しない |
| NFR5.6 | 自動検証 | Xcode同梱のSwift Testingを単体/統合テストの第一候補、XCTestを必要なUIテストの候補とする。外部パッケージを必須にしない | 実際のテストターゲットとカバレッジ取得・UI計測をCode Generation計画で検証。TDDを維持 |
| NFR5.7 | CI | 既決の専用MacでのCIを利用する。GitHub Actionsのself-hosted runnerを準備候補とする | まだ登録・環境構築・実行していない。公開範囲と隔離・実行元制限を設定前に確認 |

## 比較と帰結

OS標準技術を優先すると写真とネイティブ操作へ直接対応でき、外部ライブラリ管理が増えない。代わりに認可・コールバック・並行実行の境界は自分たちで検証する。写真ピッカーだけで階層探索を代替する案は要求を満たす根拠がないため採らない。小さな設定と最後の確定1件へ外部DBを導入する利点は現時点で小さい。保存形式の候補決定は原子的置換の動作実証を代替しない。

## 公式資料と確認範囲

- [Apple: 画像取得の通信許可](https://developer.apple.com/documentation/photos/phimagerequestoptions/isnetworkaccessallowed)：通信可否を指定する境界。全画像の可用性を保証する根拠ではない。
- [Apple: Xcodeへテストを追加](https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project)：Swift TestingとXCTestのテスト作成を説明。
- [Swift Testingの同梱形態](https://github.com/swiftlang/swift-testing/blob/main/Documentation/Distributions.md)：ツール同梱版を使う方針の根拠。

既存の参考コードをそのまま確定実装とせず、具体SDKでのビルドと本人の実機確認を別に残す。機能設計の画像結果種別の軽微な指摘は、C3の結果種別を技術設計と実装の明示的な型へ対応づけて解消する必要がある。上流成果物を黙って書き換えたり、解消済みと記録したりしない。
