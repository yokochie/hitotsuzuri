import Foundation

public protocol ArticleStoring: Sendable {
    func create(projectID: UUID, operationID: UUID, source: ArticleSource, content: ArticleContent) async throws -> SavedArticle
    func open(_ projectID: UUID) async throws -> SavedArticle
    func list() async throws -> ArticleDraftList
    func save(projectID: UUID, operationID: UUID, expected: SavedArticle, content: ArticleContent) async throws -> SavedArticle
}

public enum ArticleResolution: Sendable {
    case existing(SavedArticle)
    case newArticle(ArticleSource)
    case matchingCandidates([SavedArticle])
}

public enum ArticleSaveState: Equatable, Sendable { case newUnsaved, clean, dirty, saving, failed(ArticleFailure) }
public enum ArticleLeaveChoice: Sendable { case save, discard, keepEditing }

public struct ArticleImageSettings: Equatable, Sendable {
    public var maximumLongEdge = 2560
    public var quality = 0.9
    public init() {}
}
