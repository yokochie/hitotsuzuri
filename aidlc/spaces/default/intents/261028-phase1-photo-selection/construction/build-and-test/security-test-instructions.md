# 保護の検証

## 自動検証

各単位のテストで認可前参照なし、通信false、期限/取消、保存破損/未知版/過大/symlink保護、失敗時原本保持、正常保存後の認可/取消競合を確認する。全体は `bash scripts/verify-all.sh`。専用の合成JSONとFakeだけを使う。

## コード確認と本人確認

Photos変更APIを製品に持たないことと画像要求のisNetworkAccessAllowed=falseを確認する。通常ログは失敗分類のみ。実Photos権限・オフライン取得・外部削除は本人手順へ記録し、未観測を成功としない。CIは本人決定により非適用。

