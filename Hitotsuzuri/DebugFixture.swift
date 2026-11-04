#if DEBUG
import Foundation
import Observation
import HitotsuzuriCore
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

// UI試験専用。全境界をメモリに閉じ、実Photos/保存領域を生成しない。
@MainActor enum DebugFixture {
    private static func ownedRoot()->URL {
        let token=ProcessInfo.processInfo.environment["HZS_ARTICLE_TEST_ROOT"] ?? "uitest-"+UUID().uuidString
        precondition(token.hasPrefix("uitest-") && UUID(uuidString:String(token.dropFirst(7)))?.uuidString == String(token.dropFirst(7)),"試験rootは生成済みUUIDだけを許可")
        return FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent("ArticleFixture-"+token,isDirectory:true)
    }
    private static func cleanOwnedRoot(_ root:URL) throws {
        let base=FileManager.default.temporaryDirectory.resolvingSymlinksInPath()
        guard root.deletingLastPathComponent().path == base.path,
              root.resolvingSymlinksInPath().path == root.path,
              (try? root.resourceValues(forKeys:[.isSymbolicLinkKey]).isSymbolicLink) != true,
              root.lastPathComponent.hasPrefix("ArticleFixture-uitest-"),
              UUID(uuidString:String(root.lastPathComponent.dropFirst(22))) != nil else {throw ArticleFailure.invalidInput}
        if FileManager.default.fileExists(atPath:root.path) {try FileManager.default.removeItem(at:root)}
        guard !FileManager.default.fileExists(atPath:root.path) else {throw ArticleFailure.ioFailure}
    }
    static func makeWorkflow()->SelectionWorkflow {
        SelectionWorkflow(library:PhotoLibraryAccess(source:FixtureLibrary()),images:LocalImageAccess(driver:FixtureImages()),store:FixtureStore())
    }
    static func makePickerWithArticles() -> (SelectionWorkflow, ArticleAppCoordinator) {
        let store = FixtureStore(), root = ownedRoot()
        let images=LocalImageAccess(driver:FixtureImages())
        return (SelectionWorkflow(library:PhotoLibraryAccess(source:FixtureLibrary()),images:images,store:store), ArticleAppCoordinator(selections:store,directory:root,previewImages:images))
    }
    static func makeArticles(launchStarted:ContinuousClock.Instant = ContinuousClock().now) -> (SelectionWorkflow, ArticleAppCoordinator) {
        let root=ownedRoot()
        let selection = try! JSONDecoder().decode(CommittedSelection.self,from:Data(#"{"schemaVersion":1,"selectionID":"11111111-1111-1111-1111-111111111111","albumID":"album-a","albumTitle":"合成写真の記事","orderedAssetIDs":["album-a-photo-1","album-a-photo-2","album-a-photo-3","album-a-photo-4"],"confirmedAt":1}"#.utf8))
        let draftCase=ProcessInfo.processInfo.environment["HZS_DRAFT_CASE"]
        let fixtureCase=draftCase ?? "default"
        var current=selection
        if let draftCase {
            var json=try! JSONSerialization.jsonObject(with:JSONEncoder().encode(selection)) as! [String:Any]
            json["albumTitle"]=["long","performance"].contains(draftCase) ? String(repeating:"長い名称",count:50)+"@260913" : "合成@260913"
            if ["reconfirmed","multiple","partial"].contains(fixtureCase) { json["selectionID"]="22222222-2222-2222-2222-222222222222" }
            current=try! JSONDecoder().decode(CommittedSelection.self,from:JSONSerialization.data(withJSONObject:json))
        }
        let store = FixtureStore(selection:draftCase == "empty" ? nil : current,settings:TargetFolderSettings(folderIDs:["root-a"]))
        let draftStore=ArticleFixtureDraftStore(directory:root.appendingPathComponent("Articles"),mode:draftCase ?? "default")
        let previewDriver=ArticleFixturePreviews(unavailableAll:draftCase == "photos-missing",delayMilliseconds:draftCase == "performance" ? 100000 : (draftCase == "slow-photos" ? 300 : 0))
        let images=LocalImageAccess(driver:previewDriver)
        let coordinator=ArticleAppCoordinator(selections:store,directory:root,reader:ArticleFixtureReader(root:root),fixtureDestination:root.appendingPathComponent("Output"),previewImages:images,articleStore:draftStore)
        let previewIDs=current.orderedAssetIDs
        coordinator.fixturePreviewRequestCounts={previewIDs.map {previewDriver.requestCounts[$0] ?? 0}}
        if ProcessInfo.processInfo.environment["HZS_FIXTURE_CLEANUP"] == "1" {
            do {
                try cleanOwnedRoot(root)
                coordinator.message="試験データを回収しました。"
            } catch {coordinator.message="試験データの回収に失敗しました。"}
            return (SelectionWorkflow(library:PhotoLibraryAccess(source:FixtureLibrary()),images:images,store:store),coordinator)
        }
        if draftCase == "invalid-raw" {coordinator.fixtureDraftPreparation={$0.metadataInput.change(year:"2026",month:"2",day:"31")}}
        if ["save-delay","performance"].contains(fixtureCase) {coordinator.fixtureReleaseSave={await draftStore.releaseSave()}}
        if fixtureCase == "performance" {
            coordinator.fixturePrepareRead={await draftStore.armRead()}; coordinator.fixtureReleaseRead={await draftStore.releaseRead()}
            if ProcessInfo.processInfo.environment["HZS_DRAFT_AUTO_OPEN"] == "1" {coordinator.beginFixtureMetric("cold-input-ready",started:launchStarted)}
        }
        if ["reconfirmed","multiple","partial","long","performance"].contains(fixtureCase) {
            let fixtureSelection=current
            coordinator.fixturePreparation=Task {
                do {
                    let articles=ArticlePersistence(directory:root.appendingPathComponent("Articles"))
                    if fixtureCase == "performance",let existing=try? await articles.list(),existing.articles.count == 100,existing.failures.isEmpty {
                        let target="33333333-3333-3333-3333-000000000001"
                        let files=try FileManager.default.contentsOfDirectory(at:root.appendingPathComponent("Articles/\(target)/operations"),includingPropertiesForKeys:nil)
                        if files.count >= 1000 {return}
                    }
                    let source=try ArticleSource(selection:["long","performance"].contains(fixtureCase) ? fixtureSelection : selection)
                    for index in 1...(["multiple","partial"].contains(fixtureCase) ? 2 : 1) {
                        var content=ArticleContent(source:source)
                        if ["long","performance"].contains(fixtureCase) {
                            content=ArticleInitialContent(source:source).content
                            content.introduction=String(repeating:"導",count:10000); content.closing=String(repeating:"結",count:10000)
                            for photo in 0..<4 {content.photoTexts[photo].text=String(repeating:"写",count:10000)}
                        } else {content.title=draftCase == "multiple" ? "同名記事" : "既存の文章\(index)"; content.introduction="再開して保持する文章"}
                        let id=UUID(uuidString:String(format:"33333333-3333-3333-3333-%012d",index))!
                        var saved=try await articles.create(projectID:id,operationID:id,source:source,content:content)
                        if fixtureCase == "performance" {
                            for operation in 1..<1000 {
                                let operationID=UUID(uuidString:String(format:"44444444-4444-4444-4444-%012d",operation))!
                                saved=try await articles.save(projectID:id,operationID:operationID,expected:saved,content:content)
                            }
                            for other in 1..<100 {
                                let otherID=UUID(uuidString:String(format:"55555555-5555-5555-5555-%012d",other))!
                                let otherSource=try ArticleSource(selection:CommittedSelection(albumID:"load-\(other)",albumTitle:String(repeating:"名称",count:100),orderedAssetIDs:(1...4).map {"load-\(other)-\($0)"}))
                                var otherContent=ArticleContent(source:otherSource)
                                otherContent.title=content.title; otherContent.introduction=content.introduction; otherContent.closing=content.closing
                                for photo in 0..<4 {otherContent.photoTexts[photo].text=content.photoTexts[photo].text}
                                _=try await articles.create(projectID:otherID,operationID:otherID,source:otherSource,content:otherContent)
                            }
                        }
                        if draftCase == "partial", index == 2 {try Data("broken".utf8).write(to:root.appendingPathComponent("Articles/\(id.uuidString)/current"))}
                    }
                } catch { coordinator.message="試験用下書きを準備できませんでした。" }
            }
        }
        return (SelectionWorkflow(library:PhotoLibraryAccess(source:FixtureLibrary()),images:images,store:store),coordinator)
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
@MainActor @Observable private final class ArticleFixturePreviews:ImageDriving {
    private(set) var requestCounts:[String:Int]=[:]
    private let images=FixtureImages()
    private let unavailableAll:Bool
    private let delayMilliseconds:Int
    private var sequence=1000
    private var jobs:[Int:Task<Void,Never>]=[:]
    init(unavailableAll:Bool=false,delayMilliseconds:Int=0) {self.unavailableAll=unavailableAll; self.delayMilliseconds=delayMilliseconds}
    func request(_ id:String,completion:@escaping @MainActor (ImageOutcome)->Void)->Int {
        requestCounts[id,default:0] += 1
        if unavailableAll || id == "album-a-photo-2" {completion(.unavailable); return -1}
        if delayMilliseconds > 0 {
            sequence += 1; let token=sequence
            jobs[token]=Task { [weak self] in
                guard let self else {return}
                defer {jobs[token]=nil}
                do {try await Task.sleep(for:.milliseconds(delayMilliseconds))} catch {completion(.cancelled); return}
                _=images.request(id,completion:completion)
            }
            return token
        }
        return images.request(id,completion:completion)
    }
    func cancel(_ request:Int) {jobs.removeValue(forKey:request)?.cancel(); images.cancel(request)}
}

private actor ArticleFixtureDraftStore:ArticleStoring {
    let disk:ArticlePersistence
    let mode:String
    private var lost=false
    private var continuation:CheckedContinuation<Void,Never>?
    private var holdRead=false
    private var readContinuation:CheckedContinuation<Void,Never>?
    init(directory:URL,mode:String) {disk=ArticlePersistence(directory:directory); self.mode=mode}
    func create(projectID:UUID,operationID:UUID,source:ArticleSource,content:ArticleContent) async throws ->SavedArticle {try await disk.create(projectID:projectID,operationID:operationID,source:source,content:content)}
    func open(_ id:UUID) async throws ->SavedArticle {await waitForRead(); return try await disk.open(id)}
    func list() async throws ->ArticleDraftList {await waitForRead(); return try await disk.list()}
    func armRead() {holdRead=true}
    func releaseRead() {readContinuation?.resume(); readContinuation=nil}
    private func waitForRead() async {
        guard holdRead else {return}; holdRead=false
        let timeout=Task {do {try await Task.sleep(for:.seconds(15))} catch {return}; releaseRead()}
        await withCheckedContinuation {readContinuation=$0}; timeout.cancel()
    }
    func resumeWithSelection(projectID:UUID,operationID:UUID,expected:SavedArticle,source:ArticleSource) async throws ->SavedArticle {try await disk.resumeWithSelection(projectID:projectID,operationID:operationID,expected:expected,source:source)}
    func save(projectID:UUID,operationID:UUID,expected:SavedArticle,content:ArticleContent) async throws ->SavedArticle {
        if mode == "save-failure" {throw ArticleFailure.capacity}
        if ["save-delay","performance"].contains(mode) {
            let deadline=Task {do {try await Task.sleep(for:.seconds(15))} catch {return}; releaseSave()}
            await withCheckedContinuation {continuation=$0}
            deadline.cancel()
        }
        let value=try await disk.save(projectID:projectID,operationID:operationID,expected:expected,content:content)
        if mode == "save-uncertain", !lost {lost=true; throw ArticleFailure.uncertainResult}
        return value
    }
    func releaseSave() {continuation?.resume(); continuation=nil}
}
#endif
