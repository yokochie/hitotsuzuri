# Security Test Instructions

## 適用範囲
単一利用者のローカルmacOSアプリ。新しい外部依存/有料スキャナ/クラウド認証はない。WebのDASTや負荷基盤を追加しない。

## 自動確認
正式CIのCore/統合でnetwork=false、変更API非使用、私的canary非出現、未知版/破損/競合/ID異入力、no-follow/相対descriptor、非置換公開前後の実体/digest、未生成の既知名保護、途中片付けと再起動を確認する。OSActionは試験専用pasteboardと注入workspaceを用い、general clipboardや実Finderを操作しない。GitHub権限とartifactはverify.ymlと限定診断workflowの固定SHA/合成bundle限定を確認する。

## 実行方法と結果
今回の自動証拠はCI41994393925 attempt2の同一SHA全機能結果で、別のローカルsecurity実行を重ねない。再現に必要なら所有クラスだけを新しいCIで実行する。追加SAST/DAST/依存DBスキャンは実行していないので、その合格は主張しない。

## 本人確認
実Photosライブラリの非変更・オフライン・現在編集、出力JPEGの回転/色/位置情報、OSパネルから選んだSandbox保存先の寿命と範囲、実Finder/手動note受渡しをまとめて確認する。元データ/旧完成物を変更せず、試験用の記事/写真/出力先を使う。未確認はtest-results.mdに残す。
