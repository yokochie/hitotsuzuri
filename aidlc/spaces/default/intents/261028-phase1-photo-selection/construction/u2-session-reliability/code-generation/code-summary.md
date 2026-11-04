# U2 実装結果

## 変更ファイル

変更対象の正本は[source-manifest.json](source-manifest.json)の16パス。Xcodeプロジェクトとscheme、CoreのModels/Ports/SelectionPersistence/SelectionWorkflow/PresentationSnapshot/PickerContent、U2の6テストクラスとFake、verify-phase1.shを追加・更新した。U1テスト60件、verify-u1.sh、本人のREADMEと入力設計書は変更していない。

## 実装判断

- 認可を確認してから設定と確定を独立読込する。現在のフォルダ・所属と全4画像を確認した後に、アルバム、保存順、日時、画像、最後の確定をMainActorで一括公開する。失敗は候補全体を解放し、有効フォルダと原本を保護する。
- 復元状態、設定読込の失敗、設定保存状態、4枚保存状態を分離した。復元・検証・書込中は編集を拒否する。二重startは進行中のTaskを共有し、保存は操作IDと編集revision/世代/内容が一致した結果だけ反映する。入力を後で再生しない。
- 明示的なconfirmSelectionと、従来の原本保護を維持するsaveSelectionを分けた。破損確定だけ、SHA256固定名のquarantineファイルへ排他作成し同一bytesを読戻し検証する。同じ内容の退避は再利用し、内容衝突・退避失敗・原本変更・置換失敗では成功にしない。置換直前に原本と退避を再確認しatomic書込する。
- 未知版、I/O失敗、過大原本、symlinkを回復で上書きしない。過大原本はoversizedDataで区別し、回復を勧める破損案内とは分けた。設定破損は自動置換しない。JSONのschemaVersion 1と保存項目は互換のまま。
- 復元と確定は同じ画像検証を利用する。全4枚の共通絶対15秒期限を渡し、既存ImageAccessの個別期限との早い方を採用する。256 MiBの全生存バッファと予約、最大8要求の管理をそのまま共用する。復元画像は同一ストレージの参照を公開し複製しない。
- 通常診断は既存Diagnosticsの失敗分類のみ。正常復元の状態、個人ID・名称・画像・原本・退避パスを記録しない。

## 検証結果

指定U2コマンドで48件成功。モデル8、保存9、復元11、再試行8、表示7、結合5。各層の実Red→Greenと整理を[tdd-evidence.md](tdd-evidence.md)に記録した。

U1全60件と合わせた108件が成功した。結果は .build/DerivedData/Logs/Test/Test-Hitotsuzuri-2026.11.01_11-13-56-+0900.xcresult。既存check-coverage.swiftを同結果へ適用し、App/Core全Swiftの加重行カバレッジ854/1002 = **85.23%**、終了コード0。アプリ入口、View、Photosアダプタも分母に含む。除外・閾値の変更なし。

自動テストは合成ID/画像、Fake、隔離一時ディレクトリだけを使用した。個人の写真ライブラリを開かず、権限UIも要求していない。実ライブラリの復元・外部削除・権限変更・実保存先の障害回復は[手動確認](manual-verification.md)に残し、成功とは扱わない。

## 計画との差異

- 表示本体はU1で既にCoreのPickerContentへ分離されているため、薄いPickerViewの変更は不要だった。PickerContentとPresentationSnapshotを更新し、実際のSwiftUI描画も自動検証した。
- 約35件という目安に対し、期限・競合・原本保護の境界を優先して48件とした。
- 最終検証候補のbash scripts/verify-phase1.shを追加した。本人承認前なので、このスクリプトを最終検証として実行していない。計画Step16が許可する直接の全件xcodebuildとカバレッジを実行した。承認済みverify-u1.shの意味は変更していない。
- Fakeの再待機で完走しなかった2実行は停止し、Fake修正後に再実行した。製品のRedや成功の証拠には含めていない。初回の重複起動試験の期待件数は、起動探索と現在参照再検証が各1回あることに合わせ修正した。

## 未実行の確認

作成した自動テストはすべて実行済み。新しい最終検証スクリプトの承認と実行、本人による実機項目は未完了。CIは本人の変更決定により作成していない。U3の最終VoiceOver/キーボード全経路、100枚以上/10往復/200msの実測は今回の成功に含めない。
