"""Short isolated runner contracts; never starts Xcode or touches user fixtures."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent

class RunnerContractTests(unittest.TestCase):
    def setUp(self):
        (ROOT / ".build").mkdir(exist_ok=True)
        self.directory = tempfile.TemporaryDirectory(prefix="runner-contract-", dir=ROOT / ".build")
        self.base = Path(self.directory.name)
        self.log = self.base / "calls.jsonl"
        fake = '''#!/usr/bin/env python3
import json, os, pathlib, sys
name=pathlib.Path(sys.argv[0]).name
with open(os.environ["CONTRACT_LOG"],"a") as f: f.write(json.dumps([name]+sys.argv[1:])+"\\n")
if name=="xcodebuild":
    if os.environ.get("CONTRACT_CORE_FAIL")=="1" and any("HitotsuzuriU" in x and "Tests" in x for x in sys.argv) and not any("HitotsuzuriUITests" in x for x in sys.argv): sys.exit(65)
    if os.environ.get("CONTRACT_SMOKE_FAIL")=="1" and any("FixtureSmokeUITests" in x for x in sys.argv): sys.exit(65)
    result=sys.argv[sys.argv.index("-resultBundlePath")+1]
    pathlib.Path(result).mkdir(parents=True)
    pathlib.Path(result,"selection.json").write_text(json.dumps(sys.argv[1:]))
elif name=="xcrun":
    result=sys.argv[sys.argv.index("--path")+1]
    args=json.loads(pathlib.Path(result,"selection.json").read_text())
    names=[]
    methods={}
    import re
    skipped={x.split("/")[-1] for x in args if x.startswith("-skip-testing:")}
    for arg in args:
        if not arg.startswith("-only-testing:"): continue
        selection=arg.split(":",1)[1]
        if "/" in selection:
            parts=selection.split("/")
            names.append(parts[1])
            if len(parts)==3: methods.setdefault(parts[1],[]).append(parts[2]+"()")
        else:
            for file in pathlib.Path(selection).glob("*.swift"):
                text=file.read_text()
                if re.search(r"func\\s+test\\w+\\s*\\(",text):
                    names.extend(re.findall(r"class\\s+(\\w+)\\s*:\\s*(?:XCTestCase|ArticleDraftUITestCase)\\b",text))
    names=list(dict.fromkeys(n for n in names if n not in skipped))
    if os.environ.get("CONTRACT_ZERO")=="1": names=[]
    if os.environ.get("CONTRACT_OMIT_PERFORMANCE")=="1":
        methods.get("ArticleIntegrationTests",[]).remove("testColdOpenTenSamples()")
    print(json.dumps({"testNodes":[{"nodeType":"Test Suite","name":n,"result":"Passed","children":[{"nodeType":"Test Case","name":method,"result":"Passed"} for method in (["testArticleFixtureWindowAndEntryAreReady()","testPickerFixtureWindowAndFolderEntryAreReady()"] if n=="FixtureSmokeUITests" else methods.get(n,["testOne()"]))]} for n in names]}))
'''
        for name in ["xcodebuild", "xcrun", "swift"]:
            path = self.base / name
            path.write_text(fake)
            path.chmod(0o700)
        self.env = dict(os.environ, PATH=str(self.base)+os.pathsep+os.environ["PATH"], CONTRACT_LOG=str(self.log), HZS_RUNNER_RESULT_ROOT=str(self.base), HZS_CORE_PREFLIGHT_DONE="0", GITHUB_ACTIONS="false")
    def tearDown(self): self.directory.cleanup()
    def run_script(self, *args, script="verify-draft-experience.sh", **env):
        return subprocess.run(["bash", "scripts/"+script, *args], cwd=ROOT, env=dict(self.env, **env), capture_output=True, text=True)
    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []
    def test_smoke_is_accepted_and_only_runs_smoke(self):
        result=self.run_script("--smoke")
        self.assertEqual(result.returncode,0,result.stderr)
        calls=[c for c in self.calls() if c[0]=="xcodebuild"]
        self.assertEqual(len(calls),1)
        self.assertIn("-only-testing:HitotsuzuriUITests/FixtureSmokeUITests",calls[0])
    def test_smoke_failure_stops_functional(self):
        self.assertNotEqual(self.run_script("--functional",CONTRACT_SMOKE_FAIL="1").returncode,0)
        self.assertEqual(len([c for c in self.calls() if c[0]=="xcodebuild"]),2)
    def test_zero_executed_is_rejected(self):
        self.assertNotEqual(self.run_script("--smoke",CONTRACT_ZERO="1").returncode,0)
    def test_unknown_argument_is_rejected_before_execution(self):
        self.assertNotEqual(self.run_script("--unknown").returncode,0)
        self.assertEqual(self.calls(),[])
    def test_functional_excludes_performance(self):
        self.assertEqual(self.run_script("--functional").returncode,0)
        calls=[c for c in self.calls() if c[0]=="xcodebuild"]
        self.assertEqual(len(calls),3)
        self.assertIn("-only-testing:HitotsuzuriUITests/ArticleDraftUITests",calls[-1])
        self.assertNotIn("-only-testing:HitotsuzuriUITests/ArticleDraftPerformanceUITests",calls[-1])
    def test_performance_and_class_selection(self):
        self.assertEqual(self.run_script("--performance").returncode,0)
        calls=[c for c in self.calls() if c[0]=="xcodebuild"]
        self.assertIn("-only-testing:HitotsuzuriUITests/ArticleDraftPerformanceUITests",calls[-1])
        self.assertNotIn("-only-testing:HitotsuzuriUITests/ArticleDraftUITests",calls[-1])
        self.assertEqual(self.run_script("ArticleMetadataInputTests").returncode,0)
        calls=[c for c in self.calls() if c[0]=="xcodebuild"]
        self.assertEqual([x for x in calls[-1] if x.startswith("-only-testing:")],["-only-testing:HitotsuzuriU2Tests/ArticleMetadataInputTests"])
    def test_all_includes_every_draft_class(self):
        self.assertEqual(self.run_script().returncode,0)
        calls=[c for c in self.calls() if c[0]=="xcodebuild"]
        self.assertEqual(len(calls),4)
        self.assertIn("-only-testing:HitotsuzuriUITests/ArticleDraftPerformanceUITests",calls[-1])
    def test_native_all_retains_all_targets_and_single_coverage_bundle(self):
        self.assertEqual(self.run_script(script="verify-native.sh").returncode,0)
        calls=[c for c in self.calls() if c[0]=="xcodebuild"]
        self.assertEqual(len(calls),4)
        for target in ["HitotsuzuriU1Tests","HitotsuzuriU2Tests","HitotsuzuriU3Tests","HitotsuzuriUITests"]:
            self.assertIn("-only-testing:"+target,calls[-1])
        coverage=[c for c in self.calls() if c[0]=="swift"]
        self.assertEqual(len(coverage),1)
        self.assertEqual(coverage[0][1],"scripts/check-coverage.swift")
    def test_core_failure_stops_before_any_ui(self):
        result=self.run_script("--functional",script="verify-native.sh",CONTRACT_CORE_FAIL="1")
        self.assertNotEqual(result.returncode,0)
        calls=[c for c in self.calls() if c[0]=="xcodebuild"]
        self.assertEqual(len(calls),1)
        self.assertFalse(any("HitotsuzuriUITests" in x for x in calls[0]))
    def test_core_mode_runs_no_ui_and_no_partial_coverage_claim(self):
        result=self.run_script("--core",script="verify-native.sh")
        self.assertEqual(result.returncode,0,result.stderr)
        calls=[c for c in self.calls() if c[0]=="xcodebuild"]
        self.assertEqual(len(calls),1)
        self.assertFalse(any("HitotsuzuriUITests" in x for x in calls[0]))
        self.assertFalse(any(c[0]=="swift" for c in self.calls()))
    def test_native_functional_checks_whole_product_coverage(self):
        result=self.run_script("--functional",script="verify-native.sh")
        self.assertEqual(result.returncode,0,result.stderr)
        calls=[c for c in self.calls() if c[0]=="xcodebuild"]
        self.assertTrue(all(any(target in x for x in calls[0]) for target in ["HitotsuzuriU1Tests","HitotsuzuriU2Tests","HitotsuzuriU3Tests"]))
        coverage=[c for c in self.calls() if c[0]=="swift"]
        self.assertEqual(len(coverage),1)
        self.assertIn("-skip-testing:HitotsuzuriU2Tests/ArticlePreviewRetryTests/testDisplayMemoryAndCancellationThirtyTrials",calls[-1])
    def test_ci_dependency_skips_only_duplicate_core_preflight(self):
        result=self.run_script("--functional",script="verify-native.sh",GITHUB_ACTIONS="true",HZS_CORE_PREFLIGHT_DONE="1")
        self.assertEqual(result.returncode,0,result.stderr)
        calls=[c for c in self.calls() if c[0]=="xcodebuild"]
        self.assertEqual(len(calls),2)
        self.assertIn("-only-testing:HitotsuzuriU2Tests",calls[-1])
        self.assertEqual(len([c for c in self.calls() if c[0]=="swift"]),1)
    def test_core_zero_execution_stops_before_ui(self):
        self.assertNotEqual(self.run_script("--functional",CONTRACT_ZERO="1").returncode,0)
        calls=[c for c in self.calls() if c[0]=="xcodebuild"]
        self.assertEqual(len(calls),1)
        self.assertFalse(any("HitotsuzuriUITests" in x for x in calls[0]))
    def test_local_environment_cannot_claim_ci_core_dependency(self):
        self.assertNotEqual(self.run_script("--functional",GITHUB_ACTIONS="false",HZS_CORE_PREFLIGHT_DONE="1",CONTRACT_CORE_FAIL="1").returncode,0)
        self.assertEqual(len([c for c in self.calls() if c[0]=="xcodebuild"]),1)
    def test_ci_rejects_performance_and_all_before_execution(self):
        for args in [(), ("--performance",), ("ArticleDraftPerformanceUITests",)]:
            self.assertNotEqual(self.run_script(*args,GITHUB_ACTIONS="true").returncode,0)
        self.assertEqual(self.calls(),[])
    def test_functional_core_excludes_all_real_benchmarks(self):
        self.assertEqual(self.run_script("--core",script="verify-native.sh").returncode,0)
        call=next(c for c in self.calls() if c[0]=="xcodebuild")
        for case in ["HitotsuzuriU1Tests/ArticleIntegrationTests/testLongTextSaveThirtySamples", "HitotsuzuriU1Tests/ArticleIntegrationTests/testColdOpenTenSamples", "HitotsuzuriU1Tests/ArticleIntegrationTests/testImageMemoryAndThirtyConversions", "HitotsuzuriU2Tests/ArticleDraftIntegrationTests/testLongDraftPersistenceAndProjectionPerformance", "HitotsuzuriU2Tests/ArticlePreviewRetryTests/testDisplayMemoryAndCancellationThirtyTrials"]:
            self.assertIn("-skip-testing:"+case,call)
    def test_missing_named_benchmark_fails_even_if_class_has_passes(self):
        result=self.run_script("--performance",script="verify-native.sh",CONTRACT_OMIT_PERFORMANCE="1")
        self.assertNotEqual(result.returncode,0)
        self.assertIn("testColdOpenTenSamples",result.stderr)
        self.assertEqual(len([c for c in self.calls() if c[0]=="xcodebuild"]),1)

if __name__ == "__main__": unittest.main()
