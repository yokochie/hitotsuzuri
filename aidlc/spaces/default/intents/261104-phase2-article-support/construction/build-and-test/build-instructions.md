# Build Instructions

## 対象と環境
既存macOSネイティブアプリ、Swift 6、macOS27対象、Xcode27。候補4a3b71d1e15795fedcba4e8a808addfff3ef2308。第三者package導入、クラウド配置、配布は追加しない。本人の共有scheme差分は保持する。

## 今回の確認方法
本人e97e172fのCI優先方針と0c6f9332のコマンド変更承認に従う。同じソースのローカルUI全体を繰り返さず、現在HEAD・製品/試験/runner/workflowの未コミット差分なし・成功済みCIを確認する。

```bash
bash aidlc/spaces/default/intents/261104-phase2-article-support/verification-command.txt
```

ファイル内の承認済み1行がHEADを固定SHAと照合し、git diffで指定範囲の差分を拒否してから、gh run watch 41994393925 --repo yokochie/hitotsuzuri --exit-statusで完了結果を確認する。コード変更後や別SHAに流用しない。記録だけの変更で再テストを要求しない。

## CIで実際に使ったビルドと試験
.github/workflows/verify.ymlのnative-core→native。python3 scripts/test-native-runner.py、bash scripts/verify-native.sh --core、bash scripts/verify-native.sh --functional。macOS27.0.1/Xcode27.1のxcode-27、contents:read、ad-hoc CODE_SIGN_IDENTITY=-。主bundleは全Core機能と全機能UI、別smoke2件を先行する。ビルドは各xcodebuild testに含まれる。

## 本人が起動するとき
XcodeでHitotsuzuri.xcodeprojを開きHitotsuzuri scheme/My Macを選択する。写真アクセス・保存先の操作は本人が行う。CI合成fixtureの起動成功を実写真/実Sandboxの確認へ広げない。詳細は各Unitのuser-verification.md。

## 問題時
HEADや差分が一致しなければ既存CIを現候補の証拠にしない。新しい候補のCIで検証する。UI認証/TCC/キーボード設定は自動変更しない。容量/権限/不明結果は既存下書き・完成物・未完記録を保護し、無関係なデータを回収しない。
