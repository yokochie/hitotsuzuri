#!/bin/bash
set -euo pipefail
classes=(ArticleModelTests ArticlePersistenceTests ArticleRecoveryTests ArticleWorkspaceTests ArticleSessionTests ArticleImageTests ArticleResourceTests ArticleProbeTests ArticleIntegrationTests)
filters=()
if [[ $# -gt 0 ]]; then
  selected=("$@")
  for name in "$@"; do
    found=false
    for allowed in "${classes[@]}"; do if [[ "$name" == "$allowed" ]]; then found=true; fi; done
    if [[ "$found" != true ]]; then exit 2; fi
    filters+=("-only-testing:HitotsuzuriU1Tests/$name")
  done
else
  selected=("${classes[@]}" ArticleFoundationUITests)
  for name in "${classes[@]}"; do filters+=("-only-testing:HitotsuzuriU1Tests/$name"); done
  filters+=("-only-testing:HitotsuzuriUITests/ArticleFoundationUITests")
fi
stamp="$(date +%Y%m%d-%H%M%S)-$$"
result=".build/Article-$stamp.xcresult"
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' "${filters[@]}" -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath "$result" CODE_SIGN_IDENTITY=- test
swift -e '
import Foundation
let process = Process(), pipe = Pipe()
process.executableURL = URL(fileURLWithPath:"/usr/bin/xcrun")
process.arguments = ["xcresulttool","get","test-results","tests","--path",CommandLine.arguments[1]]
process.standardOutput = pipe
try process.run()
let data = pipe.fileHandleForReading.readDataToEndOfFile()
process.waitUntilExit()
guard process.terminationStatus == 0 else { exit(1) }
let document = try JSONSerialization.jsonObject(with:data) as! [String:Any]
var executed = Set<String>()
func inspect(_ node:[String:Any]) {
    let children = node["children"] as? [[String:Any]] ?? []
    if node["nodeType"] as? String == "Test Suite", node["result"] as? String == "Passed",
       children.contains(where: {$0["nodeType"] as? String == "Test Case" && $0["result"] as? String == "Passed"}),
       let name = node["name"] as? String { executed.insert(name) }
    children.forEach(inspect)
}
(document["testNodes"] as? [[String:Any]] ?? []).forEach(inspect)
guard Set(CommandLine.arguments.dropFirst(2)).isSubset(of:executed) else {
    fputs("指定したArticle試験クラスの一部が未実行です。\n",stderr); exit(1)
}
' "$result" "${selected[@]}"
