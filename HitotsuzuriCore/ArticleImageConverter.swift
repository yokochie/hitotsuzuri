import Foundation
import ImageIO
import CoreImage
import UniformTypeIdentifiers

/// PhotoKit の編集入力を変換終了まで保持する。元画像の byte 列は読み込まない。
public struct ArticleImageInput: @unchecked Sendable {
    public let url: URL
    public let orientation: UInt32
    let owner: AnyObject?
    public init(url: URL, orientation: UInt32) { self.url = url; self.orientation = orientation; owner = nil }
    init(url: URL, orientation: UInt32, owner: AnyObject) { self.url = url; self.orientation = orientation; self.owner = owner }
}

public final class ArticleImageBudget: @unchecked Sendable {
    private let lock = NSLock()
    private var reserved = 0
    public let limit: Int
    public init(limit: Int = 256 * 1024 * 1024) { self.limit = limit }
    func reserve(_ count: Int) throws -> ArticleImageLease {
        lock.lock(); defer { lock.unlock() }
        guard count > 0, count <= limit - reserved else { throw ArticleFailure.capacity }
        reserved += count
        return ArticleImageLease(budget: self, count: count)
    }
    fileprivate func release(_ count: Int) { lock.lock(); reserved -= count; lock.unlock() }
}
final class ArticleImageLease: Sendable {
    let budget: ArticleImageBudget, count: Int
    init(budget: ArticleImageBudget, count: Int) { self.budget = budget; self.count = count }
    deinit { budget.release(count) }
}
public struct ArticleJPEG: Sendable {
    public let bytes: Data
    public let width: Int
    public let height: Int
    let lease: ArticleImageLease?
    public init(bytes: Data, width: Int, height: Int) { self.bytes = bytes; self.width = width; self.height = height; lease = nil }
    init(bytes: Data, width: Int, height: Int, lease: ArticleImageLease) { self.bytes = bytes; self.width = width; self.height = height; self.lease = lease }
}

public enum ArticleImageConverter {
    public static func convert(_ input: ArticleImageInput, budget: ArticleImageBudget = ArticleImageBudget()) throws -> ArticleJPEG {
        guard input.url.isFileURL, let orientation = CGImagePropertyOrientation(rawValue: input.orientation) else { throw ArticleFailure.invalidInput }
        // 最大縮小面の三枚分と JPEG の余裕を、デコード開始前に確保する。
        let lease = try budget.reserve(2560 * 2560 * 4 * 3 + 32 * 1024 * 1024)
        return try autoreleasepool {
            guard let source = CGImageSourceCreateWithURL(input.url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  let width = properties[kCGImagePropertyPixelWidth] as? Int,
                  let height = properties[kCGImagePropertyPixelHeight] as? Int, width > 0, height > 0 else { throw ArticleFailure.assetUnavailable }
            let edge = min(2560, max(width, height))
            guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: edge, kCGImageSourceCreateThumbnailWithTransform: false, kCGImageSourceShouldCacheImmediately: true] as CFDictionary) else { throw ArticleFailure.assetUnavailable }
            let image = CIImage(cgImage: thumbnail).oriented(orientation)
            let space = CGColorSpace(name: CGColorSpace.sRGB)!
            let context = CIContext(options: [.useSoftwareRenderer: true, .cacheIntermediates: false])
            guard let pixels = context.createCGImage(image, from: image.extent, format: .RGBA8, colorSpace: space) else { throw ArticleFailure.assetUnavailable }
            let data = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else { throw ArticleFailure.ioFailure }
            // 新規 JPEG には元の辞書を渡さず、向きは画素へ焼き込む。
            CGImageDestinationAddImage(destination, pixels, [kCGImageDestinationLossyCompressionQuality: 0.9, kCGImagePropertyOrientation: 1] as CFDictionary)
            guard CGImageDestinationFinalize(destination), data.length <= 32 * 1024 * 1024 else { throw ArticleFailure.capacity }
            return ArticleJPEG(bytes: data as Data, width: pixels.width, height: pixels.height, lease: lease)
        }
    }
}
