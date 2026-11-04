import SwiftUI
import AppKit
import HitotsuzuriCore

@MainActor @Observable final class ArticleAppCoordinator: NSObject, NSWindowDelegate, NSApplicationDelegate {
    let presentation:ArticlePresentation
    var session: ArticleEditSession? {presentation.session}
    private(set) var canOpenCurrentSelection=false
    private(set) var previews:ArticlePhotoPreviews?
    var message = ""
    var working = false
    private let workspace: ArticleWorkspace
    private let store: any ArticleStoring
    private let images: ArticleImageAccess
    private let previewImages:any ImageAccessing
    private var previewTask:Task<Void,Never>?
    private let delivery = ArticleProbeDelivery()
    private let journal:ArticleProbeJournal
    private(set) var recovery:ArticleProbeRecoveryRecord?
    private var destinationState:ArticleDestinationState = .idle
    private var exportTask: Task<Void, Never>?
    private var requestID: UUID?
    private var leaving=false
    private let departure=ArticleDepartureBridge()
    private var previewSessionID:UUID?
    var suspendsCandidates=false
    var candidateSheetVisible=false
    private var candidateDismissal:CheckedContinuation<Void,Never>?
    private weak var attachedWindow:NSWindow?
    private var previousWindowDelegate:(any NSWindowDelegate)?
    private let fixtureDestination: URL?
    #if DEBUG
    var fixturePreparation:Task<Void,Never>?
    var fixtureDraftPreparation:((ArticleEditSession)->Void)?
    var fixtureReleaseSave:(() async ->Void)?
    var fixturePreviewRequestCounts:(()->[Int])?
    private struct FixtureMetric {
        let id=UUID()
        let started:ContinuousClock.Instant
        let sessionID:UUID?
        let title:String?
        let ordinal:Int
    }
    private var fixturePendingMetrics:[String:FixtureMetric]=[:]
    private var fixtureMeasurements:[String:[Double]]=[:]
    private var fixtureAccepted:[String:Int]=[:]
    private var fixtureCompleted:[String:Int]=[:]
    private var fixtureTimeouts:[String:Int]=[:]
    var fixturePrepareRead:(() async ->Void)?
    var fixtureReleaseRead:(() async ->Void)?
    private(set) var fixtureReadArmed=false
    private(set) var fixtureMetricsText="{}"
    var fixtureMeasuresPerformance:Bool {ProcessInfo.processInfo.arguments.contains("--article-test-fixture") && ProcessInfo.processInfo.environment["HZS_DRAFT_CASE"] == "performance"}
    func beginFixtureMetric(_ kind:String,title:String?=nil,started:ContinuousClock.Instant?=nil) {
        guard fixtureMeasuresPerformance else {return}
        fixtureAccepted[kind,default:0] += 1
        fixturePendingMetrics[kind]=FixtureMetric(started:started ?? ContinuousClock().now,sessionID:session?.sessionID,title:title,ordinal:fixtureAccepted[kind]!)
        publishFixtureMetrics()
    }
    private func publishFixtureMetrics() {
        var values=fixtureMeasurements
        values["fixture-process"]=[Double(ProcessInfo.processInfo.processIdentifier)]
        for (kind,ordinal) in fixtureAccepted {values[kind+"-accepted"]=[Double(ordinal)]}
        for (kind,ordinal) in fixtureCompleted {values[kind+"-completed"]=[Double(ordinal)]}
        for (kind,count) in fixtureTimeouts {values[kind+"-timeouts"]=[Double(count)]}
        if let data=try? JSONEncoder().encode(values),let text=String(data:data,encoding:.utf8) {fixtureMetricsText=text}
    }
    func reopenFixtureDraft() async {
        guard fixtureMeasuresPerformance else {return}
        beginFixtureMetric("reopen-input-ready")
        _=await presentation.requestNavigation(.reload); synchronizeSession()
    }
    func armFixtureRead() async {await fixturePrepareRead?(); fixtureReadArmed=true}
    func releaseFixtureRead() async {await fixtureReleaseRead?(); fixtureReadArmed=false}
    func restartFixturePreviews() {
        guard fixtureMeasuresPerformance else {return}
        previewSessionID=nil; synchronizeSession()
    }
    /// 呼出元はnative windowのdisplayIfNeeded完了後。再開は実field editorの入力可も確認する。
    func completeFixtureDisplayMetrics(in window:NSWindow,observedSessionID:UUID?)->Bool {
        guard fixtureMeasuresPerformance else {return true}
        func titleIsEditable(_ expected:String)->Bool {
            func find(_ view:NSView)->Bool {
                if let field=view as? NSTextField,field.isEditable,field.isEnabled,field.window === window,
                   let editor=field.currentEditor(),editor === window.firstResponder,editor.isEditable,
                   editor.string.utf8.elementsEqual(expected.utf8) {return true}
                return view.subviews.contains(where:find)
            }
            return window.contentView.map(find) ?? false
        }
        for (kind,metric) in fixturePendingMetrics {
            let ready:Bool
            switch kind {
            case "preview-draw":ready=presentation.mode == .preview && presentation.rendered != nil
            case "editor-input-ready":ready=observedSessionID == session?.sessionID && presentation.mode == .editing && session.map {titleIsEditable($0.content.title)} == true
            case "reopen-input-ready":ready=observedSessionID == session?.sessionID && session?.sessionID != metric.sessionID && !presentation.isLoading && session.map {titleIsEditable($0.content.title)} == true
            case "cold-input-ready":ready = observedSessionID == session?.sessionID && !presentation.isLoading && session.map {titleIsEditable($0.content.title)} == true
            case "entry-loading-draw","list-loading-draw":ready=presentation.isLoading
            case "saving-draw":ready=session?.isSaving == true
            case "input-draw":ready=metric.title.map(titleIsEditable) == true
            default:ready=false
            }
            let parts=metric.started.duration(to:ContinuousClock().now).components
            let elapsed=Double(parts.seconds)+Double(parts.attoseconds)/1e18
            if ready || elapsed >= 3 {
                if !ready {fixtureTimeouts[kind,default:0] += 1}
                fixtureMeasurements[kind,default:[]].append(elapsed)
                fixtureCompleted[kind]=metric.ordinal
                fixturePendingMetrics[kind]=nil
                publishFixtureMetrics()
            }
        }
        return fixturePendingMetrics.isEmpty
    }
    func resizeFixtureWindow(width:Int) {
        guard ProcessInfo.processInfo.arguments.contains("--article-test-fixture"),
              [640,959,960,961,1200].contains(width),let window=attachedWindow else {return}
        // 実ウィンドウの内容サイズを変えるだけで、最小幅や描画値は上書きしない。
        let height=window.contentRect(forFrameRect:window.frame).height
        window.setContentSize(NSSize(width:CGFloat(width),height:height))
    }
    #endif
    init(selections: any SelectionStoring, directory: URL, reader: any ArticleImageReading = PhotoKitArticleImageReader(), fixtureDestination: URL? = nil,previewImages:any ImageAccessing = LocalImageAccess(),articleStore:(any ArticleStoring)? = nil) {
        let store:any ArticleStoring = articleStore ?? ArticlePersistence(directory: directory.appendingPathComponent("Articles", isDirectory: true))
        self.store = store; workspace = ArticleWorkspace(selections: selections, articles: store)
        presentation=ArticlePresentation(workspace:workspace,store:store)
        journal=ArticleProbeJournal(directory:directory.appendingPathComponent("ProbeRecovery",isDirectory:true))
        images = ArticleImageAccess(reader: reader); self.fixtureDestination = fixtureDestination
        self.previewImages=previewImages
    }
    private func synchronizeSession() {
        guard let draft=session else { finishLeaving(); return }
        guard previewSessionID != draft.sessionID else {return}
        #if DEBUG
        let preparation=fixtureDraftPreparation; fixtureDraftPreparation=nil; preparation?(draft)
        #endif
        previewTask?.cancel(); previews?.cancel()
        previewSessionID=draft.sessionID
        attach(NSApp.keyWindow ?? NSApp.mainWindow)
        let previews=ArticlePhotoPreviews(assetIDs:draft.source.orderedAssetIDs,images:previewImages)
        self.previews=previews
        previewTask=Task {await previews.load()}
    }
    private func finishLeaving() {restoreWindowDelegate(); previewTask?.cancel(); previewTask=nil; previews?.cancel(); previews=nil; previewSessionID=nil}
    private func awaitFixture() async {
        #if DEBUG
        await fixturePreparation?.value
        #endif
    }
    func refreshEntryAvailability() async {await awaitFixture(); canOpenCurrentSelection = (try? await workspace.readCommittedSelection()) != nil}
    func loadRecovery() async {
        do {
            recovery=try await journal.pending()
            if recovery != nil {message="前回の画像出力に確認待ちの記録があります。同じ保存先を選び直して照合してください。"}
        } catch {message=(error as? ArticleFailure ?? .ioFailure).message}
    }
    func openSavedArticle() async {
        await awaitFixture()
        guard !working, !leaving else {return}
        #if DEBUG
        if fixtureReadArmed {beginFixtureMetric("list-loading-draw")}
        #endif
        await presentation.openDrafts(); synchronizeSession()
    }
    func openArticle() async {
        await awaitFixture()
        guard !working, !leaving else { return }
        #if DEBUG
        if fixtureReadArmed {beginFixtureMetric("entry-loading-draw")}
        #endif
        if session != nil { _=await leave(to:.currentSelection) }
        else { await presentation.beginCurrentSelection(); synchronizeSession() }
    }
    func chooseDraft(_ id:UUID) async {
        await presentation.chooseExisting(id)
        if presentation.pendingNavigation != nil {
            suspendsCandidates=true
            if candidateSheetVisible {await withCheckedContinuation {candidateDismissal=$0}}
            _=await leave(to:.article(id))
            if presentation.pendingNavigation == nil {presentation.cancelCandidates()}
            suspendsCandidates=false
        }
        synchronizeSession()
    }
    func candidateDidDismiss() {candidateSheetVisible=false; candidateDismissal?.resume(); candidateDismissal=nil}
    func retryDraftList() async {
        if let id=presentation.pendingAssociationProjectID {await chooseDraft(id)}
        else {await presentation.retryCandidates()}
    }
    func createDraft() async {await presentation.createNew(); synchronizeSession()}
    func leave(to destination:ArticleNavigationDestination = .back) async -> Bool {
        guard !working, !leaving else { return false }
        leaving=true; defer {leaving=false}
        if await presentation.requestNavigation(destination) {synchronizeSession(); return true}
        guard presentation.pendingNavigation == destination else {return false}
        let alert = NSAlert(); alert.messageText = "未保存の変更があります"
        alert.informativeText = "記事を保存してから閉じますか？"
        alert.addButton(withTitle: "保存して閉じる"); alert.addButton(withTitle: "変更を破棄"); alert.addButton(withTitle: "編集を続ける")
        alert.buttons[2].keyEquivalent="\u{1b}"
        let response: NSApplication.ModalResponse
        if let window = NSApp.keyWindow {
            response = await withCheckedContinuation { continuation in alert.beginSheetModal(for: window) { continuation.resume(returning: $0) } }
        } else { response = alert.runModal() }
        let choice: ArticleLeaveChoice = response == .alertFirstButtonReturn ? .save : response == .alertSecondButtonReturn ? .discard : .keepEditing
        let result=await presentation.resolveNavigation(choice)
        synchronizeSession(); return result
    }
    func attach(_ window: NSWindow?) {
        // Pickerのwindow生成/焦点はSwiftUIのdelegateへ任せる。
        guard session != nil else {restoreWindowDelegate(); return}
        guard let window else {return}
        if attachedWindow === window, window.delegate === self {return}
        restoreWindowDelegate()
        attachedWindow=window; previousWindowDelegate=window.delegate; window.delegate=self
    }
    private func restoreWindowDelegate() {
        if let window=attachedWindow, window.delegate === self {window.delegate=previousWindowDelegate}
        attachedWindow=nil; previousWindowDelegate=nil
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard session != nil else { return true }
        departure.request(.closeWindow,decision:{[weak self] in await self?.leave(to:.closeWindow) ?? false},completion:{if $0 {sender.performClose(nil)}})
        return false
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard session != nil else { return .terminateNow }
        if let pending=departure.pending {return pending == .terminate ? .terminateLater : .terminateCancel}
        departure.request(.terminate,decision:{[weak self] in await self?.leave(to:.terminate) ?? false},completion:{sender.reply(toApplicationShouldTerminate:$0)})
        return .terminateLater
    }
    func probe() {
        guard !working, let session else { return }
        guard recovery == nil else {message="前回の出力を照合してから新しい出力を始めてください。"; return}
        if session.isDirty {
            let alert = NSAlert(); alert.messageText = "検証出力の前に記事を保存しますか？"
            alert.addButton(withTitle:"保存して出力"); alert.addButton(withTitle:"取り消す")
            guard alert.runModal() == .alertFirstButtonReturn else {return}
            Task { if await session.save() { probe() } }; return
        }
        guard let article = session.saved else {return}
        // 先に保存先を選ぶ。この段階より前に権限トークンは存在しない。
        destinationState = .selecting
        let url: URL
        if let fixtureDestination { url = fixtureDestination }
        else {
            let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.canCreateDirectories = true; panel.allowsMultipleSelection = false
            panel.message = "画像1枚の検証出力を作るフォルダを選択してください。"
            guard panel.runModal() == .OK, let selected = panel.url else { destinationState = .finished; return }; url = selected
        }
        let grant=ArticleDestinationGrant(url:url)
        destinationState = .selected(grant)
        working = true; message = "画像1枚を準備しています…"
        let id = UUID(); requestID = id
        exportTask = Task {
            defer { grant.release(); destinationState = .finished; working = false; requestID = nil; exportTask = nil }
            do {
                try await journal.begin(jobID:id,article:article,destination:url)
                recovery=try await journal.pending()
                let start = ContinuousClock().now
                let image = try await images.image(session.source.orderedAssetIDs[0], requestID: id)
                try Task.checkCancellation()
                guard ContinuousClock().now < start + .seconds(40) else { throw ArticleFailure.timedOut }
                let result = try await delivery.write(article: article, image: image, destination: url, jobID: id, deadline:min(start + .seconds(40),ContinuousClock().now + .seconds(10)))
                outputPath=result.directory.path
                try await journal.finish(jobID:id); recovery=nil
                message = "画像1枚の検証出力が完了しました。"
            } catch {
                let failure=error as? ArticleFailure ?? (error is CancellationError ? .cancelled : .ioFailure)
                message = failure.message
                if failure == .cleanupFailure {message += " 残存場所："+url.appendingPathComponent(".article-probe-"+id.uuidString).path}
                else if failure == .uncertainResult {message += " 照合先："+url.path}
                // 記録を保持し、片付け/確定の不明を次のジョブで隠さない。
                recovery=try? await journal.pending()
            }
        }
    }
    var outputPath=""
    func recoverProbe() async {
        guard !working, let record=recovery else {return}
        destinationState = .selecting
        let panel=NSOpenPanel(); panel.canChooseFiles=false; panel.canChooseDirectories=true
        panel.message="前回の保存先を選択してください：\(record.destinationPath)"
        guard panel.runModal() == .OK, let url=panel.url else {destinationState = .finished; return}
        let grant=ArticleDestinationGrant(url:url); destinationState = .selected(grant); working=true
        defer {grant.release(); destinationState = .finished; working=false}
        guard url.standardizedFileURL.path == record.destinationPath else {message="前回と同じ保存先を選んでください。"; return}
        do {
            let result=try await delivery.reconcile(jobID:record.jobID,projectID:record.projectID,fingerprint:record.fingerprint,destination:url)
            try await journal.finish(jobID:record.jobID); recovery=nil
            if let result {message="画像1枚の検証出力を照合しました。"; outputPath=result.directory.path}
            else {message="確定成果物はありません。識別できた一時物を片付けました。再出力できます。"}
        } catch {message=(error as? ArticleFailure ?? .ioFailure).message+" 保存先："+record.destinationPath}
    }
    func cancelProbe() { if let id = requestID { images.cancel(id) }; exportTask?.cancel() }
}

/// SwiftUI のアプリdelegateを直接差し替えず、標準Adaptorから終了調整を受ける。
@MainActor final class ArticleApplicationDelegate:NSObject,NSApplicationDelegate {
    weak var coordinator:ArticleAppCoordinator?
    func applicationDidFinishLaunching(_ notification:Notification) {
        #if DEBUG
        let arguments=ProcessInfo.processInfo.arguments
        if arguments.contains("--article-test-fixture") || arguments.contains("--ui-test-fixture") {
            print("Fixture launched: windows=\(NSApp.windows.count), modal=\(NSApp.modalWindow != nil)")
        }
        #endif
    }
    func applicationShouldTerminate(_ sender:NSApplication) ->NSApplication.TerminateReply {
        coordinator?.applicationShouldTerminate(sender) ?? .terminateNow
    }
}

@MainActor private final class ArticleDestinationGrant {
    let url:URL
    private var scoped:Bool
    init(url:URL) {self.url=url; scoped=url.startAccessingSecurityScopedResource()}
    func release() {if scoped {url.stopAccessingSecurityScopedResource(); scoped=false}}
}
private enum ArticleDestinationState {
    case idle, selecting, selected(ArticleDestinationGrant), finished
}

struct ArticleWindowAttachment: NSViewRepresentable {
    let coordinator: ArticleAppCoordinator
    func makeNSView(context: Context) -> NSView { let view = NSView(); Task { @MainActor in coordinator.attach(view.window) }; return view }
    func updateNSView(_ view: NSView, context: Context) { Task { @MainActor in coordinator.attach(view.window) } }
}

#if DEBUG
/// 実表示パスの計測専用。描画値や成功状態を偽装せず、windowの描画とfield editorを観測する。
struct ArticleFixtureDisplayProbe:NSViewRepresentable {
    let coordinator:ArticleAppCoordinator
    let revision:String
    let sessionID:UUID
    func makeNSView(context:Context)->ProbeView {ProbeView()}
    func updateNSView(_ view:ProbeView,context:Context) {
        view.coordinator=coordinator; view.observedSessionID=sessionID; view.requestMeasurement()
    }
    final class ProbeView:NSView {
        weak var coordinator:ArticleAppCoordinator?
        var observedSessionID:UUID?
        private var scheduled=false
        override func viewDidMoveToWindow() {super.viewDidMoveToWindow(); requestMeasurement()}
        func requestMeasurement() {
            guard !scheduled else {return}; scheduled=true
            DispatchQueue.main.asyncAfter(deadline:.now() + .milliseconds(1)) {[weak self] in
                guard let self else {return}
                self.scheduled=false
                guard let window=self.window else {return}
                window.displayIfNeeded()
                if self.coordinator?.completeFixtureDisplayMetrics(in:window,observedSessionID:self.observedSessionID) == false {self.requestMeasurement()}
            }
        }
    }
}
#endif
