import Foundation
import Observation

@MainActor @Observable public final class ArticleEditSession {
    public let sessionID = UUID()
    public let projectID: UUID
    public let source: ArticleSource
    public var content: ArticleContent
    public var metadataInput: ArticleMetadataInput
    public private(set) var saved: SavedArticle?
    public private(set) var isSaving = false
    public private(set) var failure: ArticleFailure?
    private let store: any ArticleStoring
    private var savedMetadataInput: ArticleMetadataInput?
    private struct PendingSave {
        let id:UUID
        let content:ArticleContent
        let base:SavedArticle?
        let metadata:ArticleMetadataInput
        var outcomeUnknown=false
    }
    private var pendingOperation:PendingSave?

    public init(article: SavedArticle, store: any ArticleStoring) {
        projectID = article.projectID; source = article.source; content = article.content
        metadataInput = ArticleMetadataInput(content: article.content)
        savedMetadataInput = ArticleMetadataInput(content: article.content)
        saved = article; self.store = store
    }
    public init(source: ArticleSource, store: any ArticleStoring, initialContent: ArticleContent? = nil) {
        let value=initialContent ?? ArticleContent(source: source)
        projectID = UUID(); self.source = source; content = value
        metadataInput = ArticleMetadataInput(content: value)
        self.store = store
    }
    public var hasUncertainSave: Bool { pendingOperation?.outcomeUnknown == true }
    public func validatedContent() throws -> ArticleContent {
        let value=try metadataInput.applying(to:content)
        try value.validate(source:source)
        return value
    }
    public var isDirty: Bool {
        guard let value=try? validatedContent() else { return true }
        return saved.map { $0.fingerprint != ArticleFingerprint.content(source: source, content: value) || metadataInput != savedMetadataInput } ?? true
    }
    public var state: ArticleSaveState {
        if isSaving { return .saving }
        if let failure { return .failed(failure) }
        return saved == nil ? .newUnsaved : isDirty ? .dirty : .clean
    }
    public var stateMessage: String {
        if hasUncertainSave { return "保存結果を照合する必要があります。" + (failure.map { " " + $0.message } ?? "") }
        if let message=metadataInput.validationMessage { return message }
        return saveStateMessage
    }
    private var saveStateMessage: String {
        switch state {
        case .newUnsaved: "未保存の記事"
        case .clean: "下書きを保存しました。"
        case .dirty: "未保存の変更があります。"
        case .saving: "下書きを保存中…"
        case .failed(let failure): failure.message
        }
    }

    @discardableResult public func save() async -> Bool {
        guard !isSaving else { return false }
        let snapshot:ArticleContent
        do { snapshot=try validatedContent() }
        catch { failure=error as? ArticleFailure ?? .invalidInput; return false }
        let snapshotMetadata=metadataInput
        isSaving = true; failure = nil
        defer { isSaving = false }
        do {
            // 追加入力で不確定操作を上書きしない。元の固定入力で照合を終えてから
            // 基準版を更新し、今回の保存写しを別操作として送る。
            if let pending=pendingOperation {
                saved=try await perform(pending)
                savedMetadataInput=pending.metadata
                pendingOperation=nil
                if saved?.fingerprint == ArticleFingerprint.content(source:source,content:snapshot) {return true}
            }
            let operation=PendingSave(id:UUID(),content:snapshot,base:saved,metadata:snapshotMetadata)
            pendingOperation=operation
            saved=try await perform(operation)
            savedMetadataInput=operation.metadata
            pendingOperation = nil
            return true
        } catch {
            failure = error as? ArticleFailure ?? .ioFailure
            if failure == .uncertainResult {pendingOperation?.outcomeUnknown=true}
            // 元操作の結果不明は、照合が一時的に失敗しても解消していない。
            // 照合成功後の新操作は別pendingなので、確定した失敗なら解放できる。
            if pendingOperation?.outcomeUnknown != true {pendingOperation=nil}
            return false
        }
    }
    private func perform(_ operation:PendingSave) async throws ->SavedArticle {
        if let base=operation.base {
            return try await store.save(projectID:projectID,operationID:operation.id,expected:base,content:operation.content)
        }
        return try await store.create(projectID:projectID,operationID:operation.id,source:source,content:operation.content)
    }
    public func canLeave(_ choice: ArticleLeaveChoice) async -> Bool {
        switch choice {
        case .keepEditing: return false
        case .discard: return !isSaving
        case .save: return await save() && !isDirty
        }
    }
}
