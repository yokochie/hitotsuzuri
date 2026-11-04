import Foundation

public struct EditingSelection: Equatable, Sendable {
    public private(set) var orderedIDs: [String] = []
    public init() {}
    public mutating func toggle(_ id: String, available: Bool) {
        if let index = orderedIDs.firstIndex(of: id) { orderedIDs.remove(at: index) }
        else if available && !id.isEmpty && orderedIDs.count < 4 { orderedIDs.append(id) }
    }
    public mutating func clear() { orderedIDs = [] }
}

public struct CommittedSelection: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let selectionID: UUID
    public let albumID: String
    public let albumTitle: String
    public let orderedAssetIDs: [String]
    public let confirmedAt: Date
    public init(albumID: String, albumTitle: String, orderedAssetIDs: [String], confirmedAt: Date = Date()) {
        schemaVersion = 1; selectionID = UUID(); self.albumID = albumID
        self.albumTitle = albumTitle; self.orderedAssetIDs = orderedAssetIDs
        // 保存形式のISO8601秒精度とモデルの時点を一致させる。
        self.confirmedAt = Date(timeIntervalSince1970: confirmedAt.timeIntervalSince1970.rounded(.down))
    }
    public var isValid: Bool {
        schemaVersion == 1 && confirmedAt.timeIntervalSince1970.isFinite && !albumID.isEmpty && orderedAssetIDs.count == 4
        && Set(orderedAssetIDs).count == 4 && orderedAssetIDs.allSatisfy { !$0.isEmpty }
    }
}

public enum RestoreState: Equatable, Sendable {
    case notStarted, loading, validating, restored, missing, failed(PickerFailure), blocked
    public var isBusy: Bool { self == .loading || self == .validating }
}
public enum SaveState: Equatable, Sendable {
    case idle, saving, saved, failed(PickerFailure)
}

