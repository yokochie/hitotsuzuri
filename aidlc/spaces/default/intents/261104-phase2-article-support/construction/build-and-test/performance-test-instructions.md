# Performance Test Instructions

## 方針
性能合否は本人Macのみ。CIは期限・予約・単一終端・取消/失敗など決定論的機能を確認する。成功済みで処理が変わっていない測定は反復せず、変更が関係する項目だけをまとめる。未確認をCI成功で補わない。

## 既存の測定証拠
U1/U2はconstruction/u2-draft-experience/code-generation/tdd-evidence.mdのCore5件とUI4件。U3はconstruction/u3-article-export/code-generation/performance-evidence.mdの新規2件と片付け関連1メソッド更新。環境・全試行・p95・最大・baseline・実観測間隔を保持する。

## 必要時だけ使うコマンド
bash scripts/verify-native.sh --performance（U1/U2の既存性能）、bash scripts/verify-article-export.sh --performance（U3の2件）。ローカルUIを含む実行は本人の明示依頼/承認がある場合に限定する。今回は成功済みの同目的の実行を追加しない。

## 条件
100記事/対象1000操作、名称200文字/各本文10000文字、保存/再開30回p95≤2秒、投影100回p95≤100ms、文字切替30回p95≤0.5秒、cold10別プロセスはApp.init以降を明示。U3は4096×3072 JPEG4枚、正常先30回p95≤10秒、取消片付け30回p95≤5秒。画像直接256MiB、増分512MiB、baseline5秒以上、実観測間隔50ms以下を維持する。

## 未確認を一度の実機機会へまとめる項目
最小640×560ptの内容領域と全操作、実写真の取得時間/現在編集・回転・色/GPS除去、実Sandbox/保存先/Finder/note、取消受理の実画面表示0.5秒、U1一枚出力の実工程10秒/全体40秒の測定証拠。制御受付時間を実描画時間と同一視しない。OS lifetime peakは保守的上界と当該区間への帰属を分け、OS bootstrap/cache coldの未測定を消さない。
