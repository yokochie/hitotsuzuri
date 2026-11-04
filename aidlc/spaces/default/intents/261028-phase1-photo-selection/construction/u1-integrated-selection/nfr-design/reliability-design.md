# U1 信頼性設計

根拠: [性能要件](../nfr-requirements/performance-requirements.md)、[保護要件](../nfr-requirements/security-requirements.md)、[容量要件](../nfr-requirements/scalability-requirements.md)、[信頼性要件](../nfr-requirements/reliability-requirements.md)、[診断要件](../nfr-requirements/observability-requirements.md)、[技術選定](../nfr-requirements/tech-stack-decisions.md)、[機能仕様](../functional-design/functional-spec.md)、[内部契約](../../../inception/contract-design/contract-summary.md)、[確認回答](nfr-design-questions.md)。本段階は設計であり、製品のビルド・動作を確認済みとしない。

## RD1 保存形式と原子的置換

対応: NFR1.4、NFR3.6、NFR3.7。FoundationのCodable/JSONEncoder/JSONDecoderを使い、schemaVersionを先に確認する。settings.jsonはschemaVersionとfolderIDs、selection.jsonはschemaVersion・selectionID・albumID・albumTitle・orderedAssetIDs・confirmedAt。日時はUTCのISO8601文字列として時点を保持する。フォルダは空集合可、確定は重複なし4件。未知版を現行版へ読み替えない。

直列化された保存担当が、固定した操作IDと内容を受け取り、形式とサイズを検査してエンコードする。専用ディレクトリと対象が通常の保存先か確認し、同一ディレクトリ内の一時ファイルへ書き出してから置換するFoundationのatomic書込を利用する。設定と確定の同時原子性は求めず、各レコードを独立に保護する。設定変更後も旧確定内容を削除しない。

成功は書込APIが正常に完了した直後に、同じ操作IDと固定内容を返した場合のみ。追加の読戻し失敗を『置換されなかった』と取り違えない。書込成功後の読戻し検証はテストの対象であり、成功通知を旧内容へ戻す処理ではない。保存呼出し開始後は取消トークンで中断せず結果を待つ。UIの待機案内と保存結果未確定を区別する。保存中の重複確定・編集は拒否し、失敗した操作の再試行は検証からやり直す。

SDKのNSDataWritingAtomicとwriteToURL optionsを確認したが、強制中断・ディスク失敗における結果は専用テスト領域で実証する。旧正常内容を壊す失敗が確認された場合は保存実装を修正してから統合する。電源断・媒体故障までのゼロ損失は保証しない。[Apple atomic](https://developer.apple.com/documentation/foundation/nsdata/writingoptions/atomic)参照。

## RD2 原本保護と回復

対応: NFR3.8、NFR3.9。読込結果をmissing/valid/corrupt/unsupported/ioFailureへ分ける。missing以外を初期状態として黙って上書きしない。U1ではcorrupt/unsupported/ioFailureの対象レコードへの書込を拒否する。正常な設定だけは別に保存でき、壊れた確定原本を触らない。破損原本を退避して再確定するU2の経路は、本人の新たな確定操作で原本コピー・コピー検証・新内容の原子的置換を行う設計へ引き継ぐ。未知版にはその経路でも上書きを許可しない。

再起動では一時ファイルを通常の確定内容と見なさない。既定の固定名だけを読む。U2で全参照・全画像検証を終えた場合のみ復元し、欠損時は写真全体をクリア・有効フォルダを保持するが原本を自動破棄しない。

## RD3 失敗分類

対応: NFR4.1。拒否・制限→権限案内、空→対象選択案内、画像未取得→写真アプリで準備後再起動、不明→原因を断定しない案内、参照無効→再起動、書込失敗→編集を保持して再試行。色に加えて状態文を表示する。キーボードとVoiceOver・狭幅の完成はU3。基本表示はU1から備える。

