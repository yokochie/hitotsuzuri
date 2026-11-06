import Foundation
import ImageIO
import UniformTypeIdentifiers

public struct ArticleProbeResult: Equatable, Sendable {
    public let directory: URL
}
public enum ArticleProbeCheckpoint: Sendable { case beforeReceipt,beforeImage,beforeCommit,renamedBeforeSync,afterCommit }

/// 記事一式とは区別した、先頭画像一枚だけの検証出力。
public actor ArticleProbeDelivery {
    private struct Receipt: Codable, Equatable {
        let version: Int, jobID: UUID, projectID: UUID, fingerprint: String, imageDigest: String
    }
    private let checkpoint: @Sendable (ArticleProbeCheckpoint) throws -> Void
    private let diagnostics:ArticleDiagnostics
    public init(checkpoint: @escaping @Sendable (ArticleProbeCheckpoint) throws -> Void = { _ in },diagnostics:ArticleDiagnostics = .live) { self.checkpoint = checkpoint; self.diagnostics=diagnostics }
    public func reconcile(jobID:UUID,projectID:UUID,fingerprint:String,destination:URL) throws ->ArticleProbeResult? {
        let root=try ArticleDirectory.open(destination,create:false)
        let name="画像1枚の検証出力-"+jobID.uuidString
        let final:ArticleDirectory?
        do {final=try root.child(name,create:false)} catch ArticleFailure.missing {final=nil}
        if let folder=final {
            do {
                let receipt=try JSONDecoder().decode(Receipt.self,from:folder.read("verification.json"))
                guard receipt.version == 1, receipt.jobID == jobID, receipt.projectID == projectID, receipt.fingerprint == fingerprint,
                      ArticleFingerprint.digest(try folder.read("01.jpg")) == receipt.imageDigest else {throw ArticleFailure.corruptData}
                try root.synchronize()
                return ArticleProbeResult(directory:destination.appendingPathComponent(name,isDirectory:true))
            } catch ArticleFailure.missing {throw ArticleFailure.corruptData}
            catch is DecodingError {throw ArticleFailure.corruptData}
        } else {
            let temporary=".article-probe-"+jobID.uuidString
            let folder:ArticleDirectory
            do {folder=try root.child(temporary,create:false)} catch ArticleFailure.missing {return nil}
            // 記録を照合できない一時物は別物として保護する。
            let receipt=try JSONDecoder().decode(Receipt.self,from:folder.read("verification.json"))
            guard receipt.version == 1, receipt.jobID == jobID, receipt.projectID == projectID, receipt.fingerprint == fingerprint else {throw ArticleFailure.invalidReference}
            do {
                do {try folder.remove("01.jpg")} catch ArticleFailure.missing {}
                try folder.remove("verification.json"); try root.remove(temporary,directory:true); try root.synchronize()
            } catch {throw ArticleFailure.cleanupFailure}
            return nil
        }
    }
    public func write(article: SavedArticle, image: ArticleJPEG, destination: URL, jobID: UUID, deadline: ContinuousClock.Instant = ContinuousClock().now + .seconds(10)) async throws -> ArticleProbeResult {
        diagnostics.record(.probeWriting)
        do {
            let result=try writeOutput(article:article,image:image,destination:destination,jobID:jobID,deadline:deadline)
            diagnostics.record(.probeSucceeded); return result
        } catch {diagnostics.record(.failed,failure:error as? ArticleFailure ?? .ioFailure); throw error}
    }
    private func writeOutput(article:SavedArticle,image:ArticleJPEG,destination:URL,jobID:UUID,deadline:ContinuousClock.Instant) throws ->ArticleProbeResult {
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
            try root.synchronize()
        }
        do { try verify(); return result } catch ArticleFailure.missing {} catch { throw error }
        let temporary = ".article-probe-" + jobID.uuidString
        let folder = try root.createChildExclusive(temporary)
        var committed = false
        do {
            try Task.checkCancellation()
            let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
            try checkpoint(.beforeReceipt)
            try folder.writeNew("verification.json", data: encoder.encode(receipt))
            try folder.synchronize()
            try checkpoint(.beforeImage)
            try folder.writeNew("01.jpg", data: image.bytes)
            try folder.synchronize()
            try Task.checkCancellation()
            try checkpoint(.beforeCommit)
            guard ContinuousClock().now < deadline else { throw ArticleFailure.timedOut }
            let checkpoint=checkpoint
            try root.moveExclusive(temporary, to: name,afterRename:{try checkpoint(.renamedBeforeSync)})
            committed = true
            try checkpoint(.afterCommit)
            return result
        } catch {
            if error as? ArticleFailure == .uncertainResult {throw error}
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

public struct ArticleProbeRecoveryRecord: Codable, Equatable, Sendable {
    public let schemaVersion:Int
    public let jobID:UUID
    public let projectID:UUID
    public let fingerprint:String
    public let destinationPath:String
}
/// 永続的アクセス権を保存せず、再選択時の照合に必要な最小情報だけ持つ。
public actor ArticleProbeJournal {
    private let directory:URL
    public init(directory:URL) {self.directory=directory}
    public func pending() throws ->ArticleProbeRecoveryRecord? {
        do {
            let root=try ArticleDirectory.open(directory,create:false)
            return try Self.readPending(root)
        } catch ArticleFailure.missing {return nil}
        catch let error as ArticleFailure {throw error}
        catch {throw ArticleFailure.corruptData}
    }
    public func begin(jobID:UUID,article:SavedArticle,destination:URL) throws {
        try article.validate()
        let root=try ArticleDirectory.open(directory,create:true)
        try root.withLock {
            guard try Self.readPending(root) == nil else {throw ArticleFailure.busy}
            let record=ArticleProbeRecoveryRecord(schemaVersion:1,jobID:jobID,projectID:article.projectID,fingerprint:article.fingerprint,destinationPath:destination.path)
            try root.replace("pending",data:JSONEncoder().encode(record),expected:nil)
        }
    }
    public func finish(jobID:UUID) throws {
        let root=try ArticleDirectory.open(directory,create:false)
        try root.withLock {
            guard let record=try Self.readPending(root), record.jobID == jobID else {throw ArticleFailure.conflict}
            try root.remove("pending"); try root.synchronize()
        }
    }
    private static func readPending(_ root:ArticleDirectory) throws ->ArticleProbeRecoveryRecord? {
        let bytes:Data
        do {bytes=try root.read("pending")} catch ArticleFailure.missing {return nil}
        let record=try JSONDecoder().decode(ArticleProbeRecoveryRecord.self,from:bytes)
        guard record.schemaVersion == 1 else {throw ArticleFailure.unsupportedVersion}
        guard !record.fingerprint.isEmpty, record.destinationPath.hasPrefix("/") else {throw ArticleFailure.corruptData}
        return record
    }
}
