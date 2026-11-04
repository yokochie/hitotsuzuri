import Foundation
import Observation

public enum ArticleDisplayMode: Sendable { case editing, preview }
public enum ArticleNavigationDestination: Equatable, Sendable { case back, closeWindow, terminate, article(UUID), currentSelection, reload }
public typealias ArticleProjector = @Sendable (ArticleProjectionContext, ArticleSource, ArticleContent) async throws -> RenderedArticle

/// ウィンドウ/アプリ終了の一回だけのOS応答を扱う。
@MainActor public final class ArticleDepartureBridge {
    public private(set) var pending: ArticleNavigationDestination?
    public init() {}
    @discardableResult public func request(_ destination: ArticleNavigationDestination, decision: @escaping @MainActor () async -> Bool, completion: @escaping @MainActor (Bool) -> Void) -> Bool {
        guard pending == nil else { return false }
        pending=destination
        Task {
            let result=await decision()
            pending=nil
            completion(result)
        }
        return true
    }
}

/// 永続値はEditSessionだけが持ち、画面操作の保留先を一つに限定する。
@MainActor @Observable public final class ArticlePresentation {
    public private(set) var session: ArticleEditSession?
    public private(set) var candidates: ArticleDraftList?
    public private(set) var allowsNew = false
    public private(set) var isLoading = false
    public private(set) var isProjecting = false
    public private(set) var mode: ArticleDisplayMode = .editing
    public private(set) var rendered: RenderedArticle?
    public private(set) var message: String?
    public private(set) var failure: ArticleFailure?
    public private(set) var pendingNavigation: ArticleNavigationDestination?
    private let workspace: ArticleWorkspace
    private let store: any ArticleStoring
    private let output: (any ArticleOutputActions)?
    private let projector: ArticleProjector
    private var entrySource: ArticleSource?
    private var copying=false
    private var previewIntent=UUID()
    private var projectionRequestID:UUID?
    private var approvedDepartureSessionID:UUID?
    private var pendingNew:ArticleEditSession?
    private struct Association {
        let operationID: UUID
        let expected: SavedArticle
        let source: ArticleSource
        var uncertain=false
    }
    private var association: Association?
    public init(workspace: ArticleWorkspace, store: any ArticleStoring, output: (any ArticleOutputActions)? = nil, projector: @escaping ArticleProjector = { context,source,content in
        try await Task.detached { try context.renderArticle(source:source,content:content) }.value
    }) {
        self.workspace=workspace; self.store=store; self.output=output; self.projector=projector
    }
    public var capabilities: ArticleOutputCapabilities { output?.capabilities ?? ArticleOutputCapabilities() }
    public var pendingAssociationProjectID:UUID? {association?.expected.projectID}
    public func retryCandidates() async {
        guard !isLoading, candidates != nil, association == nil else {return}
        isLoading=true; failure=nil; message=nil
        defer {isLoading=false}
        do {
            let list=try await workspace.listDrafts()
            if let source=entrySource {
                let exact=list.articles.filter {$0.sourceSelectionIDs.contains(source.selectionID)}
                let matching=exact.isEmpty ? list.articles.filter {$0.source.albumID == source.albumID && $0.source.orderedAssetIDs == source.orderedAssetIDs} : exact
                candidates=ArticleDraftList(articles:matching,failures:list.failures)
                allowsNew=exact.isEmpty && list.failures.isEmpty
            } else {candidates=list}
        } catch {allowsNew=false; report(error)}
    }
    public func adopt(_ session: ArticleEditSession) {
        previewIntent=UUID()
        self.session=session; mode = .editing; rendered=nil; message=nil; failure=nil; approvedDepartureSessionID=nil
    }
    public func beginCurrentSelection() async {
        guard !isLoading, candidates == nil, pendingNavigation == nil else { return }
        if session != nil { _=await requestNavigation(.currentSelection); return }
        _=await loadCurrent()
    }
    private func loadCurrent() async ->Bool {
        isLoading=true; failure=nil; message=nil
        defer { isLoading=false }
        let old=session, content=session?.content, metadata=session?.metadataInput
        do {
            let source=try await workspace.readCommittedSelection()
            if pendingNew?.source == source { return await startNew(source) }
            let list=try await workspace.listDrafts()
            guard canReplace(old,content:content,metadata:metadata) else {return false}
            entrySource=source
            let exact=list.articles.filter { $0.sourceSelectionIDs.contains(source.selectionID) }
            if exact.count == 1 {
                let article=try await workspace.openArticle(exact[0].id)
                guard canReplace(old,content:content,metadata:metadata) else {return false}
                adopt(ArticleEditSession(article:article,store:store)); return true
            }
            let matching=exact.isEmpty ? list.articles.filter { $0.source.albumID == source.albumID && $0.source.orderedAssetIDs == source.orderedAssetIDs } : exact
            allowsNew=exact.isEmpty && list.failures.isEmpty
            if matching.isEmpty && list.failures.isEmpty { return await startNew(source) }
            candidates=ArticleDraftList(articles:matching,failures:list.failures)
            return true
        } catch { report(error); return false }
    }
    public func openDrafts() async {
        guard !isLoading, candidates == nil, pendingNavigation == nil else { return }
        isLoading=true; failure=nil; message=nil
        defer { isLoading=false }
        do { candidates=try await workspace.listDrafts(); entrySource=nil; allowsNew=false }
        catch { report(error) }
    }
    public func createNew() async {
        guard !isLoading, allowsNew, let source=entrySource, association == nil else { return }
        isLoading=true; defer { isLoading=false }
        _=await startNew(source)
    }
    private func startNew(_ source: ArticleSource) async ->Bool {
        let old=session, content=session?.content, metadata=session?.metadataInput
        let initial=ArticleInitialContent(source:source)
        let next:ArticleEditSession
        if let prepared=pendingNew, prepared.source == source {next=prepared}
        else {next=ArticleEditSession(source:source,store:store,initialContent:initial.content)}
        let success=await next.save()
        if !success, session != nil {
            pendingNew=next; report(next.failure ?? ArticleFailure.ioFailure); return false
        }
        guard canReplace(old,content:content,metadata:metadata) else {pendingNew=next; return false}
        pendingNew=nil
        adopt(next); candidates=nil; entrySource=nil; allowsNew=false
        if initial.invalidDateSuffix { message="末尾の日付は実在しないため候補にしませんでした。年月日を手動入力できます。" }
        return success
    }
    public func chooseExisting(_ id: UUID) async {
        guard !isLoading, let candidates, candidates.articles.contains(where:{$0.id == id}) else { return }
        if let association, association.expected.id != id { return }
        if let current=session, approvedDepartureSessionID != current.sessionID, current.isDirty || current.hasUncertainSave || current.isSaving {
            if pendingNavigation == nil { pendingNavigation = .article(id) }; return
        }
        _=await prepareExisting(id)
    }
    private func prepareExisting(_ id: UUID) async -> Bool {
        isLoading=true; failure=nil; defer { isLoading=false }
        let old=session, content=session?.content, metadata=session?.metadataInput
        do {
            let opened:SavedArticle
            if let pending=association {
                opened=try await workspace.resumeWithSelection(operationID:pending.operationID,expected:pending.expected,source:pending.source)
            } else {
                let current=try await workspace.openArticle(id)
                if let source=entrySource, !current.sourceSelectionIDs.contains(source.selectionID) {
                    let pending=Association(operationID:UUID(),expected:current,source:source)
                    association=pending
                    opened=try await workspace.resumeWithSelection(operationID:pending.operationID,expected:current,source:source)
                } else { opened=current }
            }
            association=nil
            guard canReplace(old,content:content,metadata:metadata) else {return false}
            adopt(ArticleEditSession(article:opened,store:store))
            candidates=nil; entrySource=nil; allowsNew=false; return true
        } catch {
            if error as? ArticleFailure == .uncertainResult { association?.uncertain=true }
            if association?.uncertain != true { association=nil }
            report(error); return false
        }
    }
    public func cancelCandidates() {
        guard !isLoading, association == nil else { return }
        candidates=nil; entrySource=nil; allowsNew=false; approvedDepartureSessionID=nil
    }
    public func requestNavigation(_ destination: ArticleNavigationDestination) async -> Bool {
        guard pendingNavigation == nil, !isLoading else { return false }
        if let session, session.isDirty || session.isSaving || session.hasUncertainSave {
            pendingNavigation=destination; return false
        }
        return await navigate(destination)
    }
    public func resolveNavigation(_ choice: ArticleLeaveChoice) async -> Bool {
        guard let destination=pendingNavigation else { return false }
        if case .keepEditing=choice { pendingNavigation=nil; return false }
        guard let session, !session.isSaving else { return false }
        if case .save=choice {
            guard await session.save(), !session.isDirty, !session.hasUncertainSave else { return false }
        }
        if destination == .currentSelection { approvedDepartureSessionID=session.sessionID }
        let success=await navigate(destination)
        if success { pendingNavigation=nil }
        return success
    }
    private func navigate(_ destination: ArticleNavigationDestination) async -> Bool {
        switch destination {
        case .article(let id): return await prepareExisting(id)
        case .reload:
            guard let session else { return false }
            return await prepareExisting(session.projectID)
        case .currentSelection:
            // 読込が失敗した場合、旧作業を維持する。
            let old=session
            if !(await loadCurrent()) {session=old; return false}
            return true
        case .back,.closeWindow,.terminate:
            session=nil; mode = .editing; rendered=nil; message=nil; return true
        }
    }
    public func showPreview() async {
        guard !isProjecting, let session else { return }
        failure=nil; message=nil
        let id=session.sessionID, intent=previewIntent
        let metadata=session.metadataInput
        do {
            let content=try session.validatedContent()
            let fingerprint=ArticleFingerprint.content(source:session.source,content:content)
            let result=try await projectFixed(projectID:session.projectID,source:session.source,content:content)
            guard self.session?.sessionID == id, previewIntent == intent else { return }
            guard session.metadataInput == metadata, let current=try? session.validatedContent(), ArticleFingerprint.content(source:session.source,content:current) == fingerprint else {
                mode = .editing; rendered=nil; message="内容が変わったため再表示してください。"; return
            }
            rendered=result; mode = .preview
        } catch {
            if self.session?.sessionID == id, previewIntent == intent { report(error); mode = .editing }
        }
    }
    public func showEditor() {previewIntent=UUID(); mode = .editing; rendered=nil}
    public func copyCurrent() async -> Bool {
        guard !copying, !isProjecting, let session, let output, output.capabilities.copy else { return false }
        copying=true; failure=nil; message=nil; defer { copying=false }
        let id=session.sessionID
        do {
            let content=try session.validatedContent()
            let result=try await projectFixed(projectID:session.projectID,source:session.source,content:content)
            try await output.copyPlainText(result.plainText,context:.editor(projectID:session.projectID,fingerprint:result.sourceFingerprint))
            if self.session?.sessionID == id { message="操作時点の本文をコピーしました。" }
            return true
        } catch { if self.session?.sessionID == id { report(error) }; return false }
    }
    public func prepareSavedExport(_ choice: ArticleLeaveChoice) async throws -> SavedExportInput? {
        guard let session, !session.isSaving else { throw ArticleFailure.busy }
        _=try session.validatedContent()
        if session.isDirty || session.hasUncertainSave {
            guard case .save=choice else { return nil }
            guard await session.save() else { throw session.failure ?? ArticleFailure.ioFailure }
        }
        guard let saved=session.saved else { throw ArticleFailure.missing }
        return SavedExportInput(article:saved)
    }
    private func report(_ error: Error) {
        failure=error as? ArticleFailure ?? .ioFailure; message=failure?.message
    }
    /// 表示意図の取消と、実処理一件の所有を分離する。編集へ戻っても旧処理の
    /// 終了まで次を受け付けず、処理IDの一致したdeferだけがゲートを解放する。
    private func projectFixed(projectID:UUID,source:ArticleSource,content:ArticleContent) async throws ->RenderedArticle {
        guard projectionRequestID == nil else {throw ArticleFailure.busy}
        let request=UUID()
        projectionRequestID=request; isProjecting=true
        defer {if projectionRequestID == request {projectionRequestID=nil; isProjecting=false}}
        let result=try await projector(ArticleProjectionContext(projectID:projectID),source,content)
        guard result.projectID == projectID, result.sourceFingerprint == ArticleFingerprint.content(source:source,content:content) else {throw ArticleFailure.invalidInput}
        return result
    }
    private func canReplace(_ old:ArticleEditSession?,content:ArticleContent?,metadata:ArticleMetadataInput?)->Bool {
        let bytesMatch:Bool
        if let old, let content {bytesMatch=ArticleFingerprint.content(source:old.source,content:old.content) == ArticleFingerprint.content(source:old.source,content:content)}
        else {bytesMatch=old == nil && content == nil}
        guard session?.sessionID == old?.sessionID, bytesMatch, old?.metadataInput == metadata else {
            message="読込中に入力が変わったため切り替えませんでした。内容を確認して再度選択してください。"
            return false
        }
        return true
    }
}
