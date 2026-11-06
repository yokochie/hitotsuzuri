import Foundation

public enum ArticleExportPhase: String, Codable, Sendable {
    case prepared, generating, publishing, succeeded, cancelled, failed, cleanupFailed, needsReconciliation
}

/// 実体の再選択・公開照合に用いる。URL文字列を所有の証明にしない。
public struct ArticleExportDirectoryIdentity: Codable, Equatable, Sendable {
    public let device: UInt64
    public let inode: UInt64
    public let createdSeconds: Int64
    public let createdNanoseconds: Int64
}

public struct ArticleExportRecoveryRecord: Codable, Equatable, Sendable {
    public var schemaVersion = 1
    public let jobID: UUID
    public let article: SavedArticle
    public let fixedPlainText: String
    public let markdown: String
    public let parentIdentity: ArticleExportDirectoryIdentity
    public let ownershipToken: UUID
    public var phase: ArticleExportPhase = .prepared
    public var stagingIdentity: ArticleExportDirectoryIdentity?
    public var imagesIdentity: ArticleExportDirectoryIdentity?
    public var expectedDigests: [String: String] = [:]
    public var originalFailure: ArticleFailure?
    public var stagingName: String { ".article-export-" + jobID.uuidString.lowercased() }
    public var finalName: String { "記事-" + jobID.uuidString.lowercased() }
    public init(jobID: UUID, prepared: PreparedArticleExport, parentIdentity: ArticleExportDirectoryIdentity, ownershipToken: UUID = UUID()) {
        self.jobID = jobID; article = prepared.savedInput.article
        fixedPlainText = prepared.rendered.plainText; markdown = prepared.rendered.markdown
        self.parentIdentity = parentIdentity; self.ownershipToken = ownershipToken
    }
    public func validate() throws {
        guard schemaVersion == 1 else { throw ArticleFailure.unsupportedVersion }
        try article.validate()
        let rendered = try ArticleProjectionContext(projectID: article.projectID).renderArticle(source: article.source, content: article.content)
        guard fixedPlainText.utf8.elementsEqual(rendered.plainText.utf8), markdown.utf8.elementsEqual(rendered.markdown.utf8),
              parentIdentity.inode > 0 else { throw ArticleFailure.corruptData }
        let allowed = ArticleExportLayout.artifactPaths
        guard Set(expectedDigests.keys).isSubset(of: allowed), expectedDigests.values.allSatisfy({ $0.count == 64 && $0.allSatisfy(\.isHexDigit) }) else {
            throw ArticleFailure.corruptData
        }
        if phase == .publishing || phase == .succeeded {
            guard stagingIdentity != nil, Set(expectedDigests.keys) == allowed else { throw ArticleFailure.corruptData }
        }
    }
}
