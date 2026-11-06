import XCTest
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers
@testable import HitotsuzuriCore

final class ArticleImageTests: XCTestCase {
    @MainActor func testPreviewCancellationIgnoresDelayedImage() async throws {
        let driver=ArticleDelayedPreview(), previews=ArticlePhotoPreviews(assetIDs:["a","b","c","d"],images:driver)
        let task=Task {await previews.load()}
        while driver.continuation == nil {await Task.yield()}
        previews.cancel(); driver.complete(); await task.value
        XCTAssertTrue(previews.states.isEmpty); XCTAssertEqual(driver.cancellations,1); XCTAssertEqual(driver.requested,["a"])
    }
    @MainActor func testDuplicatePreviewLoadDoesNotIssueSecondRequest() async throws {
        let driver=ArticleDelayedPreview(), previews=ArticlePhotoPreviews(assetIDs:["a","b","c","d"],images:driver)
        let task=Task {await previews.load()}
        while driver.continuation == nil {await Task.yield()}
        await previews.load(); XCTAssertEqual(driver.requested,["a"])
        previews.cancel(); driver.complete(); await task.value
    }
    @MainActor func testBlockedPreviewDoesNotBlockTextSave() async throws {
        let driver=ArticleDelayedPreview(), source=try ArticleFixtures.source(), previews=ArticlePhotoPreviews(assetIDs:source.orderedAssetIDs,images:driver)
        let task=Task {await previews.load()}
        while driver.continuation == nil {await Task.yield()}
        let session=ArticleEditSession(source:source,store:ArticlePersistence(directory:ArticleFixtures.root()))
        session.content.introduction="画像待ちでも本文を保存"
        let saved=await session.save(); XCTAssertTrue(saved); XCTAssertEqual(session.saved?.content.introduction,"画像待ちでも本文を保存")
        previews.cancel(); driver.complete(); await task.value
    }
    @MainActor func testFourPreviewStatesDoNotDependOnArticleText() async throws {
        let driver=ArticlePreviewFake(), previews=ArticlePhotoPreviews(assetIDs:["a","b","c","d"],images:driver)
        await previews.load()
        XCTAssertEqual(driver.requested,["a","b","c","d"])
        XCTAssertEqual(previews.states["b"]?.message,ArticleFailure.assetUnavailable.message)
        guard case .ready?=previews.states["a"], case .ready?=previews.states["c"] else {return XCTFail()}
        previews.cancel(); XCTAssertEqual(driver.released,[])
    }
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
@MainActor private final class ArticleDelayedPreview:ImageAccessing {
    var requested:[String]=[], cancellations=0
    var continuation:CheckedContinuation<ImageBuffer,Error>?
    func image(_ id:String,validation:Bool,deadline:ContinuousClock.Instant?) async throws ->ImageBuffer {
        requested.append(id); return try await withCheckedThrowingContinuation {continuation=$0}
    }
    func complete() {continuation?.resume(returning:ImageBuffer(pixels:Data([1,2,3,255]),width:1,height:1,bytesPerRow:4)); continuation=nil}
    func cancelDisplayRequests() {cancellations += 1}
    func release(except ids:Set<String>) {}
}
@MainActor final class ArticlePreviewFake:ImageAccessing {
    var requested:[String]=[], released:Set<String>=[]
    func image(_ assetID:String,validation:Bool,deadline:ContinuousClock.Instant?) async throws ->ImageBuffer {
        requested.append(assetID)
        if assetID == "b" {throw PickerFailure.unavailable}
        return ImageBuffer(pixels:Data([20,40,60,255]),width:1,height:1,bytesPerRow:4)
    }
    func cancelDisplayRequests() {}
    func release(except ids:Set<String>) {released=ids}
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
