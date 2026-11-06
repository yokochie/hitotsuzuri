# 画像表示復帰のCI証拠

## 変更前の基準

- コミット: d3feef45fe647eea80261d9f04bfc80123cdfa69。
- CI: https://github.com/yokochie/hitotsuzuri/actions/runs/42030797393 （push、success）。
- native-core job127256435543: success。runner契約Python28件成功（7.187秒）。Core460件成功。
- native job127257687149: success。起動smoke2件、全機能524件（Core460 + UI64）が成功。全製品5284/5798行、91.13%。
- 同SHAのPR run42030806045はcancelled。これを成功根拠にはしない。

2026-11-06にrun metadataと両jobのログを読み取った。新しいCI、ローカルbuild/native/UIを起動していない。計画作成前にApp/Core/各Tests/scripts/.githubのソースがd3feef4と一致することをgit diff --quietで確認（終了0）。e6111daは調査/要件等の記録のみ。

## 今回のRed / Green

### 最初の回帰試験実行（有効なRed未取得）

- コミットf912576c7ebf9dcac6855a03f2798b241ab0d3a5、CI42167693848（push）。
- Core job127727889551成功。native job127728593017は26分36秒でexit65。
- 起動smoke2件、既存Core460件と既存UI64件は成功。新ArticlePhotoRestorationUITestsの10件は失敗。
- T1–T8は初期表示を確認するhelperの45行でStaticText.labelが空となり失敗。owner/pixel/要求数と実画像要素の初期条件を通った後の観測不備で、出力後の欠落まで到達していない。
- T9は初回要求と再試行有効状態、T10は初回保留応答数の待機でtimeout。診断が足りず、これらを製品の再現成功と扱わない。
- T4には別途、Deliveryが実画像処理終了を待つのに応答を返す前にendedを待つ手順不備も静的に見つかった。初回CIではそこまで到達していない。

現在はテスト/fixtureの観測と手順を修復する。通常の表示復帰ロジックは未変更。有効な意図した失敗を再観測してからGreenに進む。変更前の成功や試験準備の失敗を修正根拠へ代用しない。
