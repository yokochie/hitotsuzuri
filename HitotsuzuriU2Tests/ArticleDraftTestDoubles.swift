import Foundation
import Darwin
@testable import HitotsuzuriCore

func draftSeconds(_ duration:Duration)->Double {
    let value=duration.components
    return Double(value.seconds)+Double(value.attoseconds)/1_000_000_000_000_000_000
}
func draftP95(_ values:[Double])->Double {
    guard !values.isEmpty else {return .infinity}
    return values.sorted()[Int(ceil(Double(values.count)*0.95))-1]
}

enum DraftFixtures {
    static func source(_ title: String = "散歩@260913") throws -> ArticleSource {
        try ArticleSource(selection: CommittedSelection(albumID: "draft-album", albumTitle: title, orderedAssetIDs: ["a", "b", "c", "d"]))
    }
    static func root() -> URL {
        DraftOwnedRoots.shared.makeRoot()
    }
}

// この試験プロセスが発行したUUIDのみを保持。強制終了時の未回収は別途報告する。
private final class DraftOwnedRoots:@unchecked Sendable {
    static let shared=DraftOwnedRoots()
    private let lock=NSLock()
    private var roots:[URL]=[]
    private let base=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent(".build/article-tests").resolvingSymlinksInPath()
    private init() {atexit {DraftOwnedRoots.shared.cleanUp()}}
    func makeRoot()->URL {
        let root=base.appendingPathComponent(UUID().uuidString,isDirectory:true)
        lock.withLock {roots.append(root)}
        return root
    }
    func cleanUp() {
        let owned=lock.withLock {let value=roots; roots=[]; return value}
        for root in owned {
            guard root.deletingLastPathComponent().path == base.path,
                  root.resolvingSymlinksInPath().path == root.path,
                  (try? root.resourceValues(forKeys:[.isSymbolicLinkKey]).isSymbolicLink) != true,
                  UUID(uuidString:root.lastPathComponent) != nil else {
                fputs("Draft test root cleanup refused unsafe path.\n",stderr); continue
            }
            do {
                if FileManager.default.fileExists(atPath:root.path) {try FileManager.default.removeItem(at:root)}
            } catch {fputs("Draft test root cleanup failed.\n",stderr)}
        }
    }
}

final class DraftCheckpoint: @unchecked Sendable {
    private let lock = NSLock()
    private var armed = false
    func arm() { lock.withLock { armed = true } }
    func check(_ point: ArticlePersistenceCheckpoint) throws {
        if case .currentRenamed = point {
            let fail = lock.withLock { let old = armed; armed = false; return old }
            if fail { throw ArticleFailure.ioFailure }
        }
    }
}

actor DraftSelections: SelectionStoring {
    var selection: CommittedSelection?
    var failure: PickerFailure?
    init(_ selection: CommittedSelection? = CommittedSelection(albumID:"draft-album",albumTitle:"散歩@260913",orderedAssetIDs:["a","b","c","d"])) { self.selection=selection }
    func set(_ value: CommittedSelection?) { selection=value }
    func fail(_ value: PickerFailure) { failure=value }
    func loadSelection() -> StoredValue<CommittedSelection> { failure.map { .failure($0) } ?? selection.map { .valid($0) } ?? .missing }
    func saveSelection(_ value: CommittedSelection) { selection=value }
    func loadSettings() -> StoredValue<TargetFolderSettings> { .missing }
    func saveSettings(_ settings: TargetFolderSettings) {}
}

actor DraftStore: ArticleStoring {
    let disk = ArticlePersistence(directory: DraftFixtures.root(), diagnostics: ArticleDiagnostics { _ in })
    var listFailure: ArticleFailure?
    var individualFailures: [UUID: ArticleFailure] = [:]
    var openFailure: ArticleFailure?
    var pauseOpen=false
    var saveFailures: [ArticleFailure] = []
    var loseResponse = false
    var pause = false
    var waiting = false
    var continuation: CheckedContinuation<Void,Never>?
    var createCount=0
    var operationIDs: [UUID] = []
    func configure(list: ArticleFailure? = nil, individual: [UUID:ArticleFailure] = [:], open: ArticleFailure? = nil, save: [ArticleFailure] = [], lose: Bool = false, pause: Bool = false, pauseOpen: Bool = false) {
        listFailure=list; individualFailures=individual; openFailure=open; saveFailures=save; loseResponse=lose; self.pause=pause
        self.pauseOpen=pauseOpen
    }
    func release() { continuation?.resume(); continuation=nil }
    private func before(_ id: UUID) async throws {
        operationIDs.append(id)
        if pause { pause=false; waiting=true; await withCheckedContinuation { continuation=$0 }; waiting=false }
        if !saveFailures.isEmpty { throw saveFailures.removeFirst() }
    }
    private func after(_ value: SavedArticle) throws -> SavedArticle {
        if loseResponse { loseResponse=false; throw ArticleFailure.uncertainResult }; return value
    }
    func create(projectID: UUID, operationID: UUID, source: ArticleSource, content: ArticleContent) async throws -> SavedArticle {
        createCount += 1; try await before(operationID)
        return try after(await disk.create(projectID:projectID,operationID:operationID,source:source,content:content))
    }
    func save(projectID: UUID, operationID: UUID, expected: SavedArticle, content: ArticleContent) async throws -> SavedArticle {
        try await before(operationID)
        return try after(await disk.save(projectID:projectID,operationID:operationID,expected:expected,content:content))
    }
    func resumeWithSelection(projectID: UUID, operationID: UUID, expected: SavedArticle, source: ArticleSource) async throws -> SavedArticle {
        try await before(operationID)
        return try after(await disk.resumeWithSelection(projectID:projectID,operationID:operationID,expected:expected,source:source))
    }
    func open(_ id: UUID) async throws -> SavedArticle {
        if pauseOpen {pauseOpen=false; waiting=true; await withCheckedContinuation {continuation=$0}; waiting=false}
        if let openFailure { throw openFailure }; return try await disk.open(id)
    }
    func list() async throws -> ArticleDraftList {
        if let listFailure { throw listFailure }
        var list=try await disk.list(); list.failures.merge(individualFailures) { _,new in new }; return list
    }
}

@MainActor final class DraftOutput: ArticleOutputActions {
    var capabilities=ArticleOutputCapabilities(copy:true,export:true,reveal:true)
    var failure: ArticleFailure?
    var copied: [(String,ArticleCopyContext)] = []
    var pause=false
    var continuation: CheckedContinuation<Void,Never>?
    func release() { continuation?.resume(); continuation=nil }
    func copyPlainText(_ text: String, context: ArticleCopyContext) async throws {
        copied.append((text,context))
        if pause { await withCheckedContinuation { continuation=$0 } }
        if let failure { throw failure }
    }
    func runExport(jobID: UUID, savedInput: SavedExportInput, rendered: RenderedArticle, destination: ArticleExportDestination, progress: @escaping @MainActor (ExportProgress)->Void) async throws -> ExportResult { throw ArticleFailure.busy }
    func cancelExport(_ jobID: UUID) {}
    func revealExport(_ result: ExportResult) async throws { throw ArticleFailure.busy }
}

@MainActor final class DraftProjectionGate {
    var waiting=false
    var invocations=0
    var continuation: CheckedContinuation<Void,Never>?
    func project(_ context: ArticleProjectionContext, source: ArticleSource, content: ArticleContent) async throws -> RenderedArticle {
        invocations += 1
        guard !waiting else {throw ArticleFailure.busy}
        waiting=true
        await withCheckedContinuation { continuation=$0 }
        waiting=false
        return try context.renderArticle(source:source,content:content)
    }
    func release() { continuation?.resume(); continuation=nil }
}

@MainActor struct DraftHarness {
    let selections: DraftSelections, store: DraftStore, workspace: ArticleWorkspace, presentation: ArticlePresentation
    static func make(output: DraftOutput? = nil, projector: ArticleProjector? = nil) -> DraftHarness {
        let selections=DraftSelections(), store=DraftStore()
        let workspace=ArticleWorkspace(selections:selections,articles:store)
        let presentation: ArticlePresentation
        if let projector { presentation=ArticlePresentation(workspace:workspace,store:store,output:output,projector:projector) }
        else { presentation=ArticlePresentation(workspace:workspace,store:store,output:output) }
        return DraftHarness(selections:selections,store:store,workspace:workspace,presentation:presentation)
    }
    func savedSession() async throws -> ArticleEditSession {
        let source=try await workspace.readCommittedSelection()
        let saved=try await store.create(projectID:UUID(),operationID:UUID(),source:source,content:ArticleInitialContent(source:source).content)
        let session=ArticleEditSession(article:saved,store:store)
        presentation.adopt(session); return session
    }
}

@MainActor func draftWaitUntil(_ condition: @MainActor () async -> Bool) async -> Bool {
    let end=ContinuousClock().now + .seconds(2)
    while ContinuousClock().now < end {
        if await condition() { return true }
        await Task.yield()
    }
    return false
}

@MainActor final class DraftImages: ImageAccessing {
    var calls: [(String,Bool,ContinuousClock.Instant?)] = []
    var failures: [String: PickerFailure] = [:]
    var paused: String?
    var continuation: CheckedContinuation<Void,Never>?
    var cancelled=0
    var released: [Set<String>] = []
    var onRequest: (() -> Void)?
    func image(_ assetID: String, validation: Bool, deadline: ContinuousClock.Instant?) async throws -> ImageBuffer {
        calls.append((assetID,validation,deadline)); onRequest?()
        if paused == assetID { await withCheckedContinuation { continuation=$0 } }
        if let failure=failures[assetID] { throw failure }
        return ImageBuffer(pixels:Data(repeating:255,count:16),width:2,height:2,bytesPerRow:8)
    }
    func releasePending() { continuation?.resume(); continuation=nil; paused=nil }
    func cancelDisplayRequests() { cancelled += 1 }
    func release(except ids: Set<String>) { released.append(ids) }
}

@MainActor final class DraftClock: ImageClock {
    var instant=ContinuousClock().now
    func now() -> ContinuousClock.Instant { instant }
    func advance(_ seconds: Int) { instant += .seconds(seconds) }
    func sleep(until deadline: ContinuousClock.Instant) async throws { try await Task.sleep(for:.seconds(100)) }
}

final class DraftLogs: @unchecked Sendable {
    private let lock=NSLock()
    private var values:[String]=[]
    func append(_ line:String) { lock.withLock {values.append(line)} }
    var lines:[String] { lock.withLock {values} }
}

@MainActor final class DraftDisplayDriver:ImageDriving {
    var held=false
    var requests=0
    var cancelled:[Int]=[]
    var callbacks:[Int:@MainActor (ImageOutcome)->Void]=[:]
    func request(_ assetID:String,completion:@escaping @MainActor (ImageOutcome)->Void)->Int {
        requests += 1; let id=requests
        if held {callbacks[id]=completion}
        else {completion(.image(ImageBuffer(pixels:Data(repeating:255,count:512*512*4),width:512,height:512,bytesPerRow:512*4),final:true))}
        return id
    }
    func cancel(_ requestID:Int) {cancelled.append(requestID)}
}

@MainActor final class DraftDeadlineClock:ImageClock {
    var instant=ContinuousClock().now
    private var waiters:[UUID:(ContinuousClock.Instant,CheckedContinuation<Void,Error>)]=[:]
    var pending:Int {waiters.count}
    func now()->ContinuousClock.Instant {instant}
    func advance(_ seconds:Int) {
        instant += .seconds(seconds)
        for id in Array(waiters.keys) {
            if let (deadline,continuation)=waiters[id],instant >= deadline {
                waiters[id]=nil; continuation.resume()
            }
        }
    }
    func sleep(until deadline:ContinuousClock.Instant) async throws {
        guard instant < deadline else {return}
        let id=UUID()
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            try await withCheckedThrowingContinuation {waiters[id]=(deadline,$0)}
        } onCancel: {Task {@MainActor [weak self] in
            self?.waiters.removeValue(forKey:id)?.1.resume(throwing:CancellationError())
        }}
    }
}

struct DraftMemorySample:Sendable {
    let footprint:UInt64, lifetimePeak:UInt64
    static func read() throws ->Self {
        var info=task_vm_info_data_t(), count=mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size/MemoryLayout<integer_t>.size)
        let result=withUnsafeMutablePointer(to:&info) {pointer in
            pointer.withMemoryRebound(to:integer_t.self,capacity:Int(count)) {task_info(mach_task_self_,task_flavor_t(TASK_VM_INFO),$0,&count)}
        }
        guard result == KERN_SUCCESS, info.ledger_phys_footprint_peak >= 0 else {throw ArticleFailure.ioFailure}
        return Self(footprint:info.phys_footprint,lifetimePeak:UInt64(info.ledger_phys_footprint_peak))
    }
}
