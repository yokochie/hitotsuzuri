import Foundation

/// 記事・一枚検証から独立した出力専用の記録。
public actor ArticleExportJournal {
    private let directory: URL
    public init(directory: URL) { self.directory = directory }
    public func pending() throws -> ArticleExportRecoveryRecord? { try pendingRecord() }
    public func lookup(_ jobID: UUID) throws -> ArticleExportRecoveryRecord? { try lookupRecord(jobID) }
    public func begin(_ record: ArticleExportRecoveryRecord) throws { try beginRecord(record) }
    public func update(_ record: ArticleExportRecoveryRecord, expected: ArticleExportRecoveryRecord) throws { try updateRecord(record, expected: expected) }
    public func finish(_ record: ArticleExportRecoveryRecord, expected: ArticleExportRecoveryRecord) throws { try finishRecord(record, expected: expected) }
    private nonisolated func pendingRecord() throws -> ArticleExportRecoveryRecord? {
        do { return try read(ArticleDirectory.open(directory, create: false), name: "active") }
        catch ArticleFailure.missing { return nil }
    }
    private nonisolated func lookupRecord(_ jobID: UUID) throws -> ArticleExportRecoveryRecord? {
        do {
            let root = try ArticleDirectory.open(directory, create: false)
            let active = try read(root, name: "active"), stored = try read(root, name: archive(jobID))
            if let active, active.jobID == jobID {
                if let stored { guard sameInput(active, stored) else { throw ArticleFailure.conflict }; return stored }
                return active
            }
            return stored
        } catch ArticleFailure.missing { return nil }
    }
    private nonisolated func beginRecord(_ record: ArticleExportRecoveryRecord) throws {
        try record.validate()
        let root = try ArticleDirectory.open(directory, create: true)
        try root.withLock(isolation: nil) {
            if let active = try read(root, name: "active") {
                guard active.jobID == record.jobID else { throw ArticleFailure.busy }
                guard sameInput(active, record) else { throw ArticleFailure.conflict }
                return
            }
            if let stored = try read(root, name: archive(record.jobID)) {
                guard sameInput(stored, record) else { throw ArticleFailure.conflict }
                return
            }
            try root.replace("active", data: encode(record), expected: nil)
        }
    }
    private nonisolated func updateRecord(_ record: ArticleExportRecoveryRecord, expected: ArticleExportRecoveryRecord) throws {
        try record.validate()
        guard sameInput(record, expected) else { throw ArticleFailure.conflict }
        let root = try ArticleDirectory.open(directory, create: false)
        try root.withLock(isolation: nil) { try root.replace("active", data: encode(record), expected: encode(expected)) }
    }
    private nonisolated func finishRecord(_ record: ArticleExportRecoveryRecord, expected: ArticleExportRecoveryRecord) throws {
        try record.validate()
        guard sameInput(record, expected), [.succeeded, .cancelled, .failed].contains(record.phase) else { throw ArticleFailure.invalidInput }
        let root = try ArticleDirectory.open(directory, create: false)
        try root.withLock(isolation: nil) {
            guard try root.read("active") == encode(expected) else { throw ArticleFailure.conflict }
            let name = archive(record.jobID), bytes = try encode(record)
            if let stored = try read(root, name: name) { guard stored == record else { throw ArticleFailure.conflict } }
            else { try root.writeNew(name, data: bytes); try root.synchronize() }
            guard try root.read("active") == encode(expected) else { throw ArticleFailure.conflict }
            try root.remove("active"); try root.synchronize()
        }
    }
    private nonisolated func read(_ root: ArticleDirectory, name: String) throws -> ArticleExportRecoveryRecord? {
        let bytes: Data
        do { bytes = try root.read(name) } catch ArticleFailure.missing { return nil }
        do {
            let value = try JSONDecoder().decode(ArticleExportRecoveryRecord.self, from: bytes)
            try value.validate(); return value
        } catch let failure as ArticleFailure { throw failure }
        catch { throw ArticleFailure.corruptData }
    }
    private nonisolated func archive(_ jobID: UUID) -> String { "job-" + jobID.uuidString.lowercased() + ".json" }
    private nonisolated func encode(_ record: ArticleExportRecoveryRecord) throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(record)
    }
    private nonisolated func sameInput(_ lhs: ArticleExportRecoveryRecord, _ rhs: ArticleExportRecoveryRecord) -> Bool {
        lhs.jobID == rhs.jobID && lhs.article == rhs.article && lhs.markdown.utf8.elementsEqual(rhs.markdown.utf8)
            && lhs.fixedPlainText.utf8.elementsEqual(rhs.fixedPlainText.utf8) && lhs.parentIdentity == rhs.parentIdentity
    }
}
