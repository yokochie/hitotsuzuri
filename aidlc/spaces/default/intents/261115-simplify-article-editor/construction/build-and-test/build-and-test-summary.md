# ビルドとテストの概要

macOS 27.2.1、Xcode 27.2でアプリをビルドした。修正後はCore事前チェック、UIスモーク2件、全機能試験566件がすべて成功した。ローカルの機能検証と行カバレッジの条件を満たした。

## Target Verification Matrix

| Target ID | Source | Expected | Actual | Evidence | Owning Stage | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| NFR1 | 要件書、チームの Testing Posture | 製品の行カバレッジ80%以上 | 5866/6379行（91.96%） | `Native-functional-20261115-195825-1695ec17575842b28c26bfd171fa622d.xcresult` | build-and-test | Met |
| NFR1-CI | 要件書、Testing Contract | 統合前CI | この計画にCI Pipeline段階がない。GitHub Actionsは未実行 | `.github/workflows/verify.yml` | ci-pipeline | N/A |

既存のプロジェクトCIの条件は引き続き適用する。実写真を使う実機確認は未実施。
