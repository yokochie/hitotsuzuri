import Foundation

/// 既存選択の永続値を読む。写真プレビューの成功状態は参照しない。
public actor ArticleWorkspace {
    private let selections: any SelectionStoring
    private let articles: any ArticleStoring
    public init(selections: any SelectionStoring, articles: any ArticleStoring) {
        self.selections = selections; self.articles = articles
    }
    public func resolve() async throws -> ArticleResolution {
        let source: ArticleSource
        switch await selections.loadSelection() {
        case .valid(let value): source = try ArticleSource(selection: value)
        case .missing: throw ArticleFailure.missing
        case .failure(let failure):
            switch failure {
            case .unsupportedVersion: throw ArticleFailure.unsupportedVersion
            case .corruptData: throw ArticleFailure.corruptData
            default: throw ArticleFailure.ioFailure
            }
        }
        let list = try await articles.list()
        let exact = list.articles.filter { $0.sourceSelectionIDs.contains(source.selectionID) }
        if exact.count == 1 { return .existing(exact[0]) }
        if exact.count > 1 { return .matchingCandidates(exact) }
        // 読めない記事を「下書きなし」にして新規作成することを防ぐ。
        guard list.failures.isEmpty else { throw ArticleFailure.corruptData }
        let matching = list.articles.filter { $0.source.albumID == source.albumID && $0.source.orderedAssetIDs == source.orderedAssetIDs }
        return matching.isEmpty ? .newArticle(source) : .matchingCandidates(matching)
    }
}
