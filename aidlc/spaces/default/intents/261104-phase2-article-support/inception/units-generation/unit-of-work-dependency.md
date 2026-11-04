# Phase2 実装単位の依存

入力：`unit-of-work.md`、`../domain-design/components.md`・`decisions.md`、`../requirements-analysis/requirements.md`、`../user-stories/stories.md`。本書はビルド・試験の依存を示し、経済的な実装順序やクリティカルパスを選ぶものではない。

```yaml
units:
  - name: u1-article-foundation
    kind: service
    depends_on: []
  - name: u2-draft-experience
    kind: ui
    depends_on: [u1-article-foundation]
  - name: u3-article-export
    kind: library
    depends_on: [u1-article-foundation, u2-draft-experience]
```

| 依存する単位 | 依存先 | 必要な接続 |
|---|---|---|
| U2 | U1 | 記事ID・保存リビジョン、既存選択読込、記事保存・再開、最小編集状態、画像取得契約 |
| U3 | U1 | 記事用画像・出力先アクセスの基礎、固定保存内容とジョブ識別の契約 |
| U3 | U2 | 完成した本文/撮影メモ投影、保存前確認と編集状態、出力・コピーの画面接続 |

U1は既存コードと自身の実装だけで実行し、後続を待たず記事開始・基本保存/再開・実画像1枚の保存先出力を確認する最小統合単位。U1の実証を設計文書だけで代替しない。後続が未実装でもU1のビルド・試験を成立させる。

循環・自己依存・未宣言参照はない。U2/U3は独立単位ではなく依存があるため、この分割に同時開発可能な単位の組はない。成果物を別配布する意味での独立性は要求せず、依存先だけを入れた作業環境でビルド・試験できることを要求する。実際の作業・検証・本人確認の順序はDelivery Planningが決める。
