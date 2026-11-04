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
    private var pendingOperation: (id: UUID, input: String, revision: Int?)?

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
        let snapshot = content, base = saved
        let input = ArticleFingerprint.content(source: source, content: snapshot)
        let operation: UUID
        if let pending = pendingOperation, pending.input == input, pending.revision == base?.savedRevision { operation = pending.id }
        else { operation = UUID(); pendingOperation = (operation, input, base?.savedRevision) }
        isSaving = true; failure = nil
        defer { isSaving = false }
        do {
            if let base {
                saved = try await store.save(projectID: projectID, operationID: operation, expected: base, content: snapshot)
            } else {
                saved = try await store.create(projectID: projectID, operationID: operation, source: source, content: snapshot)
            }
            pendingOperation = nil
            return true
        } catch {
            failure = error as? ArticleFailure ?? .ioFailure
            return false
        }
    }
    public func canLeave(_ choice: ArticleLeaveChoice) async -> Bool {
        switch choice {
        case .keepEditing: return false
        case .discard: return !isSaving
        case .save: return await save() && !isDirty
        }
    }
}
