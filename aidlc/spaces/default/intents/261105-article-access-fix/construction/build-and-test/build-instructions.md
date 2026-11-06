# 記事アクセス修正のビルド・検証手順

## Inputs
変更範囲は `../code-generation/code-generation-plan.md`、対象試験と正確な部分実行は `../code-generation/unit-test-instructions.md`、実装内容と本人確認は `../code-generation/code-summary.md` を参照する。

## Environment and Dependencies
第三者依存や新しいサービスは追加しない。既存Xcode project・XCTest/XCUITest・Python3・bash・Swift coverage scriptを使う。成功CIはxcode-27-arm64 / macOS27.0.1(26A434) / Xcode27.1(27A9275) / SDKmacOS27.0 / VirtualMac2,1 / arm64。署名は既存runnerのCODE_SIGN_IDENTITY=-、App Sandboxと既存entitlementsを維持する。

## Build and Test Route
既存 `.github/workflows/verify.yml` が以下を実行する。これは同一製品ソース88978d6で完了済み。結果を採用する本段階では再起動しない。

1. `python3 scripts/test-native-runner.py`（選択契約）。
2. `bash scripts/verify-native.sh --core`（Core機能）。
3. 2の成功後、`HZS_CORE_PREFLIGHT_DONE=1`の既存CI環境で `bash scripts/verify-native.sh --functional`（smoke、全Core＋全機能UIの主bundle、全製品coverage）。
4. runner内部のxcodebuildはHitotsuzuri project/scheme、platform=macOS、coverage=YES、.build/DerivedData、UUID付きxcresult、CODE_SIGN_IDENTITY=-でtestする。これが製品と試験のコンパイルも検証する。
5. `swift scripts/check-coverage.swift <主bundle>`をrunnerが実行し、全手書きApp/Core sourceを対象に80%以上を判定する。部分率の合算や別bundleの平均は使わない。

再現用の部分コマンドは上流のunit-test-instructionsにある。CIですでに当該ケースが成功している場合は同じ目的のローカルnative/UI/性能を実行しない。新たなソース変更・失敗・未解決の懸念がある場合だけ、該当する検証をやり直す。

## Current Result Verification
この段階で実行するのは次の読取確認。CIを新しくdispatch/rerunする操作ではない。

```bash
git diff --quiet 88978d6fbac624961c3880ac894facf1c0070469 -- Hitotsuzuri HitotsuzuriCore HitotsuzuriU1Tests HitotsuzuriU2Tests HitotsuzuriU3Tests HitotsuzuriUITests scripts .github
```

```bash
gh run view 42022838099 --repo yokochie/hitotsuzuri --json headSha,status,conclusion,jobs
```

両方がexit0、headShaが88978d6、status completed/conclusion successであることを確認する。jobの完了ログと結果はtest-results.mdへ記録する。本人の既存schemeのRun引数差分は保持されており、今回の製品修正にもCI設定変更にも含めていない。

## Normal Launch and Troubleshooting
本人の通常起動はXcodeでprojectを開き、scheme Hitotsuzuri / My Macから実行する。試験用引数・fixture環境変数を追加しない。操作確認の一連の手順はcode-summary.mdにまとめている。

Swiftコンパイルエラー、Xcode/SDKの不一致、fixtureの権限条件不成立、cleanup失敗は成功やskipへ置換せず原因を調べる。通常記事でエラーが残る場合はデータを削除せず操作と表示文言を記録し、Deployment Executionで切り分ける。OS権限リセットやSandbox解除を自動実行しない。

## Cleanup
CIは合成データのUUID領域だけを片付ける。ローカルのPython確認でできた空.buildは削除済み、default.profrawも不在。過去のローカルxcresultは復元していない。本人の保存領域や実写真は掃除しない。

