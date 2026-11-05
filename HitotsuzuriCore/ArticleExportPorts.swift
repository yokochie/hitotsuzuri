import Foundation

@MainActor public protocol ArticleExportImageProviding: Sendable {
    var isBusy: Bool { get }
    var reservedImageBytes: Int { get }
    var peakReservedImageBytes: Int { get }
    func image(_ assetID: String, requestID: UUID) async throws -> ArticleJPEG
    func cancel(_ requestID: UUID)
}
extension ArticleImageAccess: ArticleExportImageProviding { }

public typealias ArticleExportProgressSink = @Sendable (ExportProgress) async -> Void
public typealias ArticleExportWriterFactory = @Sendable (URL, ArticleExportRecoveryRecord) -> ArticleExportWriter

public struct ArticleExportFailureDetail: Equatable, Sendable {
    public let failure: ArticleFailure
    public let photoIndex: Int?
    public let residualDirectory: URL?
}

@MainActor public protocol ArticleExportFailureDescribing {
    var lastFailureDetail: ArticleExportFailureDetail? { get }
}
