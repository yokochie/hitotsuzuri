# CI容量の条件

## Sources
`../../inception/requirements-analysis/requirements.md` FR4/NFR3/NFR4、`nfr-requirements-questions.md`、`aidlc/spaces/default/codekb/hitotsuzuri/technology-stack.md`。

## Requirements
- **NFR4.1** runner台数・同時実行枠・共有利用が未確認の段階では増加を前提としない。並列化する場合は同時実行数、CPU/メモリ、UIセッション、作業領域の競合を調査して上限を設計する。
- **NFR4.2** 複数runが重なってもDerivedData、xcresult、試験用領域を混ぜず、同一refの古いrunの取消方針を保つ。未実行・中断したrunを完了と扱わない。

## Capacity boundary
固定の台数、増設、自動スケール、月間run数は決定していない。現状調査後に必要な変更範囲を本人と決める。アプリ利用者数の増加やクラウド容量設計は今回対象外。
