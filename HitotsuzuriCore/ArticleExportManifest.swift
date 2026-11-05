import Foundation

enum ArticleExportLayout {
    static let imagePaths = (1...4).map { String(format: "images/%02d.jpg", $0) }
    static let artifactPaths = Set(["article.md", "manifest.json"] + imagePaths)
}

public struct ArticleExportManifest: Codable, Equatable, Sendable {
    public var schemaVersion = 1
    public let manifestID: UUID
    public let jobID: UUID
    public let projectID: UUID
    public let sourceSelectionID: UUID
    public let selectionRevision: Int
    public let savedRevision: Int
    public var inputFingerprint: String
    public var orderedAssetIDs: [String]
    public var relativeImagePaths: [String]
    public var articleRelativePath = "article.md"
    public let createdAt: Date
    public var maximumLongEdge = 2560
    public var quality = 0.9
    public var colorSpace = "sRGB"
    public var encoding = "JPEG"
    public var allowUpscale = false
    public init(jobID: UUID, prepared: PreparedArticleExport, createdAt: Date = Date(), manifestID: UUID = UUID()) {
        let article = prepared.savedInput.article
        self.manifestID = manifestID; self.jobID = jobID; projectID = article.projectID
        sourceSelectionID = article.source.selectionID; selectionRevision = article.source.selectionRevision
        savedRevision = article.savedRevision; inputFingerprint = article.fingerprint
        orderedAssetIDs = article.source.orderedAssetIDs; relativeImagePaths = prepared.rendered.imagePaths
        self.createdAt = Date(timeIntervalSince1970: floor(createdAt.timeIntervalSince1970))
        maximumLongEdge = prepared.savedInput.settings.maximumLongEdge; quality = prepared.savedInput.settings.quality
    }
    public func validate(prepared: PreparedArticleExport) throws {
        guard schemaVersion == 1 else { throw ArticleFailure.unsupportedVersion }
        let article = prepared.savedInput.article
        try article.validate()
        guard projectID == article.projectID, sourceSelectionID == article.source.selectionID,
              selectionRevision == article.source.selectionRevision, savedRevision == article.savedRevision,
              inputFingerprint == article.fingerprint, orderedAssetIDs == article.source.orderedAssetIDs,
              relativeImagePaths == ArticleExportLayout.imagePaths,
              articleRelativePath == "article.md", maximumLongEdge == 2560, quality == 0.9,
              colorSpace == "sRGB", encoding == "JPEG", !allowUpscale,
              prepared.savedInput.settings == ArticleImageSettings(), createdAt.timeIntervalSince1970.isFinite else {
            throw ArticleFailure.invalidInput
        }
    }
    public func encoded() throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
    public static func decode(_ bytes: Data) throws -> Self {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Self.self, from: bytes)
    }
}
