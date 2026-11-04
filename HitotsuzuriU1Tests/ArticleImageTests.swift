import XCTest
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers
@testable import HitotsuzuriCore

final class ArticleImageTests: XCTestCase {
    func testLargeImageIsReducedAndJPEG() throws {
        let input = try ArticleImageFixture.make(width: 3000, height: 2000)
        let result = try ArticleImageConverter.convert(input)
        XCTAssertEqual(result.width, 2560); XCTAssertLessThanOrEqual(result.height, 2560)
        XCTAssertEqual(result.bytes.prefix(2), Data([0xff, 0xd8]))
    }
    func testSmallImageIsNotUpscaled() throws {
        let result = try ArticleImageConverter.convert(ArticleImageFixture.make(width: 60, height: 40))
        XCTAssertEqual(result.width, 60); XCTAssertEqual(result.height, 40)
    }
    func testOrientationIsAppliedExactlyOnce() throws {
        let input = try ArticleImageFixture.make(width: 60, height: 40, orientation: 6)
        let result = try ArticleImageConverter.convert(input)
        XCTAssertEqual(result.width, 40); XCTAssertEqual(result.height, 60)
    }
    func testGPSAndSourceTextAreNotCopied() throws {
        let result = try ArticleImageConverter.convert(ArticleImageFixture.make(width: 30, height: 20))
        let source = CGImageSourceCreateWithData(result.bytes as CFData, nil)!
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)! as NSDictionary
        XCTAssertNil(properties[kCGImagePropertyGPSDictionary])
        XCTAssertFalse(String(describing: properties).contains("PRIVATE-LOCATION"))
    }
    func testCorruptImageFails() throws {
        let url = ArticleFixtures.root().appendingPathComponent("broken")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not image".utf8).write(to: url)
        XCTAssertThrowsError(try ArticleImageConverter.convert(ArticleImageInput(url: url, orientation: 1)))
    }
    func testInvalidOrientationFails() throws {
        let good = try ArticleImageFixture.make(width: 30, height: 20)
        XCTAssertThrowsError(try ArticleImageConverter.convert(ArticleImageInput(url: good.url, orientation: 9)))
    }
}

enum ArticleImageFixture {
    static func make(width: Int, height: Int, orientation: UInt32 = 1) throws -> ArticleImageInput {
        let url = ArticleFixtures.root().appendingPathComponent("source.png")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, [kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 35, kCGImagePropertyGPSLatitudeRef: "N"], kCGImagePropertyExifDictionary: [kCGImagePropertyExifUserComment: "PRIVATE-LOCATION"]] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ArticleFailure.ioFailure }
        return ArticleImageInput(url: url, orientation: orientation)
    }
}
