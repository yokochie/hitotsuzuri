# 依存関係

## 内部

- アプリは `HitotsuzuriCore` に依存する。Coreの選択状態は写真アクセス・画像取得・選択保存のポートを受け取る。
- 記事の表示・編集は `ArticleWorkspace`、`ArticleStoring`、記事モデルと変換処理に依存する。記事への入口で確定した選択を読む。
- `ArticleExportSession` は保存済み記事と記事変換から出力を準備し、`ArticleOutputActions` へ渡す。出力の実装は画像取得、変換、ジョブ記録、書込みと復旧に依存する。
- Core試験はCoreの型と試験ダブルを使う。UI試験は起動引数・環境変数を通じて試験用のアプリ構成を起動する。

## 外部

- システム写真ライブラリの許可、選択フォルダへの権限、Finder・ペーストボードはmacOSから得る。
- 通常の写真表示と画像1枚の検証出力はローカル取得を使う。完成記事の画像取得は `ArticleExportDelivery.swift:140` でPhotoKitにネットワークを許可する。
- 利用者がファイルや本文をnoteへ受け渡す。配布物に第三者Swiftライブラリを追加する設定は見当たらない。
- 検証環境はGitHub Actionsランナー、Xcode、BashとPython 3に依存する。Actionsのcheckoutと診断用のartifactアップロードはコミットで固定されている。
