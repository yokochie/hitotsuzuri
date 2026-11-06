import Foundation
import ImageIO
import UniformTypeIdentifiers
@testable import HitotsuzuriCore

enum ExportFixture {
    @MainActor static func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock().now + .seconds(5)
        while !condition() {
            guard ContinuousClock().now < deadline else { throw ArticleFailure.timedOut }
            try await Task.sleep(for: .milliseconds(1))
        }
    }
    static func root(_ label: String = "run") throws -> URL {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".build/export-" + label + "-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
    static func prepared(title: String = "日本語\n\"引用\" 👨‍👩‍👧‍👦") throws -> PreparedArticleExport {
        let source = try ArticleSource(selection: CommittedSelection(albumID: "fixture", albumTitle: title, orderedAssetIDs: ["a", "b", "c", "d"]))
        var content = ArticleContent(source: source)
        content.introduction = "本文\n*記号*"; content.location = "  "
        let article = try SavedArticle(projectID: UUID(), source: source, content: content)
        let rendered = try ArticleProjectionContext(projectID: article.projectID).renderArticle(source: source, content: content)
        return try PreparedArticleExport(savedInput: SavedExportInput(article: article), rendered: rendered)
    }
    static let identity = ArticleExportDirectoryIdentity(device: 1, inode: 2, createdSeconds: 3, createdNanoseconds: 4)
    static func jpeg() throws -> ArticleJPEG {
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CGContext(data: nil, width: 2, height: 2, bitsPerComponent: 8, bytesPerRow: 8, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ArticleFailure.ioFailure }
        return ArticleJPEG(bytes: data as Data, width: 2, height: 2)
    }
}

@MainActor final class ExportTestImages: ArticleExportImageProviding {
    var isBusy = false
    var reservedImageBytes = 0
    var peakReservedImageBytes = 0
    var calls: [String] = []
    var requestIDs: [UUID] = []
    var cancelled: [UUID] = []
    var failureAt: Int?
    var onRequest: (@MainActor (Int) async -> Void)?
    var pause: U3Latch?
    var convert: (@MainActor () throws -> ArticleJPEG)?
    func image(_ assetID: String, requestID: UUID) async throws -> ArticleJPEG {
        isBusy = true; calls.append(assetID); requestIDs.append(requestID)
        defer { isBusy = false }
        await onRequest?(calls.count)
        await pause?.wait()
        if cancelled.contains(requestID) { throw ArticleFailure.cancelled }
        if failureAt == calls.count { throw ArticleFailure.assetUnavailable }
        return try convert?() ?? ExportFixture.jpeg()
    }
    func cancel(_ requestID: UUID) { cancelled.append(requestID); pause?.open() }
}

final class ExportTestClock: @unchecked Sendable {
    private let lock = NSLock()
    private let base = ContinuousClock().now
    private var offset: Duration = .zero
    func advance(_ duration: Duration) { lock.lock(); offset += duration; lock.unlock() }
    func now() -> ContinuousClock.Instant { lock.lock(); defer { lock.unlock() }; return base + offset }
}

@MainActor final class ExportTestActions: ArticleOutputActions {
    let capabilities = ArticleOutputCapabilities(copy: true, export: true, reveal: true)
    var calls = 0
    var cancelCalls = 0
    var copied: String?
    var runFailure: ArticleFailure?
    var pause: U3Latch?
    func copyPlainText(_ text: String, context: ArticleCopyContext) async throws { copied = text }
    func runExport(jobID: UUID, savedInput: SavedExportInput, rendered: RenderedArticle, destination: ArticleExportDestination, progress: @escaping @MainActor (ExportProgress) -> Void) async throws -> ExportResult {
        calls += 1; progress(ExportProgress(jobID: jobID, stage: "acquiring", completedImages: 1))
        await pause?.wait()
        if let runFailure { throw runFailure }
        return ExportResult(jobID: jobID, projectID: savedInput.article.projectID, savedRevision: savedInput.article.savedRevision, selectionRevision: savedInput.article.source.selectionRevision, fingerprint: savedInput.article.fingerprint, directory: destination.selectedDirectory, fixedPlainText: rendered.plainText)
    }
    func cancelExport(_ jobID: UUID) { cancelCalls += 1; runFailure = .cancelled; pause?.open() }
    func revealExport(_ result: ExportResult) async throws { }
}
