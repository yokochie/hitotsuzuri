# U1 機能設計の確認

## 入力と確認範囲

[実装単位](../../../inception/units-generation/unit-of-work.md)、[ストーリー割当](../../../inception/units-generation/unit-of-work-story-map.md)、[受け入れ条件](../../../inception/user-stories/stories.md)、[要件](../../../inception/requirements-analysis/requirements.md)、[構成要素](../../../inception/domain-design/components.md)、[内部契約](../../../inception/contract-design/contract-summary.md)を引き継ぐ。

既存の回答で製品の動作は確定しており、新しい製品判断を求める質問はない。5構成要素を空・境界値・同名異ID・遅延応答・外部変更・書込み失敗の観点で確認した。確定済みの動作は再質問せず、下記の範囲を設計へ落とし込む。画像の具体的品質・待機上限、資源上限と実行境界は後続の技術設計で決定し、実装開始前に揃える。

## Consolidated Summary Confirmation

- U1は実ライブラリの許可、複数フォルダの再帰探索、1アルバムの写真閲覧、順序付き4枚選択、検証後の保存までを一通り動かす。
- 名称ではなくIDで区別し、親子フォルダの同時選択は重複排除する。動画を除外して写真のアルバム内順序を保つ。写真アプリとの並びの一致は実機で確認する。
- 通信を要求せず、取得不可の写真は選択できない。5枚目は禁止し、解除後は番号を詰め、再選択は末尾へ追加する。
- 検証・保存中は編集と重複確定を禁止する。固定した4枚の参照・所属・画像可否を検証し、保存完了後だけ成功を表示する。失敗時は以前の確定内容と編集内容を保つ。
- U1で保存の基礎と安全性を備え、復元と異常系の完全化はU2、最終画面・操作支援・性能の受け入れはU3で完成させる。後続単位の条件をU1で達成済みとは扱わない。
- 自動テストと本人の実機確認を分け、具体的な検証コマンドは最初の実装単位の検証前に確認する。

Does this all look correct before I generate the artifact?

- Looks correct
- Request changes

[Answer]: Looks correct
