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

### 観測修復後の対象限定CI（有効なRed）

- コミットd45acb74a7c8f48db690a10880bf5aa984c3aab2。
- CI https://github.com/yokochie/hitotsuzuri/actions/runs/42171059895 、job127738722780、6分33秒、exit65。
- 起動smoke2件成功、新UI10件は3成功・7失敗（279.881秒）。
- 対照T1（fresh下書き再開）、T9（マウス/キーで番号別再試行）、T10（遅い旧応答の排除/不要保持解放）は成功。
- T2正常出力、T5保存先取消、T6容量拒否、T7保存失敗、T8入力検証失敗の5件は、出力終端後に `owner=false;imageBusy=false;pixels=none,none,none,none;entered=1` の状態で4枚のready/要求再開を待って失敗。通常復帰ロジックは未修正で、目的の表示欠落を再現した有効なRedとする。
- T3出力画像失敗はAX snapshotの取得エラー、T4取消はbusy中のメッセージ待ちtimeout。両者は有効なRed5件と区別し、修復してから成功を確認する。

修復したfixtureはrestore-*の場合だけPickerの検証用adapterを分け、記事driverの要求/保留とcacheを独立観測する。通常App/既存fixtureの共有構成は変更しない。この新classはPicker共有時の相互作用を証明せず、既存の共有資源試験/既存UIと本人確認を併用する。

全機能CIを繰り返す負担を減らすため、一時的なmarker限定 `diagnose-photo-restoration.yml` で承認計画の対象指定コマンドを実行した。同SHAの通常full runs42171059761/42171064663は取消を要求した。これらを成功証拠にはしない。Greenを対象限定で確かめた後は一時workflowを削除し、通常の全Core→smoke→全機能/80%検査を通す。最終CIの条件を省略しない。
