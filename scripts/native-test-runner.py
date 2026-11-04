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
SMOKE = "FixtureSmokeUITests"
PERFORMANCE = "ArticleDraftPerformanceUITests"
TARGETS = ["HitotsuzuriU1Tests", "HitotsuzuriU2Tests", "HitotsuzuriU3Tests", "HitotsuzuriUITests"]

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

def check_result(result, expected):
    completed = subprocess.run(["xcrun", "xcresulttool", "get", "test-results", "tests", "--path", str(result)],
                               check=True, capture_output=True, text=True)
    document = json.loads(completed.stdout)
    passed = set()
    smoke_methods = set()
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
            if suite == SMOKE:
                smoke_methods.add(name.removesuffix("()"))
        for child in node.get("children", []):
            inspect(child, suite)
    for node in document.get("testNodes", []):
        inspect(node)
    if count == 0 or not set(expected).issubset(passed):
        raise ValueError("指定クラスが未実行: "+", ".join(sorted(set(expected)-passed)))
    if SMOKE in expected and not {"testArticleFixtureWindowAndEntryAreReady",
                                  "testPickerFixtureWindowAndFolderEntryAreReady"}.issubset(smoke_methods):
        raise ValueError("両fixture方式のsmokeが未実行")
    print(f"Verified {count} executed cases: {', '.join(expected)}", flush=True)

def run_group(prefix, filters, expected):
    base = Path(os.environ.get("HZS_RUNNER_RESULT_ROOT", ".build")).resolve()
    if not base.is_relative_to(Path(".build").resolve()):
        raise ValueError("result root must stay inside .build")
    base.mkdir(parents=True, exist_ok=True)
    result = base / (prefix+"-"+datetime.now().strftime("%Y%m%d-%H%M%S")+"-"+uuid.uuid4().hex+".xcresult")
    subprocess.run(["xcodebuild", "-project", "Hitotsuzuri.xcodeproj", "-scheme", "Hitotsuzuri",
                    "-destination", "platform=macOS", *filters, "-enableCodeCoverage", "YES",
                    "-derivedDataPath", ".build/DerivedData", "-resultBundlePath", str(result),
                    "CODE_SIGN_IDENTITY=-", "test"], check=True)
    check_result(result, expected)
    return result

def main():
    scope, *args = sys.argv[1:]
    all_classes = native_classes()
    allowed = {name:"HitotsuzuriU2Tests" for name in CORE}
    allowed.update({name:"HitotsuzuriUITests" for name in [SMOKE, "ArticleDraftUITests", PERFORMANCE]})
    if scope == "native":
        allowed = all_classes
    mode = "all"
    selected = None
    if args:
        if len(args) == 1 and args[0] in ["--smoke", "--functional", "--performance"]:
            mode = args[0][2:]
        elif all(name in allowed for name in args):
            selected = list(dict.fromkeys(args))
            mode = "selected"
        else:
            raise ValueError("未知または混在する試験区分/クラス")
    needs_smoke = selected is None or any(allowed[name] == "HitotsuzuriUITests" for name in selected)
    if needs_smoke:
        run_group("Smoke", ["-only-testing:HitotsuzuriUITests/"+SMOKE], [SMOKE])
    if mode == "smoke":
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
    result = run_group(("Native" if scope == "native" else "Draft")+"-"+mode, filters, selected)
    if scope == "native" and mode == "all":
        # 単一の全対象bundleへ既存の製品加重checkerを適用。率の平均や対象除外はしない。
        subprocess.run(["swift", "scripts/check-coverage.swift", str(result)], check=True)
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
