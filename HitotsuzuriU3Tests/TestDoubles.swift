import XCTest
@testable import HitotsuzuriCore

func candidate(_ ids:[String] = ["4","2","3","1"]) -> CommittedSelection {
    .init(albumID:"a",albumTitle:"保存時の名称",orderedAssetIDs:ids,confirmedAt:Date(timeIntervalSince1970:123))
}
@MainActor final class U3Library: LibrarySource {
    var access:AccessStatus = .authorized
    var hierarchyCount=0
    var assetsCount=0
    var pause:(@MainActor () async -> Void)?
    var pauseAssets:(@MainActor (String) async -> Void)?
    var photos=["1","2","3","4","5"]
    var value=LibraryHierarchy(folders:[.init(id:"f",title:"親",albums:["a"]),.init(id:"other",title:"別")],albums:[.init(id:"a",title:"現在の名称")])
    func status()->AccessStatus { access }
    func requestAccess() async ->AccessStatus { access = .authorized; return access }
    func hierarchy() async throws ->LibraryHierarchy { hierarchyCount += 1; if let pause { await pause() }; return value }
    func assets(in albumID:String) async throws ->[LibraryAsset] { assetsCount += 1; if let pauseAssets {await pauseAssets(albumID)}; return photos.map { .init(id:$0) } }
}
@MainActor final class U3Images: ImageAccessing {
    var calls=[String](), released=Set<String>()
    var failure:PickerFailure?
    var pause:(@MainActor () async -> Void)?
    var deadlines=[ContinuousClock.Instant?]()
    var onImage:(@MainActor ()->Void)?
    let buffer=ImageBuffer(pixels:Data(repeating:1,count:16),width:2,height:2,bytesPerRow:8)
    func image(_ id:String,validation:Bool,deadline:ContinuousClock.Instant?) async throws ->ImageBuffer {
        calls.append(id); deadlines.append(deadline); onImage?()
        if let pause { await pause() }; try Task.checkCancellation()
        if let failure { throw failure }; return buffer
    }
    func cancelDisplayRequests() {}
    func release(except ids:Set<String>) { released=ids }
}
@MainActor final class U3Clock:ImageClock {
    let base=ContinuousClock().now
    var offset:Duration = .zero
    func now()->ContinuousClock.Instant {base.advanced(by:offset)}
    func sleep(until deadline:ContinuousClock.Instant) async throws {try await Task.sleep(for:.seconds(60))}
}
actor U3Store: SelectionStoring {
    var settings:StoredValue<TargetFolderSettings> = .valid(.init(folderIDs:["f","removed"]))
    var selection:StoredValue<CommittedSelection> = .valid(candidate())
    var writes=0, reads=0
    var saveFailure:PickerFailure?
    var settingsFailure:PickerFailure?
    var pause:(@Sendable () async ->Void)?
    func configure(settings:StoredValue<TargetFolderSettings>?=nil,selection:StoredValue<CommittedSelection>?=nil,saveFailure:PickerFailure?=nil,settingsFailure:PickerFailure?=nil) {
        if let settings {self.settings=settings}; if let selection {self.selection=selection}
        self.saveFailure=saveFailure; self.settingsFailure=settingsFailure
    }
    func setPause(_ value:(@Sendable () async ->Void)?) { pause=value }
    func loadSettings()->StoredValue<TargetFolderSettings> { reads += 1; return settings }
    func loadSelection()->StoredValue<CommittedSelection> { reads += 1; return selection }
    func saveSettings(_ value:TargetFolderSettings)throws { if let settingsFailure {throw settingsFailure}; settings = .valid(value) }
    func saveSelection(_ value:CommittedSelection) async throws { writes += 1; if let pause {await pause()}; if let saveFailure {throw saveFailure}; selection = .valid(value) }
}
@MainActor func workflow(_ library:U3Library = U3Library(),_ images:U3Images = U3Images(),_ store:U3Store = U3Store())->SelectionWorkflow {
    SelectionWorkflow(library:PhotoLibraryAccess(source:library),images:images,store:store)
}
@MainActor func draft(_ w:SelectionWorkflow) async {
    await w.start(); await w.setTargetFolders(["f"]); await w.selectAlbum(.init(id:"a",title:"現在"))
    for id in ["1","2","3","4"] { await w.loadImage(id); if !w.selection.orderedIDs.contains(id) {w.toggle(id)} }
}
@MainActor final class U3Latch {
    var waiting=false
    private var opened=false
    private var continuation:CheckedContinuation<Void,Never>?
    func wait() async { if opened {return}; waiting=true; await withCheckedContinuation { continuation=$0 } }
    func open() {opened=true; continuation?.resume(); continuation=nil}
}
