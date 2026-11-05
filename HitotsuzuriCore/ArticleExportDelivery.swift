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

/// UIから独立した出力制御。同期I/OはWriter/Journalの直列actorへ渡す。
public actor ArticleExportDelivery {
    private let images: any ArticleExportImageProviding
    private let journal: ArticleExportJournal
    private let now: @Sendable () -> ContinuousClock.Instant
    private let writerFactory: ArticleExportWriterFactory
    public private(set) var failureDetail: ArticleExportFailureDetail?
    private var activeJobID: UUID?
    private var activeRequestID: UUID?
    private var cancelRequested = false
    private var committing = false
    private var photoIndex: Int?
    public init(images: any ArticleExportImageProviding, journal: ArticleExportJournal,
                now: @escaping @Sendable () -> ContinuousClock.Instant = { ContinuousClock().now },
                writerFactory: @escaping ArticleExportWriterFactory = { ArticleExportWriter(destination: $0, record: $1) }) {
        self.images = images; self.journal = journal; self.now = now; self.writerFactory = writerFactory
    }
    public func run(jobID: UUID, prepared: PreparedArticleExport, destination: URL, progress: @escaping ArticleExportProgressSink = { _ in }) async throws -> ExportResult {
        guard activeJobID == nil else { throw ArticleFailure.busy }
        guard prepared.savedInput.settings == ArticleImageSettings() else { throw ArticleFailure.invalidInput }
        activeJobID = jobID; cancelRequested = false; failureDetail = nil
        defer { activeJobID = nil; activeRequestID = nil; committing = false; photoIndex = nil }
        let deadline = now() + .seconds(180)
        let parentIdentity = try await Task.detached { try ArticleExportFileSystem.identity(of: destination) }.value
        var record = ArticleExportRecoveryRecord(jobID: jobID, prepared: prepared, parentIdentity: parentIdentity)
        if let existing = try await journal.lookup(jobID) {
            guard existing.article == record.article, existing.parentIdentity == record.parentIdentity,
                  existing.markdown.utf8.elementsEqual(record.markdown.utf8), existing.fixedPlainText.utf8.elementsEqual(record.fixedPlainText.utf8) else { throw ArticleFailure.conflict }
            guard existing.phase == .succeeded else { throw existing.originalFailure ?? ArticleFailure.uncertainResult }
            let writer = writerFactory(destination, existing)
            guard let directory = try await writer.reconcile() else { throw ArticleFailure.uncertainResult }
            return result(existing, directory: directory)
        }
        try await journal.begin(record)
        let writer = writerFactory(destination, record)
        do {
            try check(deadline)
            let started = try await writer.prepare()
            try await journal.update(started, expected: record); record = started
            for (offset, assetID) in prepared.savedInput.article.source.orderedAssetIDs.enumerated() {
                photoIndex = offset + 1
                try check(deadline)
                await progress(ExportProgress(jobID: jobID, stage: "acquiring", completedImages: offset))
                let next = try await processImage(assetID, index: offset + 1, writer: writer, deadline: deadline)
                try await journal.update(next, expected: record); record = next
                await progress(ExportProgress(jobID: jobID, stage: "writing", completedImages: offset + 1))
            }
            photoIndex = nil; try check(deadline)
            await progress(ExportProgress(jobID: jobID, stage: "validating", completedImages: 4))
            let sealed = try await writer.seal()
            try await journal.update(sealed, expected: record); record = sealed
            await progress(ExportProgress(jobID: jobID, stage: "committing", completedImages: 4))
            try check(deadline); committing = true
            let directory = try await writer.publish()
            let completed = await writer.snapshot()
            // 公開の成立は記録更新失敗で取り消さない。未完activeを残して次回照合する。
            do { try await journal.finish(completed, expected: record) }
            catch { failureDetail = ArticleExportFailureDetail(failure: .uncertainResult, photoIndex: nil, residualDirectory: directory) }
            return result(completed, directory: directory)
        } catch {
            let failure = error as? ArticleFailure ?? (error is CancellationError ? .cancelled : .ioFailure)
            await settleImages()
            var interrupted = await writer.snapshot(); interrupted.originalFailure = failure
            if committing || failure == .uncertainResult {
                interrupted.phase = .needsReconciliation
                try await journal.update(interrupted, expected: record)
                failureDetail = ArticleExportFailureDetail(failure: .uncertainResult, photoIndex: photoIndex, residualDirectory: destination.appendingPathComponent(interrupted.finalName))
                throw ArticleFailure.uncertainResult
            }
            do {
                if interrupted.stagingIdentity != nil { try await writer.cleanup() }
                interrupted.phase = failure == .cancelled ? .cancelled : .failed
                try await journal.finish(interrupted, expected: record)
                failureDetail = ArticleExportFailureDetail(failure: failure, photoIndex: photoIndex, residualDirectory: nil)
            } catch {
                interrupted.phase = .cleanupFailed
                try await journal.update(interrupted, expected: record)
                failureDetail = ArticleExportFailureDetail(failure: .cleanupFailure, photoIndex: photoIndex, residualDirectory: destination.appendingPathComponent(interrupted.stagingName))
                throw ArticleFailure.cleanupFailure
            }
            throw failure
        }
    }
    public func cancel(_ jobID: UUID) async {
        guard activeJobID == jobID else { return }
        cancelRequested = true
        if !committing, let request = activeRequestID { await images.cancel(request) }
    }
    public func pending() async throws -> ArticleExportRecoveryRecord? { try await journal.pending() }
    public func recover(destination: URL, cleanupConfirmed: Bool) async throws -> ExportResult? {
        guard activeJobID == nil else { throw ArticleFailure.busy }
        guard let record = try await journal.pending() else { return nil }
        activeJobID = record.jobID
        defer { activeJobID = nil }
        let writer = writerFactory(destination, record)
        if let directory = try await writer.reconcile() {
            var completed = record; completed.phase = .succeeded
            try await journal.finish(completed, expected: record)
            return result(completed, directory: directory)
        }
        guard cleanupConfirmed else { return nil }
        try await writer.cleanup()
        var cancelled = record; cancelled.phase = .cancelled
        try await journal.finish(cancelled, expected: record)
        return nil
    }
    private func check(_ deadline: ContinuousClock.Instant) throws {
        guard !cancelRequested, !Task.isCancelled else { throw ArticleFailure.cancelled }
        guard now() < deadline else { throw ArticleFailure.timedOut }
    }
    private func processImage(_ assetID: String, index: Int, writer: ArticleExportWriter, deadline: ContinuousClock.Instant) async throws -> ArticleExportRecoveryRecord {
        let started = now(), request = UUID()
        activeRequestID = request
        defer { activeRequestID = nil }
        guard await images.reservedImageBytes <= 256 * 1024 * 1024 else { throw ArticleFailure.capacity }
        let image = try await images.image(assetID, requestID: request)
        try check(min(deadline, started + .seconds(30)))
        guard await images.reservedImageBytes <= 256 * 1024 * 1024, image.bytes.count <= 32 * 1024 * 1024 else { throw ArticleFailure.capacity }
        let record = try await writer.writeImage(image, index: index)
        try check(min(deadline, started + .seconds(40)))
        return record
    }
    private func settleImages() async {
        if let request = activeRequestID { await images.cancel(request) }
        // 論理取消と同期変換の終了は別。実処理終了までgrantの呼出元へ戻らない。
        while await images.isBusy { try? await Task.sleep(for: .milliseconds(10)) }
    }
    private func result(_ record: ArticleExportRecoveryRecord, directory: URL) -> ExportResult {
        ExportResult(jobID: record.jobID, projectID: record.article.projectID, savedRevision: record.article.savedRevision, selectionRevision: record.article.source.selectionRevision, fingerprint: record.article.fingerprint, directory: directory, fixedPlainText: record.fixedPlainText)
    }
}
