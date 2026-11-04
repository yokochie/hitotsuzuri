import Foundation
import Photos

@MainActor public final class PhotoLibraryAccess: LibraryAccessing {
    private let source: any LibrarySource
    public init(source: any LibrarySource) { self.source=source }
    public convenience init() { self.init(source: SystemLibrarySource()) }
    public var authorization: AccessStatus { source.status() }
    public func requestAuthorization() async -> AccessStatus { await source.requestAccess() }
    public func hierarchy() async throws -> LibraryHierarchy {
        guard authorization == .authorized else { throw PickerFailure.authorization }
        return try await source.hierarchy()
    }
    public func albums(in folders: Set<String>, hierarchy: LibraryHierarchy) -> [LibraryAlbum] {
        let index=Dictionary(hierarchy.folders.map { ($0.id,$0) }, uniquingKeysWith: { first,_ in first })
        var stack=hierarchy.folders.filter { folders.contains($0.id) }.map(\.id).reversed().map { $0 }
        var visited=Set<String>(), albumIDs=Set<String>(), ordered=[String]()
        while let id=stack.popLast() {
            guard visited.insert(id).inserted, let folder=index[id] else { continue }
            for album in folder.albums where albumIDs.insert(album).inserted { ordered.append(album) }
            stack.append(contentsOf: folder.children.reversed())
        }
        let albums=Dictionary(hierarchy.albums.map { ($0.id,$0) }, uniquingKeysWith: { first,_ in first })
        return ordered.compactMap { albums[$0] }
    }
    public func assets(in albumID: String) async throws -> [LibraryAsset] {
        guard authorization == .authorized else { throw PickerFailure.authorization }
        return try await source.assets(in:albumID)
    }
    public func validate(folders: Set<String>, albumID: String, assets: [String]) async throws {
        let h=try await hierarchy()
        guard assets.count==4, Set(assets).count==4, albums(in:folders,hierarchy:h).contains(where:{$0.id==albumID}) else { throw PickerFailure.invalidReference }
        let members=Set(try await self.assets(in:albumID).map(\.id))
        guard assets.allSatisfy(members.contains) else { throw PickerFailure.invalidReference }
    }
}

@MainActor private final class SystemLibrarySource: LibrarySource {
    func status() -> AccessStatus { Self.map(PHPhotoLibrary.authorizationStatus(for:.readWrite)) }
    func requestAccess() async -> AccessStatus {
        let result=await PHPhotoLibrary.requestAuthorization(for:.readWrite)
        return Self.map(result)
    }
    private static func map(_ status: PHAuthorizationStatus) -> AccessStatus {
        switch status { case .authorized: return .authorized; case .notDetermined: return .notDetermined
        case .denied: return .denied; case .restricted: return .restricted; default: return .unsupported }
    }
    func hierarchy() async throws -> LibraryHierarchy {
        try await Task.detached(priority:.userInitiated) {
            guard PHPhotoLibrary.authorizationStatus(for:.readWrite) == .authorized else { throw PickerFailure.authorization }
            var folders=[LibraryFolder](), albums=[LibraryAlbum](), stack=[PHCollectionList]()
            PHCollectionList.fetchTopLevelUserCollections(with:nil).enumerateObjects { collection,_,_ in
                if let folder=collection as? PHCollectionList { stack.append(folder) }
            }
            var visited=Set<String>(), seenAlbums=Set<String>()
            while let folder=stack.popLast() {
                guard visited.insert(folder.localIdentifier).inserted else { continue }
                var children=[String](), contained=[String]()
                PHCollection.fetchCollections(in:folder,options:nil).enumerateObjects { child,_,_ in
                    if let nested=child as? PHCollectionList { children.append(nested.localIdentifier); stack.append(nested) }
                    else if let album=child as? PHAssetCollection, album.assetCollectionType == .album {
                        contained.append(album.localIdentifier)
                        if seenAlbums.insert(album.localIdentifier).inserted { albums.append(.init(id:album.localIdentifier,title:album.localizedTitle ?? "名称なし")) }
                    }
                }
                folders.append(.init(id:folder.localIdentifier,title:folder.localizedTitle ?? "名称なし",children:children,albums:contained))
            }
            return LibraryHierarchy(folders:folders,albums:albums)
        }.value
    }
    func assets(in albumID: String) async throws -> [LibraryAsset] {
        try await Task.detached(priority:.userInitiated) {
            guard PHPhotoLibrary.authorizationStatus(for:.readWrite) == .authorized else { throw PickerFailure.authorization }
            guard let album=PHAssetCollection.fetchAssetCollections(withLocalIdentifiers:[albumID],options:nil).firstObject else { throw PickerFailure.invalidReference }
            var result=[LibraryAsset]()
            // sortDescriptorsを設定せず、取得順を保ったまま動画のみ除外する。
            PHAsset.fetchAssets(in:album,options:nil).enumerateObjects { asset,_,_ in
                if asset.mediaType == .image { result.append(.init(id:asset.localIdentifier)) }
            }
            return result
        }.value
    }
}


