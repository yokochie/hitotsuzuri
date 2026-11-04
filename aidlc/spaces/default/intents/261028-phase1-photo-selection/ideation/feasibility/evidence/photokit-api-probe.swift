// 型・API利用可否のみを確認する検証コード。実行しない。
import AppKit
import Observation
import Photos
import SwiftUI

func collectAlbums(under folder: PHCollectionList, visited: inout Set<String>) -> [String] {
    guard visited.insert(folder.localIdentifier).inserted else { return [] }
    let children = PHCollection.fetchCollections(in: folder, options: nil)
    var result: [String] = []
    for index in 0..<children.count {
        let collection = children.object(at: index)
        if let album = collection as? PHAssetCollection {
            result.append(album.localIdentifier)
        } else if let child = collection as? PHCollectionList {
            result.append(contentsOf: collectAlbums(under: child, visited: &visited))
        }
    }
    return result
}

func apiSurface(album: PHAssetCollection, asset: PHAsset, manager: PHCachingImageManager) {
    _ = PHCollection.fetchTopLevelUserCollections(with: nil)
    _ = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in }
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
    fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
    _ = PHAsset.fetchAssets(in: album, options: fetchOptions)
    let imageOptions = PHImageRequestOptions()
    imageOptions.isNetworkAccessAllowed = false
    let requestID = manager.requestImage(for: asset, targetSize: CGSize(width: 160, height: 160), contentMode: .aspectFill, options: imageOptions) { _, _ in }
    manager.cancelImageRequest(requestID)
}

@MainActor @Observable final class ProbeState { var count = 0 }

struct ProbeView: View {
    var body: some View {
        NavigationSplitView { Text("フォルダ") } content: { Text("アルバム") } detail: { Text("写真") }
    }
}
