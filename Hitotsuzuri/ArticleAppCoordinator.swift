import SwiftUI
import AppKit
import HitotsuzuriCore

@MainActor @Observable final class ArticleAppCoordinator: NSObject, NSWindowDelegate, NSApplicationDelegate {
    var session: ArticleEditSession?
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
    private let fixtureDestination: URL?
    init(selections: any SelectionStoring, directory: URL, reader: any ArticleImageReading = PhotoKitArticleImageReader(), fixtureDestination: URL? = nil,previewImages:any ImageAccessing = LocalImageAccess()) {
        let store = ArticlePersistence(directory: directory.appendingPathComponent("Articles", isDirectory: true))
        self.store = store; workspace = ArticleWorkspace(selections: selections, articles: store)
        journal=ArticleProbeJournal(directory:directory.appendingPathComponent("ProbeRecovery",isDirectory:true))
        images = ArticleImageAccess(reader: reader); self.fixtureDestination = fixtureDestination
        self.previewImages=previewImages
    }
    private func activate(_ draft:ArticleEditSession) {
        previewTask?.cancel(); previews?.cancel()
        session=draft
        let previews=ArticlePhotoPreviews(assetIDs:draft.source.orderedAssetIDs,images:previewImages)
        self.previews=previews
        previewTask=Task {await previews.load()}
    }
    private func finishLeaving() {previewTask?.cancel(); previewTask=nil; previews?.cancel(); previews=nil; session=nil}
    func loadRecovery() async {
        do {
            recovery=try await journal.pending()
            if recovery != nil {message="前回の画像出力に確認待ちの記録があります。同じ保存先を選び直して照合してください。"}
        } catch {message=(error as? ArticleFailure ?? .ioFailure).message}
    }
    func openSavedArticle() async {
        guard session == nil, !working else {return}
        do {
            let list=try await store.list()
            guard !list.articles.isEmpty else {message=list.failures.isEmpty ? "保存した下書きはありません。" : ArticleFailure.corruptData.message; return}
            let alert=NSAlert(); alert.messageText="保存した下書きを開く"
            let menu=NSPopUpButton(frame:NSRect(x:0,y:0,width:360,height:28))
            for article in list.articles {menu.addItem(withTitle:article.content.title.isEmpty ? "タイトルなし" : article.content.title)}
            alert.accessoryView=menu; alert.addButton(withTitle:"開く"); alert.addButton(withTitle:"取り消す")
            guard alert.runModal() == .alertFirstButtonReturn else {return}
            activate(ArticleEditSession(article:list.articles[menu.indexOfSelectedItem],store:store))
        } catch {message=(error as? ArticleFailure ?? .ioFailure).message}
    }
    func openArticle() async {
        guard !working, session == nil else { return }
        working = true; defer { working = false }
        do {
            switch try await workspace.resolve() {
            case .existing(let article): activate(ArticleEditSession(article: article, store: store))
            case .newArticle(let source):
                let draft = ArticleEditSession(source: source, store: store)
                activate(draft)
                _ = await draft.save()
            case .matchingCandidates: message = "対応する下書き候補があります。無断で新しい記事は作りません。"
            }
        } catch { message = (error as? ArticleFailure ?? .ioFailure).message }
    }
    func leave() async -> Bool {
        guard let session else { return true }
        guard !working, !leaving else { return false }
        leaving=true; defer {leaving=false}
        while session.isSaving {try? await Task.sleep(for:.milliseconds(50)); if Task.isCancelled {return false}}
        guard session.isDirty else { finishLeaving(); return true }
        let alert = NSAlert(); alert.messageText = "未保存の変更があります"
        alert.informativeText = "記事を保存してから閉じますか？"
        alert.addButton(withTitle: "保存して閉じる"); alert.addButton(withTitle: "変更を破棄"); alert.addButton(withTitle: "編集を続ける")
        let response: NSApplication.ModalResponse
        if let window = NSApp.keyWindow {
            response = await withCheckedContinuation { continuation in alert.beginSheetModal(for: window) { continuation.resume(returning: $0) } }
        } else { response = alert.runModal() }
        let choice: ArticleLeaveChoice = response == .alertFirstButtonReturn ? .save : response == .alertSecondButtonReturn ? .discard : .keepEditing
        if await session.canLeave(choice) { finishLeaving(); return true }
        return false
    }
    func attach(_ window: NSWindow?) { window?.delegate = self; NSApp.delegate = self }
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard session != nil else { return true }
        Task { if await leave() { sender.close() } }; return false
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard session != nil else { return .terminateNow }
        Task { sender.reply(toApplicationShouldTerminate: await leave()) }; return .terminateLater
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
