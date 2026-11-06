import Foundation
import OSLog

public enum ArticleDiagnosticStage:String,Sendable {
    case saveStarted,saveSucceeded,imageRequested,imageConverting,imageSucceeded,probeWriting,probeSucceeded,failed
}
/// 任意文字列や記事識別子を受け付けず、分類だけを通常診断へ渡す。
public struct ArticleDiagnostics:Sendable {
    private let sink:@Sendable (String)->Void
    public init(sink:@escaping @Sendable (String)->Void) {self.sink=sink}
    public static let live=ArticleDiagnostics {line in
        Logger(subsystem:"com.yokochie.Hitotsuzuri",category:"article").info("\(line,privacy:.public)")
    }
    func record(_ stage:ArticleDiagnosticStage,failure:ArticleFailure?=nil) {
        sink(stage.rawValue+(failure.map {":"+$0.rawValue} ?? ""))
    }
}

public protocol ArticleStoring: Sendable {
    func create(projectID: UUID, operationID: UUID, source: ArticleSource, content: ArticleContent) async throws -> SavedArticle
    func open(_ projectID: UUID) async throws -> SavedArticle
    func list() async throws -> ArticleDraftList
    func save(projectID: UUID, operationID: UUID, expected: SavedArticle, content: ArticleContent) async throws -> SavedArticle
    func resumeWithSelection(projectID: UUID, operationID: UUID, expected: SavedArticle, source: ArticleSource) async throws -> SavedArticle
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
