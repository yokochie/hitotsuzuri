import Foundation

public struct SavedExportInput: Sendable, Equatable {
    public let article: SavedArticle
    public let settings: ArticleImageSettings
    public init(article: SavedArticle, settings: ArticleImageSettings = ArticleImageSettings()) { self.article=article; self.settings=settings }
}
public struct PreparedArticleExport: Sendable {
    public let savedInput: SavedExportInput
    public let rendered: RenderedArticle
    public init(savedInput: SavedExportInput, rendered: RenderedArticle) throws {
        let article=savedInput.article
        try article.validate()
        let expected=try ArticleProjectionContext(projectID:article.projectID).renderArticle(source:article.source,content:article.content)
        guard rendered.projectID == expected.projectID, rendered.sourceFingerprint == expected.sourceFingerprint,
              rendered.plainText.utf8.elementsEqual(expected.plainText.utf8), rendered.markdown.utf8.elementsEqual(expected.markdown.utf8),
              rendered.imagePaths == expected.imagePaths else { throw ArticleFailure.invalidInput }
        self.savedInput=savedInput; self.rendered=rendered
    }
}
public struct ArticleOutputCapabilities: Sendable {
    public let copy: Bool, export: Bool, reveal: Bool
    public init(copy: Bool = false, export: Bool = false, reveal: Bool = false) { self.copy=copy; self.export=export; self.reveal=reveal }
}
public enum ArticleCopyContext: Equatable, Sendable {
    case editor(projectID: UUID, fingerprint: String)
    case exported(jobID: UUID, projectID: UUID)
}
/// U3が選択済みアクセス寿命と照合する値。U2はOSのアクセス権を作らない。
public struct ArticleExportDestination: Sendable {
    public let grantID: UUID
    public let selectedDirectory: URL
    public init(grantID: UUID, selectedDirectory: URL) { self.grantID=grantID; self.selectedDirectory=selectedDirectory }
}
public struct ExportProgress: Sendable {
    public let jobID: UUID
    public let stage: String
    public let completedImages: Int
    public let fraction: Double?
    public init(jobID: UUID, stage: String, completedImages: Int, fraction: Double? = nil) { self.jobID=jobID; self.stage=stage; self.completedImages=completedImages; self.fraction=fraction }
}
public struct ExportResult: Equatable, Sendable {
    public let jobID: UUID, projectID: UUID
    public let savedRevision: Int, selectionRevision: Int
    public let fingerprint: String
    public let directory: URL
    public let fixedPlainText: String
    public init(jobID: UUID, projectID: UUID, savedRevision: Int, selectionRevision: Int, fingerprint: String, directory: URL, fixedPlainText: String) {
        self.jobID=jobID; self.projectID=projectID; self.savedRevision=savedRevision; self.selectionRevision=selectionRevision; self.fingerprint=fingerprint; self.directory=directory; self.fixedPlainText=fixedPlainText
    }
}
@MainActor public protocol ArticleOutputActions {
    var capabilities: ArticleOutputCapabilities { get }
    func copyPlainText(_ text: String, context: ArticleCopyContext) async throws
    func runExport(jobID: UUID, savedInput: SavedExportInput, rendered: RenderedArticle, destination: ArticleExportDestination, progress: @escaping @MainActor (ExportProgress) -> Void) async throws -> ExportResult
    func cancelExport(_ jobID: UUID)
    func revealExport(_ result: ExportResult) async throws
}
