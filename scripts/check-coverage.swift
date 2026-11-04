import Foundation

// xccovの実行行数を製品の手書きSwiftファイル全体で重み付き集計する。
guard CommandLine.arguments.count==2 else { fputs("使用法: swift scripts/check-coverage.swift <U1.xcresult>\n",stderr); exit(2) }
let process=Process()
process.executableURL=URL(fileURLWithPath:"/usr/bin/xcrun")
process.arguments=["xccov","view","--report","--json",CommandLine.arguments[1]]
let pipe=Pipe(); process.standardOutput=pipe; process.standardError=FileHandle.standardError
do { try process.run() } catch { fputs("xccovを実行できません。\n",stderr); exit(2) }
let data=pipe.fileHandleForReading.readDataToEndOfFile(); process.waitUntilExit()
guard process.terminationStatus==0 else { exit(process.terminationStatus) }
guard let report=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any], let targets=report["targets"] as? [[String:Any]] else { fputs("カバレッジ結果が不正です。\n",stderr); exit(2) }
let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
var expected=Set<String>()
for directory in ["Hitotsuzuri","HitotsuzuriCore"] {
    guard let files=FileManager.default.enumerator(at:root.appendingPathComponent(directory),includingPropertiesForKeys:nil) else { fputs("製品ソースがありません。\n",stderr); exit(2) }
    for case let url as URL in files where url.pathExtension=="swift" { expected.insert(url.standardizedFileURL.path) }
}
var counts=[String:(Int,Int)]()
for target in targets where ["Hitotsuzuri.app","HitotsuzuriCore.framework"].contains(target["name"] as? String ?? "") {
    for file in target["files"] as? [[String:Any]] ?? [] {
        guard let path=file["path"] as? String, expected.contains(path), let covered=file["coveredLines"] as? Int, let total=file["executableLines"] as? Int else { continue }
        counts[path]=(covered,total)
    }
}
let missing=expected.subtracting(counts.keys)
guard missing.isEmpty else { fputs("未計測の製品ソースがあります: \(missing.sorted().joined(separator:", "))\n",stderr); exit(1) }
let covered=counts.values.reduce(0) { $0+$1.0 }, total=counts.values.reduce(0) { $0+$1.1 }
guard total>0 else { fputs("実行可能行が0です。\n",stderr); exit(1) }
for path in counts.keys.sorted() {
    let (c,t)=counts[path]!
    print("\(path.replacingOccurrences(of:root.path+"/",with:"")): \(c)/\(t)")
}
let percent=100*Double(covered)/Double(total)
print(String(format:"製品全体の行カバレッジ: %d/%d = %.2f%%",covered,total,percent))
exit(percent>=80 ? 0 : 1)

