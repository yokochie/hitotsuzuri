# U2 復元と回復

根拠: [性能](../nfr-requirements/performance-requirements.md)、[保護](../nfr-requirements/security-requirements.md)、[容量](../nfr-requirements/scalability-requirements.md)、[信頼性](../nfr-requirements/reliability-requirements.md)、[診断](../nfr-requirements/observability-requirements.md)、[技術選定](../nfr-requirements/tech-stack-decisions.md)、[機能仕様](../functional-design/functional-spec.md)、[契約](../../../inception/contract-design/contract-summary.md)。CIは[本人の変更決定](../../../change-decisions/2026-10-31-local-verification.md)により省略。以下は設計であり未実装。

## R21 二段階復元

対応NFR3.25、NFR4.21。起動時に認可→設定と確定の独立読込→現在の有効フォルダ→アルバムと4枚所属→4画像の順に検証する。候補をローカル変数に保持し、途中状態を編集中選択として公開しない。全成功ならUI実行境界でアルバム・順序・確定日時・画像・lastCommittedを一括適用する。

1件でも無効なら候補全体を捨て、アルバムと全選択を空にし有効フォルダだけ残す。保存原本の写しは内部で保護できるが、復元成功や保存済み4枚と表示しない。権限不足は復元失敗の一般文より権限案内を優先する。構成変更の読み直しは再起動のみ。

## R22 退避後置換

対応NFR3.26、NFR3.22。本人の新しい有効4枚確定でだけ、保存担当が現在原本のbytes/版を再検査する。正常は既存のatomic保存、未知版/ioFailure/過大は拒否、破損だけ退避経路を許可する。操作開始時に見た原本と現在bytesが違えば安全に拒否し、別原本を誤って置換しない。

退避先がなければ排他的に原本のコピーを作成し、読戻しbytes一致を確認する。あれば同一bytesを確認して再利用する。退避完成後にもう一度原本一致を確認して新確定をatomic置換する。置換前の失敗は旧原本を保ち、置換成功後にだけ成功を返す。退避だけが残った中断は正常な確定とみなさない。置換の結果未確定で裏の書込みを二重再試行しない。

設定の破損は新フォルダ選択で自動退避/置換せず保護する。本人へ安全な手動復旧手順を用意する。U2の自動回復は破損確定レコードの新規確定に限定する。

## R23 編集と再試行

対応NFR3.27。保存中は固定した編集内容を用い、結果IDと内容を照合して成功反映。失敗は編集と旧確定を保持し、本人再試行は参照と画像検証から始める。編集を終了時に書き出さない。フォルダ変更で対象外になったとき古い成功案内を消す。設定保存と4枚保存の状態は独立に表示する。

