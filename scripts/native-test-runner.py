"""Shared execution and xcresult checks for the existing bash entry points."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from datetime import datetime
import uuid

CORE = ["ArticleInitialContentTests", "ArticleMetadataInputTests", "ArticleProjectionTests",
        "ArticleAssociationTests", "ArticleEntryTests", "ArticleNavigationTests",
        "ArticleDraftSessionTests", "ArticleOutputPreparationTests", "ArticlePreviewRetryTests",
        "ArticleDraftIntegrationTests"]
EXPORT_CORE = ["ArticleExportContractTests", "ArticleExportModelTests", "ArticleExportJournalTests",
               "ArticleExportWriterTests", "ArticleExportDeliveryTests", "ArticleExportSessionTests",
               "ArticleExportOSActionTests", "ArticleExportIntegrationTests"]
EXPORT_PERFORMANCE = ["HitotsuzuriU3Tests/ArticleExportIntegrationTests/"+name for name in [
    "testFourImageExportThirtyTrialsPerformance", "testExportMemoryAndCancellationThirtyTrials"]]
SMOKE = "FixtureSmokeUITests"
PERFORMANCE = "ArticleDraftPerformanceUITests"
UI_SHARDS = {
    "--ui-shard-article-edit-export": ("ArticleDraftUITests", "ArticleExportUITests", "ArticleCloudExportUITests"),
    "--ui-shard-navigation-photo-storage": ("NativeInputTests", "ArticlePhotoRestorationUITests",
                     "ArticleFoundationUITests", "ArticleSandboxStorageUITests"),
}
INPUT_FOCUS = [
    "HitotsuzuriUITests/NativeInputTests/testSingleTabFromAlbumOperatesPhotoAndShiftTabReturns",
    "HitotsuzuriUITests/NativeInputTests/testAlbumArrowsInCompactAfterMouseSelectionFollowPhotos",
]
INPUT_REGRESSION = INPUT_FOCUS + ["HitotsuzuriUITests/NativeInputTests/"+name for name in [
    "testCompactAlbumTabCanActivateEnabledConfirm",
    "testCompactConfirmShiftTabReturnsToAlbumRow",
    "testCompactPhotoTabCanActivateEnabledConfirm",
    "testCompactPhotoTabConfirmAndShiftTabReturnCanSave",
    "testPhotoTabWithEnabledConfirmCanSaveBySpace",
    "testTabReentryPreservesMultipleFoldersAlbumAndPhotoDraft",
]]
TARGETS = ["HitotsuzuriU1Tests", "HitotsuzuriU2Tests", "HitotsuzuriU3Tests", "HitotsuzuriUITests"]
CORE_PERFORMANCE = [
    "HitotsuzuriU1Tests/ArticleIntegrationTests/testLongTextSaveThirtySamples",
    "HitotsuzuriU1Tests/ArticleIntegrationTests/testColdOpenTenSamples",
    "HitotsuzuriU1Tests/ArticleIntegrationTests/testImageMemoryAndThirtyConversions",
    "HitotsuzuriU2Tests/ArticleDraftIntegrationTests/testLongDraftPersistenceAndProjectionPerformance",
    "HitotsuzuriU2Tests/ArticlePreviewRetryTests/testDisplayMemoryAndCancellationThirtyTrials",
]
CORE_PERFORMANCE += EXPORT_PERFORMANCE

def native_classes():
    values = {}
    for target in TARGETS:
        for path in Path(target).glob("*.swift"):
            text = path.read_text()
            if not re.search(r"func\s+test\w+\s*\(", text):
                continue
            for name in re.findall(r"class\s+(\w+)\s*:\s*(?:XCTestCase|ArticleDraftUITestCase)\b", text):
                values[name] = target
    return values

def check_result(result, expected, expected_cases=()):
    completed = subprocess.run(["xcrun", "xcresulttool", "get", "test-results", "tests", "--path", str(result)],
                               check=True, capture_output=True, text=True)
    document = json.loads(completed.stdout)
    passed = set()
    smoke_methods = set()
    passed_cases = set()
    count = 0
    def inspect(node, suite=""):
        nonlocal count
        name = node.get("name", "")
        if node.get("nodeType") == "Test Suite":
            suite = name
        if node.get("nodeType") == "Test Case":
            if node.get("result") != "Passed":
                raise ValueError("未成功/未実行の試験: "+suite+"/"+name)
            count += 1
            passed.add(suite)
            passed_cases.add(suite+"/"+name.removesuffix("()"))
            if suite == SMOKE:
                smoke_methods.add(name.removesuffix("()"))
        for child in node.get("children", []):
            inspect(child, suite)
    for node in document.get("testNodes", []):
        inspect(node)
    if count == 0 or not set(expected).issubset(passed):
        raise ValueError("指定クラスが未実行: "+", ".join(sorted(set(expected)-passed)))
    missing = {case.split("/",1)[1] for case in expected_cases} - passed_cases
    if missing:
        raise ValueError("指定試験が未実行: "+", ".join(sorted(missing)))
    if SMOKE in expected and not {"testArticleFixtureWindowAndEntryAreReady",
                                  "testPickerFixtureWindowAndFolderEntryAreReady"}.issubset(smoke_methods):
        raise ValueError("両fixture方式のsmokeが未実行")
    print(f"Verified {count} executed cases: {', '.join(expected)}", flush=True)

def run_group(prefix, filters, expected, expected_cases=()):
    base = Path(os.environ.get("HZS_RUNNER_RESULT_ROOT", ".build")).resolve()
    if not base.is_relative_to(Path(".build").resolve()):
        raise ValueError("result root must stay inside .build")
    base.mkdir(parents=True, exist_ok=True)
    result = base / (prefix+"-"+datetime.now().strftime("%Y%m%d-%H%M%S")+"-"+uuid.uuid4().hex+".xcresult")
    subprocess.run(["xcodebuild", "-project", "Hitotsuzuri.xcodeproj", "-scheme", "Hitotsuzuri",
                    "-destination", "platform=macOS", *filters, "-enableCodeCoverage", "YES",
                    "-derivedDataPath", ".build/DerivedData", "-resultBundlePath", str(result),
                    "CODE_SIGN_IDENTITY=-", "test"], check=True)
    check_result(result, expected, expected_cases)
    return result

def main():
    scope, *args = sys.argv[1:]
    all_classes = native_classes()
    if scope == "native" and len(args) == 1 and args[0] in UI_SHARDS:
        expected = {name for name, target in all_classes.items()
                    if target == "HitotsuzuriUITests" and name not in {SMOKE, PERFORMANCE}}
        assigned = [name for shard in UI_SHARDS.values() for name in shard]
        if len(assigned) != len(set(assigned)) or set(assigned) != expected:
            raise ValueError("UI分割に重複、未割当、または対象外のクラスがあります。")
        shard = UI_SHARDS[args[0]]
        run_group(args[0][2:], ["-only-testing:HitotsuzuriUITests/"+name for name in shard], shard)
        return
    allowed = {name:"HitotsuzuriU2Tests" for name in CORE}
    allowed.update({name:"HitotsuzuriUITests" for name in [SMOKE, "ArticleDraftUITests", PERFORMANCE]})
    if scope == "native":
        allowed = all_classes
    elif scope == "export":
        allowed = {name:"HitotsuzuriU3Tests" for name in EXPORT_CORE}
        allowed.update({SMOKE:"HitotsuzuriUITests", "ArticleExportUITests":"HitotsuzuriUITests"})
    mode = "all"
    selected = None
    if args:
        modes = ["--core", "--smoke", "--functional", "--performance"]
        if scope == "native":
            modes.extend(["--input-focus", "--input-regression"])
        if len(args) == 1 and args[0] in modes:
            mode = args[0][2:]
        elif all(name in allowed for name in args):
            selected = list(dict.fromkeys(args))
            mode = "selected"
        else:
            raise ValueError("未知または混在する試験区分/クラス")
    in_ci = os.environ.get("GITHUB_ACTIONS") == "true"
    if in_ci and (mode in ["all", "performance"] or PERFORMANCE in (selected or [])):
        raise ValueError("性能測定は本人Mac専用です。CIでは --core / --functional を指定してください。")
    performance_cases = [case for case in CORE_PERFORMANCE
                         if scope == "native" or case.startswith("HitotsuzuriU2Tests/")]
    if scope == "export":
        performance_cases = EXPORT_PERFORMANCE
    def core_group(performance_only=False):
        if performance_only:
            filters = ["-only-testing:"+case for case in performance_cases]
            expected = list(dict.fromkeys(case.split("/")[1] for case in performance_cases))
        else:
            expected = [name for name,target in allowed.items() if target != "HitotsuzuriUITests"]
            filters = (["-only-testing:"+target for target in TARGETS[:-1]] if scope == "native"
                       else ["-only-testing:"+allowed[name]+"/"+name for name in expected])
            filters.extend("-skip-testing:"+case for case in CORE_PERFORMANCE)
        return run_group(("Native" if scope == "native" else "Draft")+"-core", filters, expected,
                         performance_cases if performance_only else ())
    if mode == "core":
        core_group()
        print("Core専用: UIと製品全体のカバレッジは判定していません。", flush=True)
        return
    if scope == "export" and mode == "performance":
        core_group(performance_only=True)
        print("U3性能2件のみ: 全機能/製品全体カバレッジは判定していません。", flush=True)
        return
    # CIの同一commitのCore成功依存を使う。主bundleのCore機能試験は省かない。
    upstream_core = (mode != "all" and os.environ.get("GITHUB_ACTIONS") == "true"
                     and os.environ.get("HZS_CORE_PREFLIGHT_DONE") == "1")
    if selected is None and mode in ["all", "functional", "performance"] and not upstream_core:
        core_group(performance_only=mode == "performance")
    if mode == "all":
        core_group(performance_only=True)
    needs_smoke = selected is None or any(allowed[name] == "HitotsuzuriUITests" for name in selected)
    if needs_smoke:
        run_group("Smoke", ["-only-testing:HitotsuzuriUITests/"+SMOKE], [SMOKE])
    if mode == "smoke":
        return
    if mode in ["input-focus", "input-regression"]:
        cases = INPUT_FOCUS if mode == "input-focus" else INPUT_REGRESSION
        run_group("Native-"+mode, ["-only-testing:"+case for case in cases],
                  ["NativeInputTests"], cases)
        print(f"入力診断{len(cases)}件のみ: 全体成功/カバレッジの判定ではありません。", flush=True)
        return
    if selected is None:
        selected = list(allowed)
        if mode == "functional":
            selected = [name for name in selected if name not in [SMOKE, PERFORMANCE]]
        elif mode == "performance":
            selected = [PERFORMANCE]
        else:
            selected = [name for name in selected if name != SMOKE]
    else:
        selected = [name for name in selected if name != SMOKE]
        if not selected:
            return
    if not selected:
        raise ValueError("試験選択が0件")
    if scope == "native" and mode in ["all", "functional"]:
        filters = ["-only-testing:"+target for target in TARGETS]
        filters.append("-skip-testing:HitotsuzuriUITests/"+SMOKE)
        if mode == "functional":
            filters.append("-skip-testing:HitotsuzuriUITests/"+PERFORMANCE)
    else:
        filters = ["-only-testing:"+allowed[name]+"/"+name for name in selected]
    if mode in ["all", "functional"] or in_ci or scope == "export":
        # 実時間・実メモリの合否はMacの専用groupで確認する。
        filters.extend("-skip-testing:"+case for case in CORE_PERFORMANCE)
    result = run_group(("Native" if scope == "native" else "Draft")+"-"+mode, filters, selected)
    if scope == "native" and mode in ["all", "functional"]:
        # 全Core機能+全機能UIの単一bundleで全製品sourceの加重floorを判定。
        # 別に必須実行する性能計測のカバレッジ率を平均・合算しない。
        subprocess.run(["swift", "scripts/check-coverage.swift", str(result)], check=True)
        if mode == "functional":
            print("製品全体の行カバレッジを確認。詳細性能の成功は別に必要です。", flush=True)
    else:
        print("部分実行: 製品全体のカバレッジ/全体成功は判定していません。", flush=True)

if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        sys.exit(error.returncode or 1)
    except (ValueError, OSError, json.JSONDecodeError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(2)
