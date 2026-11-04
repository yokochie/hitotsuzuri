import Foundation
import ImageIO
import UniformTypeIdentifiers

public struct ArticleProbeResult: Equatable, Sendable {
    public let directory: URL
}
public enum ArticleProbeCheckpoint: Sendable { case beforeCommit, afterCommit }

/// 記事一式とは区別した、先頭画像一枚だけの検証出力。
public actor ArticleProbeDelivery {
    private struct Receipt: Codable, Equatable {
        let version: Int, jobID: UUID, projectID: UUID, fingerprint: String, imageDigest: String
    }
    private let checkpoint: @Sendable (ArticleProbeCheckpoint) throws -> Void
    public init(checkpoint: @escaping @Sendable (ArticleProbeCheckpoint) throws -> Void = { _ in }) { self.checkpoint = checkpoint }
    public func write(article: SavedArticle, image: ArticleJPEG, destination: URL, jobID: UUID, deadline: ContinuousClock.Instant = ContinuousClock().now + .seconds(10)) async throws -> ArticleProbeResult {
        try article.validate()
        guard image.width > 0, image.height > 0, max(image.width, image.height) <= 2560,
              let source = CGImageSourceCreateWithData(image.bytes as CFData, nil),
              CGImageSourceGetType(source) == UTType.jpeg.identifier as CFString,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              properties[kCGImagePropertyPixelWidth] as? Int == image.width,
              properties[kCGImagePropertyPixelHeight] as? Int == image.height else { throw ArticleFailure.invalidInput }
        let receipt = Receipt(version: 1, jobID: jobID, projectID: article.projectID, fingerprint: article.fingerprint, imageDigest: ArticleFingerprint.digest(image.bytes))
        let root = try ArticleDirectory.open(destination, create: true)
        let name = "画像1枚の検証出力-" + jobID.uuidString
        let result = ArticleProbeResult(directory: destination.appendingPathComponent(name, isDirectory: true))
        func verify() throws {
            let folder = try root.child(name, create: false)
            guard try JSONDecoder().decode(Receipt.self, from: folder.read("verification.json")) == receipt,
                  ArticleFingerprint.digest(try folder.read("01.jpg")) == receipt.imageDigest else { throw ArticleFailure.conflict }
        }
        do { try verify(); return result } catch ArticleFailure.missing {} catch { throw error }
        let temporary = ".article-probe-" + UUID().uuidString
        let folder = try root.child(temporary, create: true)
        var committed = false
        do {
            try Task.checkCancellation()
            try folder.writeNew("01.jpg", data: image.bytes)
            let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
            try folder.writeNew("verification.json", data: encoder.encode(receipt))
            try folder.synchronize()
            try Task.checkCancellation()
            try checkpoint(.beforeCommit)
            guard ContinuousClock().now < deadline else { throw ArticleFailure.timedOut }
            try root.moveExclusive(temporary, to: name)
            committed = true
            try checkpoint(.afterCommit)
            return result
        } catch {
            // 確定応答を失った場合も同じ job の完全な成果物を照合する。
            if (try? verify()) != nil { return result }
            if !committed {
                do {
                    for file in ["01.jpg", "verification.json"] { do { try folder.remove(file) } catch ArticleFailure.missing {} }
                    try root.remove(temporary, directory: true)
                    try root.synchronize()
                } catch { throw ArticleFailure.cleanupFailure }
            }
            if error is CancellationError { throw ArticleFailure.cancelled }
            throw error
        }
    }
}
