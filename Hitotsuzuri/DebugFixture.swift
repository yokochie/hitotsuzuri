#if DEBUG
import Foundation
import HitotsuzuriCore
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

// UI試験専用。全境界をメモリに閉じ、実Photos/保存領域を生成しない。
@MainActor enum DebugFixture {
    static func makeWorkflow()->SelectionWorkflow {
        SelectionWorkflow(library:PhotoLibraryAccess(source:FixtureLibrary()),images:LocalImageAccess(driver:FixtureImages()),store:FixtureStore())
    }
    static func makePickerWithArticles() -> (SelectionWorkflow, ArticleAppCoordinator) {
        let store = FixtureStore(), root = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent("picker-article-" + UUID().uuidString)
        return (SelectionWorkflow(library:PhotoLibraryAccess(source:FixtureLibrary()),images:LocalImageAccess(driver:FixtureImages()),store:store), ArticleAppCoordinator(selections:store,directory:root))
    }
    static func makeArticles() -> (SelectionWorkflow, ArticleAppCoordinator) {
        let namedRoot=ProcessInfo.processInfo.environment["HZS_ARTICLE_TEST_ROOT"]
        let name=namedRoot ?? UUID().uuidString
        print("Article fixture enabled: namedRoot=\(namedRoot != nil)")
        let safe = name.filter { $0.isLetter || $0.isNumber || $0 == "-" }
        // OS管理の一時baseだけを正規化。生成したjob領域/選択先のリンク拒否は維持。
        let root = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent("ArticleFixture-" + safe, isDirectory:true)
        let selection = try! JSONDecoder().decode(CommittedSelection.self,from:Data(#"{"schemaVersion":1,"selectionID":"11111111-1111-1111-1111-111111111111","albumID":"album-a","albumTitle":"合成写真の記事","orderedAssetIDs":["album-a-photo-1","album-a-photo-2","album-a-photo-3","album-a-photo-4"],"confirmedAt":1}"#.utf8))
        let store = FixtureStore(selection:selection,settings:TargetFolderSettings(folderIDs:["root-a"]))
        return (SelectionWorkflow(library:PhotoLibraryAccess(source:FixtureLibrary()),images:LocalImageAccess(driver:FixtureImages()),store:store), ArticleAppCoordinator(selections:store,directory:root,reader:ArticleFixtureReader(root:root),fixtureDestination:root.appendingPathComponent("Output"),previewImages:LocalImageAccess(driver:ArticleFixturePreviews())))
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
    init(selection:CommittedSelection?=nil,settings:TargetFolderSettings?=nil) {self.selection=selection; self.settings=settings}
    func loadSettings()->StoredValue<TargetFolderSettings> {settings.map {.valid($0)} ?? .missing}
    func saveSettings(_ value:TargetFolderSettings) {settings=value}
    func loadSelection()->StoredValue<CommittedSelection> {selection.map {.valid($0)} ?? .missing}
    func saveSelection(_ value:CommittedSelection) {selection=value}
}
@MainActor private final class ArticleFixtureReader: ArticleImageReading {
    let root: URL
    init(root:URL) {self.root=root}
    func request(_ id:String,networkAllowed:Bool,completion:@escaping @MainActor (Result<ArticleImageInput,ArticleFailure>)->Void)->Int {
        do {
            try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
            let url=root.appendingPathComponent("synthetic.png")
            let space=CGColorSpace(name:CGColorSpace.sRGB)!
            let context=CGContext(data:nil,width:60,height:40,bitsPerComponent:8,bytesPerRow:240,space:space,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.setFillColor(CGColor(red:0.3,green:0.5,blue:0.8,alpha:1)); context.fill(CGRect(x:0,y:0,width:60,height:40))
            let destination=CGImageDestinationCreateWithURL(url as CFURL,UTType.png.identifier as CFString,1,nil)!
            CGImageDestinationAddImage(destination,context.makeImage()!,nil)
            guard CGImageDestinationFinalize(destination) else {throw ArticleFailure.ioFailure}
            completion(.success(ArticleImageInput(url:url,orientation:1)))
        } catch {completion(.failure(.ioFailure))}
        return 1
    }
    func cancel(_ request:Int) {}
}
@MainActor private final class ArticleFixturePreviews:ImageDriving {
    private let images=FixtureImages()
    func request(_ id:String,completion:@escaping @MainActor (ImageOutcome)->Void)->Int {
        if id == "album-a-photo-2" {completion(.unavailable); return -1}
        return images.request(id,completion:completion)
    }
    func cancel(_ request:Int) {images.cancel(request)}
}
#endif
