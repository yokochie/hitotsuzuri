import Foundation
import AppKit

public struct ArticleExportFailureDetail: Equatable, Sendable {
    public let failure: ArticleFailure
    public let photoIndex: Int?
    public let residualDirectory: URL?
}

@MainActor public protocol ArticleExportFailureDescribing {
    var lastFailureDetail: ArticleExportFailureDetail? { get }
}

public enum ArticleExportOSFailure: String, Error, LocalizedError {
    case clipboardFailure, finderFailure
    public var errorDescription: String? {
        switch self {
        case .clipboardFailure: "本文をコピーできませんでした。文章は保持しています。"
        case .finderFailure: "出力先をFinderで開けませんでした。移動・削除やアクセスを確認してください。"
        }
    }
}

@MainActor public protocol ArticleExportDestinationReleasing {
    func releaseDestination(_ destination: ArticleExportDestination)
}

/// 選択による一時アクセスを一回だけ解放する。再起動の権限は保存しない。
@MainActor public final class ArticleExportDestinationAccess {
    public let reference: ArticleExportDestination
    private var scoped: Bool
    private var released = false
    private let stop: @MainActor () -> Void
    public init(url: URL, start: (@MainActor () -> Bool)? = nil, stop: (@MainActor () -> Void)? = nil) {
        reference = ArticleExportDestination(grantID: UUID(), selectedDirectory: url)
        scoped = start?() ?? url.startAccessingSecurityScopedResource()
        self.stop = stop ?? { url.stopAccessingSecurityScopedResource() }
    }
    public func release() { guard !released else { return }; released = true; if scoped { stop(); scoped = false } }
}

@MainActor public final class ArticleExportOSActions: ArticleOutputActions, ArticleExportDestinationReleasing, ArticleExportFailureDescribing {
    public let capabilities = ArticleOutputCapabilities(copy: true, export: true, reveal: true)
    private let delivery: ArticleExportDelivery
    private let pasteboard: NSPasteboard
    private let write: (@MainActor (String) -> Bool)?
    private let open: @MainActor (URL) -> Bool
    private var grants: [UUID: ArticleExportDestinationAccess] = [:]
    private var completed: [UUID: ExportResult] = [:]
    public private(set) var lastFailureDetail: ArticleExportFailureDetail?
    public init(delivery: ArticleExportDelivery, pasteboard: NSPasteboard = .general,
                write: (@MainActor (String) -> Bool)? = nil,
                open: @escaping @MainActor (URL) -> Bool = { NSWorkspace.shared.open($0) }) {
        self.delivery = delivery; self.pasteboard = pasteboard; self.write = write; self.open = open
    }
    public func register(_ access: ArticleExportDestinationAccess) -> ArticleExportDestination {
        grants[access.reference.grantID] = access; return access.reference
    }
    public func releaseDestination(_ destination: ArticleExportDestination) {
        grants.removeValue(forKey: destination.grantID)?.release()
    }
    public func copyPlainText(_ text: String, context: ArticleCopyContext) async throws {
        switch context {
        case .editor(_, let fingerprint): guard !fingerprint.isEmpty else { throw ArticleFailure.invalidInput }
        case .exported(let jobID, let projectID):
            guard let result = completed[jobID], result.projectID == projectID,
                  text.utf8.elementsEqual(result.fixedPlainText.utf8) else { throw ArticleFailure.invalidInput }
        }
        let succeeded: Bool
        if let write { succeeded = write(text) }
        else { pasteboard.clearContents(); succeeded = pasteboard.setString(text, forType: .string) }
        guard succeeded else { throw ArticleExportOSFailure.clipboardFailure }
    }
    public func runExport(jobID: UUID, savedInput: SavedExportInput, rendered: RenderedArticle, destination: ArticleExportDestination, progress: @escaping @MainActor (ExportProgress) -> Void) async throws -> ExportResult {
        guard let access = grants[destination.grantID] else { throw ArticleFailure.permissionDenied }
        defer { releaseDestination(destination) }
        guard access.reference.selectedDirectory == destination.selectedDirectory else { throw ArticleFailure.invalidReference }
        let prepared = try PreparedArticleExport(savedInput: savedInput, rendered: rendered)
        let sink = ArticleExportProgressBridge(progress)
        lastFailureDetail = nil
        do {
            let result = try await delivery.run(jobID: jobID, prepared: prepared, destination: destination.selectedDirectory) { value in await sink.send(value) }
            // 完了画面の一件だけを保持し、過去ジョブの全本文を常駐させない。
            completed = [jobID: result]
            return result
        } catch { lastFailureDetail = await delivery.failureDetail; throw error }
    }
    public func cancelExport(_ jobID: UUID) { Task { await delivery.cancel(jobID) } }
    public func revealExport(_ result: ExportResult) async throws {
        guard completed[result.jobID] == result else { throw ArticleExportOSFailure.finderFailure }
        let url = result.directory, scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            try await Task.detached {
                _ = try ArticleExportFileSystem.identity(of: url)
                guard FileManager.default.isReadableFile(atPath: url.path) else { throw ArticleFailure.permissionDenied }
            }.value
        }
        catch { throw ArticleExportOSFailure.finderFailure }
        guard open(url) else { throw ArticleExportOSFailure.finderFailure }
    }
    public func recover(destination: ArticleExportDestination, cleanupConfirmed: Bool) async throws -> ExportResult? {
        guard let access = grants[destination.grantID] else { throw ArticleFailure.permissionDenied }
        defer { releaseDestination(destination) }
        guard access.reference.selectedDirectory == destination.selectedDirectory else { throw ArticleFailure.invalidReference }
        if let result = try await delivery.recover(destination: destination.selectedDirectory, cleanupConfirmed: cleanupConfirmed) {
            completed = [result.jobID: result]; return result
        }
        return nil
    }
}

/// MainActorの画面通知をSendableな参照へ限定する。
@MainActor private final class ArticleExportProgressBridge {
    private let sink: @MainActor (ExportProgress) -> Void
    init(_ sink: @escaping @MainActor (ExportProgress) -> Void) { self.sink = sink }
    func send(_ value: ExportProgress) { sink(value) }
}
