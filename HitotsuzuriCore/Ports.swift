import Foundation

public enum AccessStatus: String, Sendable { case notDetermined, authorized, denied, restricted, unsupported }
public enum PickerFailure: String, Error, Sendable {
    case authorization, invalidReference, unavailable, ioFailure, corruptData, unsupportedVersion, timedOut, cancelled, capacity, oversizedData
    public var message: String {
        switch self {
        case .authorization: return "写真へのアクセスが許可されていません。システム設定をご確認ください。"
        case .invalidReference: return "写真やアルバムが変更されました。アプリを再起動してください。"
        case .unavailable: return "画像を取得できません。写真アプリで準備してから再起動してください。"
        case .ioFailure: return "保存できませんでした。編集内容は保持されています。再試行できます。"
        case .corruptData: return "保存データを読み取れません。原本を保護するため上書きしません。"
        case .unsupportedVersion: return "未対応の保存形式です。対応するアプリをご確認ください。"
        case .timedOut: return "画像の取得が時間内に完了しませんでした。準備後に再起動してください。"
        case .cancelled: return "取得を取り消しました。"
        case .capacity: return "画像の保持上限に達しました。表示範囲を移動してください。"
        case .oversizedData: return "保存データが1 MiBの上限を超えています。原本を保護しています。手動復旧手順を確認してください。"
        }
    }
}
public struct LibraryFolder: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let children: [String]
    public let albums: [String]
    public init(id: String, title: String, children: [String] = [], albums: [String] = []) { self.id=id; self.title=title; self.children=children; self.albums=albums }
}
public struct LibraryAlbum: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public init(id: String, title: String) { self.id=id; self.title=title }
}
public struct LibraryAsset: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public init(id: String, title: String = "写真") { self.id=id; self.title=title }
}
public struct LibraryHierarchy: Sendable {
    public let folders: [LibraryFolder]
    public let albums: [LibraryAlbum]
    public init(folders: [LibraryFolder], albums: [LibraryAlbum]) { self.folders=folders; self.albums=albums }
}
@MainActor public protocol LibrarySource {
    func status() -> AccessStatus
    func requestAccess() async -> AccessStatus
    func hierarchy() async throws -> LibraryHierarchy
    func assets(in albumID: String) async throws -> [LibraryAsset]
}
@MainActor public protocol LibraryAccessing {
    var authorization: AccessStatus { get }
    func requestAuthorization() async -> AccessStatus
    func hierarchy() async throws -> LibraryHierarchy
    func albums(in folders: Set<String>, hierarchy: LibraryHierarchy) -> [LibraryAlbum]
    func assets(in albumID: String) async throws -> [LibraryAsset]
    func validate(folders: Set<String>, albumID: String, assets: [String]) async throws
}
public struct ImageBuffer: Equatable, Sendable {
    let storage: ImageStorage
    public var pixels: Data { storage.pixels }
    public let width: Int
    public let height: Int
    public let bytesPerRow: Int
    public var byteCount: Int { pixels.count }
    public init(pixels: Data, width: Int, height: Int, bytesPerRow: Int) { storage=ImageStorage(pixels:pixels); self.width=width; self.height=height; self.bytesPerRow=bytesPerRow }
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.pixels==rhs.pixels && lhs.width==rhs.width && lhs.height==rhs.height && lhs.bytesPerRow==rhs.bytesPerRow }
}
// 返却値と描画プロバイダが共有する不変ストレージ。コピーの数でなく生存バッファを数える。
final class ImageStorage: Sendable {
    let pixels: Data
    init(pixels: Data) { self.pixels=pixels }
}
@MainActor public protocol ImageClock: Sendable {
    func now() -> ContinuousClock.Instant
    func sleep(until deadline: ContinuousClock.Instant) async throws
}
@MainActor public final class ContinuousImageClock: ImageClock {
    public init() {}
    public func now() -> ContinuousClock.Instant { ContinuousClock().now }
    public func sleep(until deadline: ContinuousClock.Instant) async throws { try await ContinuousClock().sleep(until:deadline) }
}
public enum ImageOutcome: Sendable { case image(ImageBuffer, final: Bool), unavailable, cancelled, failure(PickerFailure) }
public struct ImageResourceSnapshot:Equatable,Sendable {
    public let active:Int
    public let queued:Int
    public let retainedBuffers:Int
    public let retainedBytes:Int
    public let reservedBytes:Int
    public let unnecessaryDisplay:Int
    public let necessaryCount:Int
}
@MainActor public protocol ImageDriving {
    func request(_ assetID: String, completion: @escaping @MainActor (ImageOutcome) -> Void) -> Int
    func cancel(_ requestID: Int)
}
@MainActor public protocol ImageAccessing: Sendable {
    var resources:ImageResourceSnapshot? {get}
    func image(_ assetID: String, validation: Bool, deadline: ContinuousClock.Instant?) async throws -> ImageBuffer
    func cancelDisplayRequests()
    func release(except ids: Set<String>)
}
extension ImageAccessing {
    public var resources:ImageResourceSnapshot? {nil}
    public func image(_ assetID: String, validation: Bool) async throws -> ImageBuffer { try await image(assetID,validation:validation,deadline:nil) }
}
public struct TargetFolderSettings: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let folderIDs: [String]
    public init(folderIDs: [String]) { schemaVersion=1; self.folderIDs=Array(Set(folderIDs)).sorted() }
    public var isValid: Bool { schemaVersion==1 && folderIDs.allSatisfy {!$0.isEmpty} && Set(folderIDs).count==folderIDs.count }
}
public enum StoredValue<Value: Sendable>: Sendable { case missing, valid(Value), failure(PickerFailure) }
public protocol SelectionStoring: Sendable {
    func loadSettings() async -> StoredValue<TargetFolderSettings>
    func saveSettings(_ settings: TargetFolderSettings) async throws
    func loadSelection() async -> StoredValue<CommittedSelection>
    func saveSelection(_ selection: CommittedSelection) async throws
    func confirmSelection(_ selection: CommittedSelection) async throws
}
extension SelectionStoring {
    public func confirmSelection(_ selection: CommittedSelection) async throws { try await saveSelection(selection) }
}

