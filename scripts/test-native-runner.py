"""Short isolated runner contracts; never starts Xcode or touches user fixtures."""
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent

def is_pinned_action_reference(reference, action):
    """依存更新を許可しつつ、正しいAction名と完全なcommit固定を検査する。"""
    return re.fullmatch(re.escape(action) + r"@[0-9a-f]{40}", reference) is not None

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
    if os.environ.get("CONTRACT_OMIT_FOCUS")=="1" and "NativeInputTests" in methods:
        methods["NativeInputTests"].remove("testSingleTabFromAlbumOperatesPhotoAndShiftTabReturns()")
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
    def test_ui_shards_run_disjoint_classes_without_repeating_smoke(self):
        for shard in ("a", "b"):
            result = self.run_script("--ui-shard-"+shard, script="verify-native.sh")
            self.assertEqual(result.returncode, 0, result.stderr)
        calls = [call for call in self.calls() if call[0] == "xcodebuild"]
        self.assertEqual(len(calls), 2)
        selections = [{arg for arg in call if arg.startswith("-only-testing:")} for call in calls]
        self.assertTrue(selections[0].isdisjoint(selections[1]))
        self.assertEqual(len(selections[0] | selections[1]), 7)
        self.assertTrue(all(arg.startswith("-only-testing:HitotsuzuriUITests/") for arg in selections[0] | selections[1]))
        self.assertFalse(any("FixtureSmokeUITests" in arg or "Performance" in arg for arg in selections[0] | selections[1]))
    def test_ui_shard_rejects_missing_execution(self):
        result = self.run_script("--ui-shard-a", script="verify-native.sh", CONTRACT_ZERO="1")
        self.assertNotEqual(result.returncode, 0)
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
    def test_input_focus_is_partial_and_requires_both_named_cases(self):
        result=self.run_script("--input-focus",script="verify-native.sh")
        self.assertEqual(result.returncode,0,result.stderr)
        calls=[c for c in self.calls() if c[0]=="xcodebuild"]
        self.assertEqual(len(calls),2)
        self.assertEqual({x for x in calls[-1] if x.startswith("-only-testing:")},{
            "-only-testing:HitotsuzuriUITests/NativeInputTests/testSingleTabFromAlbumOperatesPhotoAndShiftTabReturns",
            "-only-testing:HitotsuzuriUITests/NativeInputTests/testAlbumArrowsInCompactAfterMouseSelectionFollowPhotos"})
        self.assertFalse(any(c[0]=="swift" for c in self.calls()))
    def test_input_focus_is_not_a_draft_mode(self):
        self.assertNotEqual(self.run_script("--input-focus").returncode,0)
        self.assertEqual(self.calls(),[])
    def test_input_focus_rejects_one_missing_case(self):
        result=self.run_script("--input-focus",script="verify-native.sh",GITHUB_ACTIONS="true",CONTRACT_OMIT_FOCUS="1")
        self.assertNotEqual(result.returncode,0)
        self.assertIn("testSingleTabFromAlbumOperatesPhotoAndShiftTabReturns",result.stderr)
    def test_input_regression_selects_exactly_the_eight_failures(self):
        result=self.run_script("--input-regression",script="verify-native.sh",GITHUB_ACTIONS="true")
        self.assertEqual(result.returncode,0,result.stderr)
        calls=[c for c in self.calls() if c[0]=="xcodebuild"]
        self.assertEqual(len(calls),2)
        cases=[x for x in calls[-1] if x.startswith("-only-testing:")]
        self.assertEqual(len(set(cases)),8)
        self.assertTrue(all(x.startswith("-only-testing:HitotsuzuriUITests/NativeInputTests/test") for x in cases))
        self.assertFalse(any(c[0]=="swift" for c in self.calls()))

    def test_export_contract_selects_only_export_contract_class(self):
        result=self.run_script("ArticleExportContractTests",script="verify-article-export.sh")
        self.assertEqual(result.returncode,0,result.stderr)
        calls=[c for c in self.calls() if c[0]=="xcodebuild"]
        self.assertEqual(len(calls),1)
        self.assertEqual([x for x in calls[0] if x.startswith("-only-testing:")],
                         ["-only-testing:HitotsuzuriU3Tests/ArticleExportContractTests"])

    def test_export_performance_selects_exact_two_cases_without_ui(self):
        result=self.run_script("--performance",script="verify-article-export.sh")
        self.assertEqual(result.returncode,0,result.stderr)
        calls=[c for c in self.calls() if c[0]=="xcodebuild"]
        self.assertEqual(len(calls),1)
        self.assertEqual(len([x for x in calls[0] if x.startswith("-only-testing:")]),2)
        self.assertFalse(any("HitotsuzuriUITests" in x for x in calls[0]))

    def test_export_ci_rejects_performance_before_execution(self):
        result=self.run_script("--performance",script="verify-article-export.sh",GITHUB_ACTIONS="true")
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(self.calls(),[])

    def test_export_selected_functional_excludes_real_benchmarks(self):
        result=self.run_script("ArticleExportIntegrationTests",script="verify-article-export.sh",GITHUB_ACTIONS="true")
        self.assertEqual(result.returncode,0,result.stderr)
        call=next(c for c in self.calls() if c[0]=="xcodebuild")
        self.assertIn("-skip-testing:HitotsuzuriU3Tests/ArticleExportIntegrationTests/testFourImageExportThirtyTrialsPerformance",call)
        self.assertIn("-skip-testing:HitotsuzuriU3Tests/ArticleExportIntegrationTests/testExportMemoryAndCancellationThirtyTrials",call)

    def test_export_local_class_diagnostic_does_not_repeat_performance(self):
        result=self.run_script("ArticleExportIntegrationTests",script="verify-article-export.sh",GITHUB_ACTIONS="false")
        self.assertEqual(result.returncode,0,result.stderr)
        call=next(c for c in self.calls() if c[0]=="xcodebuild")
        self.assertIn("-skip-testing:HitotsuzuriU3Tests/ArticleExportIntegrationTests/testFourImageExportThirtyTrialsPerformance",call)
        self.assertIn("-skip-testing:HitotsuzuriU3Tests/ArticleExportIntegrationTests/testExportMemoryAndCancellationThirtyTrials",call)

class PinnedActionReferenceTests(unittest.TestCase):
    def test_accepts_previous_and_updated_commit_pins(self):
        references = {
            "actions/checkout": [
                "d23441a48e516b6c34aea4fa41551a30e30af803",
                "3d3c42e5aac5ba805825da76410c181273ba90b1",
            ],
            "actions/upload-artifact": [
                "ea165f8d65b6e75b540449e92b4886f43607fa02",
                "cf430e030ddbb5b0abf93d22962f4752f3646cd9",
            ],
        }
        for action, commits in references.items():
            for commit in commits:
                with self.subTest(action=action, commit=commit):
                    self.assertTrue(is_pinned_action_reference(f"{action}@{commit}", action))

    def test_rejects_tags_branches_and_short_or_invalid_commits(self):
        action = "actions/upload-artifact"
        for reference in ["v7", "main", "cf430e0", "g" * 40, "A" * 40]:
            with self.subTest(reference=reference):
                self.assertFalse(is_pinned_action_reference(f"{action}@{reference}", action))

    def test_rejects_another_action_with_a_valid_commit(self):
        reference = "actions/checkout@" + "a" * 40
        self.assertFalse(is_pinned_action_reference(reference, "actions/upload-artifact"))

    def test_rejects_extra_characters_around_the_reference(self):
        valid = "actions/upload-artifact@" + "a" * 40
        for reference in [valid + "0", valid + "\n", valid + "/extra", " " + valid]:
            with self.subTest(reference=reference):
                self.assertFalse(is_pinned_action_reference(reference, "actions/upload-artifact"))


class ExportDiagnosticWorkflowTests(unittest.TestCase):
    def workflow(self):
        path = ROOT / ".github/workflows/diagnose-article-export.yml"
        self.assertTrue(path.is_file(), "承認されたbranch限定診断workflowが存在する")
        if not path.is_file(): return {}
        return json.loads(subprocess.check_output(["ruby", "-ryaml", "-rjson", "-e", "puts JSON.generate(YAML.load_file(ARGV[0]))", str(path)], text=True))

    def test_diagnostic_requires_exact_branch_and_explicit_commit_marker(self):
        workflow = self.workflow()
        if not workflow: return
        event = workflow.get("on", workflow.get("true", {}))
        self.assertEqual(event, {"push": {"branches": ["codex/phase2-u2-draft-experience"]}})
        job = workflow["jobs"]["fixed-copy"]
        self.assertEqual(job["if"], "github.ref == 'refs/heads/codex/phase2-u2-draft-experience' && contains(github.event.head_commit.message, '[u3-copy-diagnostic]')")
        self.assertEqual(workflow["permissions"], {"contents": "read"})
        self.assertEqual(job["runs-on"], "xcode-27")
        self.assertEqual(job["timeout-minutes"], 10)

    def test_diagnostic_runs_one_case_and_always_uploads_only_its_bundle(self):
        workflow = self.workflow()
        if not workflow: return
        steps = workflow["jobs"]["fixed-copy"]["steps"]
        commands = [step["run"] for step in steps if "run" in step]
        self.assertEqual(len(commands), 2)
        environment = next((command for command in commands if "sw_vers" in command), "")
        for expected in ["xcodebuild -version", "defaults read -g AppleKeyboardUIMode", "not explicitly configured"]:
            self.assertIn(expected, environment)
        self.assertNotIn("defaults write", environment)
        diagnostics = [command for command in commands if "-only-testing:" in command]
        self.assertEqual(len(diagnostics), 1)
        command = diagnostics[0]
        self.assertEqual(command.count("-only-testing:"), 1)
        self.assertIn("-only-testing:HitotsuzuriUITests/ArticleExportUITests/testFixedCompletionCopyDoesNotUseLaterEditorChanges", command)
        self.assertNotIn("--functional", command)
        upload = steps[-1]
        self.assertEqual(upload["if"], "always()")
        self.assertTrue(is_pinned_action_reference(upload["uses"], "actions/upload-artifact"))
        self.assertEqual(upload["with"]["path"], ".build/ArticleExport-copy-diagnostic.xcresult")
        self.assertEqual(upload["with"]["retention-days"], 1)
        self.assertTrue(upload["with"].get("include-hidden-files", False), "所有bundle内の隠しデータも欠落させない")
        self.assertTrue(is_pinned_action_reference(steps[0]["uses"], "actions/checkout"))

if __name__ == "__main__": unittest.main()
