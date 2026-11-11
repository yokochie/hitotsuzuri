# 計測と結果の記録

## Sources
`../../inception/requirements-analysis/requirements.md` FR1/FR2/FR6/NFR1、`performance-requirements.md`、`aidlc/spaces/default/codekb/hitotsuzuri/technology-stack.md`。

## Requirements
- **NFR1.7** run/attempt、commit、PR更新・開始・完了時刻、結果、runner/toolchain、試験集合、キャッシュ条件、取得できる区間時間を紐付ける。時刻はUTCまたはoffset付き、所要時間は秒。不明は明記する。
- **NFR1.8** 前後の全標本と中央値、30%判定、除外記録、待機と実行の内訳、未確認を日本語で示す。異常値も消さず、除外理由を示す。過去ログの欠損から推測値を作らない。
- **NFR1.9** 30%未達、品質不合格、標本不足は別々に表示する。新しい常設dashboard・外部通知・有料監視は導入せず、既存Actions表示とプロジェクト内記録を使う。
