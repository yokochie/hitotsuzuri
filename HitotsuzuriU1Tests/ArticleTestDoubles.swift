import Foundation
@testable import HitotsuzuriCore

enum ArticleFixtures {
    static func source() throws -> ArticleSource {
        try ArticleSource(selection: CommittedSelection(albumID: "album", albumTitle: "記事", orderedAssetIDs: ["a", "b", "c", "d"]))
    }
    static func root() -> URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent(".build/article-tests/\(UUID().uuidString)")
    }
    static func create(_ store: ArticlePersistence) async throws -> SavedArticle {
        let s = try source()
        return try await store.create(projectID: UUID(), operationID: UUID(), source: s, content: ArticleContent(source: s))
    }
}
