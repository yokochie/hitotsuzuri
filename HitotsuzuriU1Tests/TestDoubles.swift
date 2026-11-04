import Foundation
@testable import HitotsuzuriCore

@MainActor final class FakeLibrarySource: LibrarySource {
    var access: AccessStatus = .authorized
    var fetchCount = 0
    var value = LibraryHierarchy(folders: [
        .init(id: "parent", title: "同名", children: ["child"], albums: ["a"]),
        .init(id: "child", title: "子", children: ["deep"], albums: ["b"]),
        .init(id: "deep", title: "深", children: ["parent"], albums: ["a","c"])
    ], albums: [.init(id: "a", title: "同名"), .init(id: "b", title: "同名"), .init(id: "c", title: "三")])
    var photos = ["a": ["1","2","3","4","5"], "b": ["6"], "c": []]
    func status() -> AccessStatus { access }
    func requestAccess() async -> AccessStatus { access = .authorized; return access }
    func hierarchy() async throws -> LibraryHierarchy { fetchCount += 1; return value }
    func assets(in albumID: String) async throws -> [LibraryAsset] {
        guard let ids=photos[albumID] else { throw PickerFailure.invalidReference }
        return ids.map { LibraryAsset(id: $0) }
    }
}
@MainActor final class FakeImageDriver: ImageDriving {
    var outcome: ImageOutcome = .image(.init(pixels: Data(repeating: 1, count: 16), width: 2, height: 2, bytesPerRow: 8), final: true)
    var callbacks: [Int: @MainActor (ImageOutcome)->Void] = [:]
    var cancelled: [Int] = []
    var requestCount=0
    var automatic=true
    var onRequest: ((Int)->Void)?
    func request(_ assetID: String, completion: @escaping @MainActor (ImageOutcome)->Void) -> Int {
        requestCount += 1; let id=requestCount; callbacks[id]=completion
        onRequest?(id)
        if automatic { Task { completion(outcome) } }
        return id
    }
    func cancel(_ requestID: Int) { cancelled.append(requestID) }
}
func testSelection() -> CommittedSelection { .init(albumID: "a", albumTitle: "テスト", orderedAssetIDs: ["1","2","3","4"]) }

@MainActor final class ManualImageClock: ImageClock {
    private let base=ContinuousClock().now
    var offset: Duration = .zero
    func now() -> ContinuousClock.Instant { base.advanced(by:offset) }
    func sleep(until deadline: ContinuousClock.Instant) async throws { try await Task.sleep(for:.seconds(60)) }
}

