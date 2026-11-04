import SwiftUI
import AppKit
import HitotsuzuriCore

@MainActor @Observable final class ArticleAppCoordinator: NSObject, NSWindowDelegate, NSApplicationDelegate {
    var session: ArticleEditSession?
    var message = ""
    var working = false
    private let workspace: ArticleWorkspace
    private let store: any ArticleStoring
    private let images: ArticleImageAccess
    private let delivery = ArticleProbeDelivery()
    private var exportTask: Task<Void, Never>?
    private var requestID: UUID?
    private let fixtureDestination: URL?
    init(selections: any SelectionStoring, directory: URL, reader: any ArticleImageReading = PhotoKitArticleImageReader(), fixtureDestination: URL? = nil) {
        let store = ArticlePersistence(directory: directory.appendingPathComponent("Articles", isDirectory: true))
        self.store = store; workspace = ArticleWorkspace(selections: selections, articles: store)
        images = ArticleImageAccess(reader: reader); self.fixtureDestination = fixtureDestination
    }
    func openArticle() async {
        guard !working, session == nil else { return }
        working = true; defer { working = false }
        do {
            switch try await workspace.resolve() {
            case .existing(let article): session = ArticleEditSession(article: article, store: store)
            case .newArticle(let source):
                let draft = ArticleEditSession(source: source, store: store)
                session = draft
                _ = await draft.save()
            case .matchingCandidates: message = "対応する下書き候補があります。無断で新しい記事は作りません。"
            }
        } catch { message = (error as? ArticleFailure ?? .ioFailure).message }
    }
    func leave() async -> Bool {
        guard let session else { return true }
        guard !working, !session.isSaving else { return false }
        guard session.isDirty else { self.session = nil; return true }
        let alert = NSAlert(); alert.messageText = "未保存の変更があります"
        alert.informativeText = "記事を保存してから閉じますか？"
        alert.addButton(withTitle: "保存して閉じる"); alert.addButton(withTitle: "変更を破棄"); alert.addButton(withTitle: "編集を続ける")
        let response: NSApplication.ModalResponse
        if let window = NSApp.keyWindow {
            response = await withCheckedContinuation { continuation in alert.beginSheetModal(for: window) { continuation.resume(returning: $0) } }
        } else { response = alert.runModal() }
        let choice: ArticleLeaveChoice = response == .alertFirstButtonReturn ? .save : response == .alertSecondButtonReturn ? .discard : .keepEditing
        if await session.canLeave(choice) { self.session = nil; return true }
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
        if session.isDirty {
            let alert = NSAlert(); alert.messageText = "検証出力の前に記事を保存しますか？"
            alert.addButton(withTitle:"保存して出力"); alert.addButton(withTitle:"取り消す")
            guard alert.runModal() == .alertFirstButtonReturn else {return}
            Task { if await session.save() { probe() } }; return
        }
        guard let article = session.saved else {return}
        // 先に保存先を選ぶ。この段階より前に権限トークンは存在しない。
        let url: URL
        if let fixtureDestination { url = fixtureDestination }
        else {
            let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.canCreateDirectories = true; panel.allowsMultipleSelection = false
            panel.message = "画像1枚の検証出力を作るフォルダを選択してください。"
            guard panel.runModal() == .OK, let selected = panel.url else { return }; url = selected
        }
        let scoped = url.startAccessingSecurityScopedResource()
        working = true; message = "画像1枚を準備しています…"
        let id = UUID(); requestID = id
        exportTask = Task {
            defer { if scoped { url.stopAccessingSecurityScopedResource() }; working = false; requestID = nil; exportTask = nil }
            do {
                let start = ContinuousClock().now
                let image = try await images.image(session.source.orderedAssetIDs[0], requestID: id)
                try Task.checkCancellation()
                guard ContinuousClock().now < start + .seconds(40) else { throw ArticleFailure.timedOut }
                _ = try await delivery.write(article: article, image: image, destination: url, jobID: id, deadline:min(start + .seconds(40),ContinuousClock().now + .seconds(10)))
                message = "画像1枚の検証出力が完了しました。"
            } catch { message = (error as? ArticleFailure ?? (error is CancellationError ? .cancelled : .ioFailure)).message }
        }
    }
    func cancelProbe() { if let id = requestID { images.cancel(id) }; exportTask?.cancel() }
}

struct ArticleWindowAttachment: NSViewRepresentable {
    let coordinator: ArticleAppCoordinator
    func makeNSView(context: Context) -> NSView { let view = NSView(); Task { @MainActor in coordinator.attach(view.window) }; return view }
    func updateNSView(_ view: NSView, context: Context) { Task { @MainActor in coordinator.attach(view.window) } }
}
