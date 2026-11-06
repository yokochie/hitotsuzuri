# 利用場面と実装単位の対応

入力：`../user-stories/stories.md`、`../requirements-analysis/requirements.md`、`../domain-design/components.md`・`decisions.md`、`unit-of-work.md`。複数単位の行は、各単位がその場面の一部を実装することを示す。各Functional Designは行の全ACを列挙し、自身の担当・依存先の担当・非該当理由を区別して欠落させない。

| 利用場面 | Unit ID | Directory | 実装部分 |
|---|---|---|---|
| US1.1 | U1; U2 | u1-article-foundation; u2-draft-experience | U1は基本開始と記事識別、U2は入口2か所・候補・再確定選択の完成 |
| US1.2 | U1; U2 | u1-article-foundation; u2-draft-experience | U1は独立保存・基本編集/再開、U2は全欄・競合と状態表示の完成 |
| US1.3 | U1; U2 | u1-article-foundation; u2-draft-experience | U1は最小画面の未保存保護、U2は全離脱経路・焦点・複数対象の完成 |
| US1.4 | U1; U2; U3 | u1-article-foundation; u2-draft-experience; u3-article-export | U1は文章再開と通信禁止、U2は取得不能の編集UI、U3は4枚出力の終端・再試行 |
| US1.5 | U2 | u2-draft-experience | 日付候補、撮影情報、初期内容、保存復元の完成 |
| US1.6 | U2; U3 | u2-draft-experience; u3-article-export | U2は画面・プレビュー・本文投影、U3はOSコピーと成功表示の接続 |
| US1.7 | U1; U2; U3 | u1-article-foundation; u2-draft-experience; u3-article-export | U1は実画像1枚の取得/出力基礎、U2は保存操作/投影、U3は一式出力・manifest・取消/失敗/復旧 |
| US1.8 | U3 | u3-article-export | Finder、コピー済み本文と4枚のnote受渡し、実機確認記録 |

## 単位内の実装・試験の進め方
U1は既存読込と正本保護のfixture、基本記事保存/再開、最小画面、実画像1枚と保存先接続を各層のTDDでつなぐ。U2は入力規則・本文投影・保存と再開の操作・配置/キー到達を各層のTDDで完成させる。U3は固定入力と成果物の整合、失敗/取消・片付け、OS受渡しの接続を各層のTDDで完成させる。これは単位内の依存に沿う説明で、単位間の経済的な優先順位や日程は決めない。

## Coverage
US1.1〜US1.8の8行を全て割当て、U1/U2/U3の全単位に実装する場面がある。NFR1〜NFR7は各場面の受け入れ条件と共通品質を通じて引き継ぎ、期限/予算・CI等の未決定を実装前に具体化する。詳細は`traceability.json`と各設計のAC対応へつなぐ。
