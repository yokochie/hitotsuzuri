#if DEBUG
import Foundation
import HitotsuzuriCore

// UI試験専用。全境界をメモリに閉じ、実Photos/保存領域を生成しない。
@MainActor enum DebugFixture {
    static func makeWorkflow()->SelectionWorkflow {
        SelectionWorkflow(library:PhotoLibraryAccess(source:FixtureLibrary()),images:LocalImageAccess(driver:FixtureImages()),store:FixtureStore())
    }
}
@MainActor private final class FixtureLibrary:LibrarySource {
    func status()->AccessStatus {.authorized}
    func requestAccess() async ->AccessStatus {.authorized}
    func hierarchy() async throws ->LibraryHierarchy {
        .init(folders:[
            .init(id:"root-a",title:"テスト親A",children:["child-a"],albums:["album-a"]),
            .init(id:"child-a",title:"テスト子A",children:["grandchild-a"],albums:["album-c"]),
            .init(id:"grandchild-a",title:"テスト孫A",albums:["album-e"]),
            .init(id:"root-b",title:"テスト親B",children:["child-b"],albums:["album-b"]),
            .init(id:"child-b",title:"テスト子B",albums:["album-d"])
        ],albums:[.init(id:"album-a",title:"テストアルバムA"),.init(id:"album-b",title:"テストアルバムB"),.init(id:"album-c",title:"テストアルバムC"),.init(id:"album-d",title:"テストアルバムD"),.init(id:"album-e",title:"テストアルバムE")])
    }
    func assets(in albumID:String) async throws ->[LibraryAsset] {
        let count=["album-a":12,"album-b":10,"album-c":8,"album-d":6,"album-e":4][albumID] ?? 0
        return (0..<count).map {.init(id:"\(albumID)-photo-\($0+1)")}
    }
}
@MainActor private final class FixtureImages:ImageDriving {
    var next=0
    func request(_ id:String,completion:@escaping @MainActor (ImageOutcome)->Void)->Int {
        next += 1
        let color=UInt8((next*17)%200+30)
        let bytes=Data((0..<256).flatMap {_ in [color,UInt8(100),UInt8(180),UInt8(255)]})
        completion(.image(.init(pixels:bytes,width:16,height:16,bytesPerRow:64),final:true))
        return next
    }
    func cancel(_ id:Int) {}
}
private actor FixtureStore:SelectionStoring {
    var settings:TargetFolderSettings?
    var selection:CommittedSelection?
    func loadSettings()->StoredValue<TargetFolderSettings> {settings.map {.valid($0)} ?? .missing}
    func saveSettings(_ value:TargetFolderSettings) {settings=value}
    func loadSelection()->StoredValue<CommittedSelection> {selection.map {.valid($0)} ?? .missing}
    func saveSelection(_ value:CommittedSelection) {selection=value}
}
#endif
