// 設計案8.2のAPI呼び出しとinout捕捉だけを抽出したコンパイル検証用。
// アプリ実装ではなく、実行もしない。
import Photos

func collectAlbums(under folder: PHCollectionList, visited: inout Set<String>) -> [String] {
    guard visited.insert(folder.localIdentifier).inserted else { return [] }
    let children = PHCollectionList.fetchCollections(in: folder, options: nil)
    var result: [String] = []
    children.enumerateObjects { collection, _, _ in
        if let album = collection as? PHAssetCollection {
            result.append(album.localIdentifier)
        } else if let child = collection as? PHCollectionList {
            result.append(contentsOf: collectAlbums(under: child, visited: &visited))
        }
    }
    return result
}

func topLevel() -> PHFetchResult<PHCollection> {
    PHCollectionList.fetchTopLevelUserCollections(with: nil)
}
