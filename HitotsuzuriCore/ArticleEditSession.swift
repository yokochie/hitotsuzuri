import Foundation
import Observation

@MainActor @Observable public final class ArticleEditSession {
    public let projectID: UUID
    public let source: ArticleSource
    public var content: ArticleContent
    public private(set) var saved: SavedArticle?
    public private(set) var isSaving = false
    public private(set) var failure: ArticleFailure?
    private let store: any ArticleStoring
    private struct PendingSave {
        let id:UUID
        let content:ArticleContent
        let base:SavedArticle?
        var outcomeUnknown=false
    }
    private var pendingOperation:PendingSave?

    public init(article: SavedArticle, store: any ArticleStoring) {
        projectID = article.projectID; source = article.source; content = article.content
        saved = article; self.store = store
    }
    public init(source: ArticleSource, store: any ArticleStoring) {
        projectID = UUID(); self.source = source; content = ArticleContent(source: source)
        self.store = store
    }
    public var isDirty: Bool {
        saved.map { $0.fingerprint != ArticleFingerprint.content(source: source, content: content) } ?? true
    }
    public var state: ArticleSaveState {
        if isSaving { return .saving }
        if let failure { return .failed(failure) }
        return saved == nil ? .newUnsaved : isDirty ? .dirty : .clean
    }
    public var stateMessage: String {
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
        let snapshot = content
        isSaving = true; failure = nil
        defer { isSaving = false }
        do {
            // 追加入力で不確定操作を上書きしない。元の固定入力で照合を終えてから
            // 基準版を更新し、今回の保存写しを別操作として送る。
            if let pending=pendingOperation {
                saved=try await perform(pending)
                pendingOperation=nil
                if saved?.fingerprint == ArticleFingerprint.content(source:source,content:snapshot) {return true}
            }
            let operation=PendingSave(id:UUID(),content:snapshot,base:saved)
            pendingOperation=operation
            saved=try await perform(operation)
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
