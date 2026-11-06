import XCTest
@testable import HitotsuzuriCore

final class ArticleModelTests: XCTestCase {
    func testPublishedReferenceVectorMatchesIndependentEncoding() throws {
        let decoder=JSONDecoder(); decoder.dateDecodingStrategy = .secondsSince1970
        let source=try decoder.decode(ArticleSource.self,from:Data(#"{"selectionID":"11111111-1111-1111-1111-111111111111","albumID":"album","albumTitle":"記事","orderedAssetIDs":["a","b","c","d"],"confirmedAt":0,"selectionRevision":1}"#.utf8))
        let content=ArticleContent(source:source)
        XCTAssertEqual(ArticleFingerprint.canonicalBytes(source:source,content:content).count,848)
        XCTAssertEqual(ArticleFingerprint.content(source:source,content:content),"c371afcd1918af5e9d37c02cc94c6dfbd059aeee0aa0e26ea8b86aa1e5af26a3")
    }
    func testUnrepresentableSourceTimestampIsRejected() throws {
        let selection=CommittedSelection(albumID:"album",albumTitle:"記事",orderedAssetIDs:["a","b","c","d"],confirmedAt:Date(timeIntervalSince1970:Double.greatestFiniteMagnitude))
        XCTAssertThrowsError(try ArticleSource(selection:selection))
    }
    func testCanonicalEncodingContainsFieldNames() throws {
        let source=try ArticleFixtures.source(), content=ArticleContent(source:source)
        let bytes=ArticleFingerprint.canonicalBytes(source:source,content:content)
        XCTAssertNotNil(bytes.range(of:Data("title".utf8)))
        XCTAssertNotNil(bytes.range(of:Data("orderedAssetIDs".utf8)))
    }
    func source(_ ids: [String] = ["a", "b", "c", "d"]) throws -> ArticleSource {
        try ArticleSource(selection: CommittedSelection(albumID: "album", albumTitle: "日本語@260101", orderedAssetIDs: ids))
    }
    func testFourPhotosPreserveOrder() throws {
        let value = try source()
        XCTAssertEqual(value.orderedAssetIDs, ["a", "b", "c", "d"])
        XCTAssertEqual(value.selectionRevision, 1)
    }
    func testDuplicateAndMissingPhotosAreRejected() {
        XCTAssertThrowsError(try source(["a", "a", "c", "d"]))
        XCTAssertThrowsError(try source(["a"]))
    }
    func testContentTextRoundTrip() throws {
        let s = try source()
        var c = ArticleContent(source: s)
        c.introduction = "日本語\n😀\"引用\""
        let decoded = try JSONDecoder().decode(ArticleContent.self, from: JSONEncoder().encode(c))
        XCTAssertEqual(decoded, c)
    }
    func testContentRejectsWrongPhotoOrder() throws {
        let s = try source()
        var c = ArticleContent(source: s)
        c.photoTexts.reverse()
        XCTAssertThrowsError(try c.validate(source: s))
    }
    func testFingerprintIsStableAndSensitiveToText() throws {
        let s = try source()
        var c = ArticleContent(source: s)
        let first = ArticleFingerprint.content(source: s, content: c)
        XCTAssertEqual(first, ArticleFingerprint.content(source: s, content: c))
        c.title += " "
        XCTAssertNotEqual(first, ArticleFingerprint.content(source: s, content: c))
    }
    func testFingerprintDoesNotNormalizeUnicodeOrNewlines() throws {
        let s = try source()
        var a = ArticleContent(source: s), b = a
        a.title = "é"; b.title = "e\u{301}"
        XCTAssertNotEqual(ArticleFingerprint.content(source: s, content: a), ArticleFingerprint.content(source: s, content: b))
        a.title = "a\r\nb"; b.title = "a\nb"
        XCTAssertNotEqual(ArticleFingerprint.content(source: s, content: a), ArticleFingerprint.content(source: s, content: b))
    }
    func testCalendarDayValidation() {
        XCTAssertTrue(ArticleCalendarDay(year: 2000, month: 2, day: 29).isValid)
        XCTAssertFalse(ArticleCalendarDay(year: 2026, month: 2, day: 31).isValid)
    }
}
