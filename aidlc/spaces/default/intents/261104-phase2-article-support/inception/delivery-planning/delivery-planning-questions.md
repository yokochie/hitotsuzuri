# 実装計画の確認

## 確認済みの前提
- 最初に実際に動く最小接続を確認し、U1→U2→U3を順に進める。各Unitを1つのBolt（動く成果物まで仕上げる1回の実装）とする案を基準とする。
- U1では既存選択から記事開始・基本編集・手動保存・再開・実画像1枚の出力を確認する。
- 本人が判断・実写真確認を担当し、AIが実装する。TDD、製品全体80%以上の行カバレッジ、統合前CIを維持する。
- CI環境は未用意であり、この段階で実行先・設定・費用を具体化する。過去のCI省略を引き継がない。
- 接続仕様のR-01/R-02は本人の承認によりリスクとして受容された。修正指示へ読み替えず、後続設計で成立性と実装への影響を明示する。

## Q1 CI実行先の具体化
CIは変更を契機に自動でビルド・試験する仕組み。どの方向で具体案を調べるか。

A. GitHubが用意するMacでの実行を調べる。対応OS/Xcode・料金・利用枠を確認し、追加課金しない設定を前提に具体案を示す。
B. 本人のMacで自動実行する案を調べる。専用環境の分離、実行中の負荷、写真へのアクセスを避ける条件と設定手順を示す。
X. Other (please specify)

[Answer]: A. GitHub提供Macを調査。GitHubのリポジトリはパブリックにした（本人申告、APIでもpublicを確認）。

## 調査結果と計画案
- 2026-11-04確認。GitHub APIでyokochie/hitotsuzuriのprivate=false、visibility=publicを確認。
- GitHub公式の標準runner一覧で、公開リポジトリの標準runnerは無料、arm64のxcode-27ラベルが対象と確認。macOS 27・Xcode 27を提供する一般提供済みイメージを使用する。xlarge等の大型runnerを使わない。
- 本人の現環境はmacOS 27.2 / Xcode 27.2 (27B52)。CIでは選択したXcodeとOSをログに記録し、必要SDKがなければ失敗させ、対応OSを無断変更しない。
- CIはpull_request、作業ブランチpush、手動起動で実行する。contents: read、秘密情報なし、合成fixtureのみ。pull_request_targetを使わない。個人写真・下書きを送信しない。
- 実行コマンド候補はbash scripts/verify-native.sh。現行はU1/U2/U3のXCTestとUIテスト、カバレッジ検査を実行する。Phase2の単体・統合・fixtureによる一連の操作試験を対象へ追加する。実写真・写真アプリ編集・Sandbox実保存・note受渡しは本人確認を別途必要とする。
- 有料runner・外部サービス・キャッシュ/成果物のアップロードを追加しない計画とし、まず標準runnerの実行ログで結果を残す。CI設定はU1の統合前に導入し、後続でも同じ試験を必須とする。CI成功を確認するまで統合しない。

根拠:
- https://docs.github.com/en/actions/reference/runners/github-hosted-runners
- https://github.blog/changelog/2026-10-15-xcode-27-runner-image-generally-available/
- https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md
- https://api.github.com/repos/yokochie/hitotsuzuri

## 検証コマンドの本人承認
`bash scripts/verify-native.sh`を全Unitの完了確認に使用する。本人がApproveを選択し、専用の回答記録と設定が成功した。実写真・Sandbox・noteの本人確認は別途必要。

## Consolidated Summary Confirmation
- 3回のBolt（動く成果物まで仕上げる実装）をU1→U2→U3の順で、1つずつ設計・実装・検証する。最小接続の早期実証を優先し、重み付きの順位採点は使わない。
- U1は記事開始・基本編集・手動保存・再開・実画像1枚出力。画像なしでも文章を再開でき、旧選択と正常な下書きを保護する。最初の実装が動いたことを本人に確認してから後続へ進む。
- U2は全編集欄・日付候補・撮影情報・下書き選択・再確定時の新規/再開・未保存離脱・狭幅/長文・プレビューを完成させる。
- U3は保存済み固定内容からの画像4枚・Markdown・manifestの一式、取消/失敗/復旧、本文コピーとFinderを完成させる。
- 実装はAI、実写真とnoteの確認・判断は本人。固定期限や他チーム待ちは設けず、CI利用可否と本人の実機確認を外部依存として扱う。
- TDD・製品全体80%以上の行カバレッジ・統合前CIを維持する。本人承認済みのbash scripts/verify-native.shへPhase2の試験を追加する。
- CIは公開リポジトリの標準xcode-27 runnerで実行する。PR/作業ブランチpush/手動起動、読取権限、秘密情報なし、合成データのみ。大型runnerや有料追加、写真/下書き送信、キャッシュ/成果物アップロードは追加しない。U1統合前からCI成功を必須とする。
- 実写真の編集・回転・色・位置情報除去・Sandbox・note手動受渡しは本人確認。VoiceOver追加検証なし。OS/Xcode/署名・起動・確認・戻し方を日本語で残す。
- 接続仕様で受容したR-01/R-02と保存/画像予算/異常終了回復の具体化事項を後続設計へ引き継ぎ、実装の成立性を確認する。各Unitの詳細コード計画は実装前に別途確認する。

Does this all look correct before I generate the artifact?

- Looks correct
- Request changes

[Answer]: Looks correct
