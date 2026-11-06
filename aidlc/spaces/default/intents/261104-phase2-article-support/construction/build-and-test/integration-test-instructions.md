# Integration Test Instructions

## 境界と試験データ
XCTest、UUID所有root、実ファイル/実Image I/O合成画像を使う。C1の保存/関連付け/不確定照合→U2の編集/純粋投影→C3の保存済み固定値→C2画像を一枚ずつ→U3 Writer/Journal/回復を確認する。写真不能時の文章保持、同ID異入力、symlink/外部変更/同期/片付け失敗、古い応答、固定コピーを含む。

## 今回の実行先
成功済み同一SHAの正式CIに全境界クラスを含む。ローカルでUnit別ラッパーと全体を重ねない。今段階の確認コマンドはbuild-instructions.mdの承認済みCI結果確認一回だけ。CIの実コマンドはbash scripts/verify-native.sh --functional。

## 部分再現が必要になった場合
U1はbash scripts/verify-article-foundation.sh、U2はbash scripts/verify-draft-experience.sh --functional、U3はbash scripts/verify-article-export.sh --functional。既知の原因があるときだけ必要なクラスに絞り、新しいCIで実行する。ここに列挙したことを追加実行済みとしない。固有xcresult、選択ケースの実行/成功/skip0を検査する。

## 期待と限界
全製品80%は単一主bundleで判定し、部分率を平均しない。合成UIは実macOS XCTestのアプリを操作する。Node/DOM/Webブラウザによる試験ではない。実PhotoKitの個人ライブラリ、general clipboard、実Finder、noteへ自動試験を広げない。
