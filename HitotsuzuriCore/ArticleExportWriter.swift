import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum ArticleExportCheckpoint: Equatable, Sendable {
    case afterCreate, beforeImage(Int), beforeSeal, afterValidation, beforeRename, afterRename, beforeCleanup
}
public actor ArticleExportWriter {
    private let destination: URL
    private var record: ArticleExportRecoveryRecord
    private let checkpoint: @Sendable (ArticleExportCheckpoint) throws -> Void
    private var root: ArticleDirectory?
    private var folder: ArticleDirectory?
    private var images: ArticleDirectory?
    private var published = false
    public init(destination: URL, record: ArticleExportRecoveryRecord, checkpoint: @escaping @Sendable (ArticleExportCheckpoint) throws -> Void = { _ in }) {
        self.destination = destination; self.record = record; self.checkpoint = checkpoint
    }
    public func snapshot() -> ArticleExportRecoveryRecord { record }
    public func prepare() throws -> ArticleExportRecoveryRecord {
        guard folder == nil else { throw ArticleFailure.busy }
        try record.validate()
        let root = try checkedRoot()
        let folder = try root.createChildExclusive(record.stagingName)
        self.root = root; self.folder = folder
        record.stagingIdentity = try ArticleExportFileSystem.identity(folder)
        try folder.writeNew("owner.json", data: Data(record.ownershipToken.uuidString.utf8))
        images = try folder.createChildExclusive("images")
        record.imagesIdentity = try ArticleExportFileSystem.identity(images!)
        try folder.synchronize(); try root.synchronize()
        record.phase = .generating
        try checkpoint(.afterCreate)
        return record
    }
    public func writeImage(_ image: ArticleJPEG, index: Int) throws -> ArticleExportRecoveryRecord {
        guard record.phase == .generating, let images, (1...4).contains(index),
              record.expectedDigests.count == index - 1 else { throw ArticleFailure.invalidInput }
        try checkpoint(.beforeImage(index))
        try validateJPEG(image)
        let name = String(format: "%02d.jpg", index)
        try images.writeNew(name, data: image.bytes)
        record.expectedDigests["images/" + name] = ArticleFingerprint.digest(image.bytes)
        return record
    }
    public func seal() throws -> ArticleExportRecoveryRecord {
        guard record.phase == .generating, let folder, let images,
              record.expectedDigests.count == 4 else { throw ArticleFailure.invalidInput }
        try checkpoint(.beforeSeal)
        let prepared = try preparation()
        let manifest = ArticleExportManifest(jobID: record.jobID, prepared: prepared)
        try manifest.validate(prepared: prepared)
        for (name, bytes) in [("article.md", Data(record.markdown.utf8)), ("manifest.json", try manifest.encoded())] {
            try folder.writeNew(name, data: bytes); record.expectedDigests[name] = ArticleFingerprint.digest(bytes)
        }
        try images.synchronize(); try folder.synchronize()
        try verify(folder, includeReceipt: true)
        record.phase = .publishing
        try record.validate(); try checkpoint(.afterValidation)
        return record
    }
    public func publish() throws -> URL {
        guard record.phase == .publishing, let root, let folder else { throw ArticleFailure.invalidInput }
        try checkIdentity(root.child(record.stagingName, create: false))
        // sealの記録を保存してから内部receiptを除く。除去直後の中断でも全digestが記録に残る。
        try verify(folder, includeReceipt: true)
        try folder.remove("owner.json"); try folder.synchronize()
        try verify(folder, includeReceipt: false)
        try checkpoint(.beforeRename)
        // rename前の検査とrenameの間に差し替わっても、公開後の同一実体・全bytes照合で成功を拒否する。
        do {
            try root.moveExclusive(record.stagingName, to: record.finalName, afterRename: { try checkpoint(.afterRename) })
            published = true
            let final = try root.child(record.finalName, create: false)
            try checkIdentity(final); try verify(final, includeReceipt: false)
            try root.synchronize(); _ = try checkedRoot(); record.phase = .succeeded
            return destination.appendingPathComponent(record.finalName, isDirectory: true)
        } catch ArticleFailure.conflict { throw ArticleFailure.conflict }
        catch { record.phase = .needsReconciliation; throw ArticleFailure.uncertainResult }
    }
    public func cleanup() throws {
        try checkpoint(.beforeCleanup)
        guard !published, record.phase != .succeeded, let identity = record.stagingIdentity else { throw ArticleFailure.invalidReference }
        let root = try checkedRoot()
        // 完成名があれば、公開成否の照合を先に行う。完成物は自動削除しない。
        do { _ = try root.child(record.finalName, create: false); throw ArticleFailure.uncertainResult }
        catch ArticleFailure.missing { }
        let folder = try root.child(record.stagingName, create: false)
        guard try ArticleExportFileSystem.identity(folder) == identity else { throw ArticleFailure.invalidReference }
        let receipt: Data?
        do { receipt = try folder.read("owner.json") } catch ArticleFailure.missing { receipt = nil }
        let hasReceipt = receipt == Data(record.ownershipToken.uuidString.utf8)
        if !hasReceipt { try verify(folder, includeReceipt: false) }
        let names = try ArticleExportFileSystem.entries(folder)
        guard names.isSubset(of: ["owner.json", "images", "article.md", "manifest.json"]) else { throw ArticleFailure.cleanupFailure }
        let images = try folder.child("images", create: false)
        guard try ArticleExportFileSystem.identity(images) == record.imagesIdentity else { throw ArticleFailure.invalidReference }
        let imageNames = try ArticleExportFileSystem.entries(images)
        guard imageNames.isSubset(of: Set((1...4).map { String(format: "%02d.jpg", $0) })) else { throw ArticleFailure.cleanupFailure }
        // 既知の生成済みbytesが外部変更されていれば、そのファイルは片付けない。
        for (path, digest) in record.expectedDigests {
            let bytes = try artifactBytes(path, folder: folder, images: images)
            guard ArticleFingerprint.digest(bytes) == digest else { throw ArticleFailure.cleanupFailure }
        }
        for name in imageNames { try images.remove(name) }
        try folder.remove("images", directory: true)
        for name in names.subtracting(["images"]) { try folder.remove(name) }
        try root.remove(record.stagingName, directory: true); try root.synchronize()
    }
    public func reconcile() throws -> URL? {
        let root = try checkedRoot()
        let final: ArticleDirectory
        do { final = try root.child(record.finalName, create: false) } catch ArticleFailure.missing { return nil }
        try checkIdentity(final); try verify(final, includeReceipt: false); try root.synchronize()
        published = true; record.phase = .succeeded
        return destination.appendingPathComponent(record.finalName, isDirectory: true)
    }
    private func checkedRoot() throws -> ArticleDirectory {
        let root = try ArticleDirectory.open(destination, create: false)
        guard try ArticleExportFileSystem.identity(root) == record.parentIdentity else { throw ArticleFailure.invalidReference }
        return root
    }
    private func checkIdentity(_ folder: ArticleDirectory) throws {
        guard let identity = record.stagingIdentity, try ArticleExportFileSystem.identity(folder) == identity else { throw ArticleFailure.invalidReference }
    }
    private func preparation() throws -> PreparedArticleExport {
        let rendered = try ArticleProjectionContext(projectID: record.article.projectID).renderArticle(source: record.article.source, content: record.article.content)
        return try PreparedArticleExport(savedInput: SavedExportInput(article: record.article), rendered: rendered)
    }
    private func verify(_ folder: ArticleDirectory, includeReceipt: Bool) throws {
        try checkIdentity(folder)
        let names = Set(["images", "article.md", "manifest.json"] + (includeReceipt ? ["owner.json"] : []))
        guard try ArticleExportFileSystem.entries(folder) == names,
              Set(record.expectedDigests.keys) == ArticleExportLayout.artifactPaths else { throw ArticleFailure.corruptData }
        let images = try folder.child("images", create: false)
        guard try ArticleExportFileSystem.identity(images) == record.imagesIdentity else { throw ArticleFailure.invalidReference }
        guard try ArticleExportFileSystem.entries(images) == Set((1...4).map { String(format: "%02d.jpg", $0) }) else { throw ArticleFailure.corruptData }
        for (path, digest) in record.expectedDigests {
            let bytes = try artifactBytes(path, folder: folder, images: images)
            guard ArticleFingerprint.digest(bytes) == digest else { throw ArticleFailure.corruptData }
        }
        let manifest = try ArticleExportManifest.decode(folder.read("manifest.json"))
        guard manifest.jobID == record.jobID else { throw ArticleFailure.corruptData }
        try manifest.validate(prepared: preparation())
        guard try folder.read("article.md") == Data(record.markdown.utf8) else { throw ArticleFailure.corruptData }
    }
    private func validateJPEG(_ image: ArticleJPEG) throws {
        guard image.width > 0, image.height > 0, max(image.width, image.height) <= 2560,
              let source = CGImageSourceCreateWithData(image.bytes as CFData, nil),
              CGImageSourceGetType(source) == UTType.jpeg.identifier as CFString,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              properties[kCGImagePropertyPixelWidth] as? Int == image.width,
              properties[kCGImagePropertyPixelHeight] as? Int == image.height,
              properties[kCGImagePropertyGPSDictionary] == nil else { throw ArticleFailure.invalidInput }
    }
    private func artifactBytes(_ path: String, folder: ArticleDirectory, images: ArticleDirectory) throws -> Data {
        path.hasPrefix("images/") ? try images.read(String(path.dropFirst(7))) : try folder.read(path)
    }
}
