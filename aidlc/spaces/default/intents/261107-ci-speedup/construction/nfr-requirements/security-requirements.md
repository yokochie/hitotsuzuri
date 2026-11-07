# CIの保護条件

## Sources
`../../inception/requirements-analysis/requirements.md` NFR3/FR4、`../../inception/practices-discovery/evidence.md`、`aidlc/spaces/default/codekb/hitotsuzuri/technology-stack.md`。

## Requirements
- **NFR3.1** 既存のcontents読取権限、checkout認証情報非保持、Actions依存のcommit固定を維持し、高速化を理由に権限を増やさない。差分点検で確認する。
- **NFR3.2** 秘密情報、実写真、個人の記事をログ・キャッシュ・成果物へ追加しない。合成試験データと必要な計測情報だけを扱う。キャッシュ採用時は保存対象・信頼境界を設計し、信頼できないPRの成果を信頼する実行の検証済み成果として扱わない。
- **NFR3.3** 新たな有料ツール・サービスを前提にせず、費用不明を無料と断定しない。runner台数、共有状況、同時実行枠、費用・権限を調べ、変更が必要なら本人の判断を得る。

## Threat considerations
不正なキャッシュからの誤成功、共有作業領域の汚染、成果物への情報混入、不要な権限拡大を点検する。独自認証・外部backend・新たな規制適合認証は対象外。調査できないアカウント情報は未確認と報告する。
