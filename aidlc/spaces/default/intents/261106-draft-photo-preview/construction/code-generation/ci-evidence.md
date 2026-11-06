# 画像表示復帰のCI証拠

## 変更前の基準

- コミット: d3feef45fe647eea80261d9f04bfc80123cdfa69。
- CI: https://github.com/yokochie/hitotsuzuri/actions/runs/42030797393 （push、success）。
- native-core job127256435543: success。runner契約Python28件成功（7.187秒）。Core460件成功。
- native job127257687149: success。起動smoke2件、全機能524件（Core460 + UI64）が成功。全製品5284/5798行、91.13%。
- 同SHAのPR run42030806045はcancelled。これを成功根拠にはしない。

2026-11-06にrun metadataと両jobのログを読み取った。新しいCI、ローカルbuild/native/UIを起動していない。計画作成前にApp/Core/各Tests/scripts/.githubのソースがd3feef4と一致することをgit diff --quietで確認（終了0）。e6111daは調査/要件等の記録のみ。

## 今回のRed / Green

未実施。テスト追加後の意図した失敗と修正後の成功は、実際のCIを観測して追記する。変更前の成功を今回の回帰再現・修正成功へ代用しない。
