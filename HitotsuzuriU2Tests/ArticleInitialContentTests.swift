import XCTest
@testable import HitotsuzuriCore

final class ArticleInitialContentTests: XCTestCase {
    func testPrependScalarBeforeSuffixIsPreservedByteForByte() throws {
        let prefix = "記録\u{600}"
        let value = ArticleInitialContent(source: try DraftFixtures.source(prefix + "@260913"))
        XCTAssertEqual(Array(value.content.title.utf8), Array(prefix.utf8))
    }
    func testAbsoluteSuffixCreatesUnconfirmedDate() throws {
        let value = ArticleInitialContent(source: try DraftFixtures.source()).content
        XCTAssertEqual(value.title, "散歩")
        XCTAssertEqual(value.shootingDate, ArticleCalendarDay(year: 2026, month: 9, day: 13))
        XCTAssertEqual(value.dateCandidateState, .candidate)
    }
    func testTrailingNewlineIsNotAnAbsoluteSuffix() throws {
        let name = "記録@260913\n"
        XCTAssertEqual(ArticleInitialContent(source: try DraftFixtures.source(name)).content.title, name)
    }
    func testFullwidthDigitsAndAtAreNotRecognized() throws {
        for name in ["記録@２６０９１３", "記録＠260913", "記録@260913追記", "記録@260913 "] {
            let value = ArticleInitialContent(source: try DraftFixtures.source(name)).content
            XCTAssertEqual(value.title, name); XCTAssertNil(value.shootingDate)
        }
    }
    func testLeapDayAndEmptyTitle() throws {
        let value = ArticleInitialContent(source: try DraftFixtures.source("@000229")).content
        XCTAssertEqual(value.title, "")
        XCTAssertEqual(value.shootingDate, ArticleCalendarDay(year: 2000, month: 2, day: 29))
    }
    func testInvalidDateStillRemovesSyntacticSuffix() throws {
        let value = ArticleInitialContent(source: try DraftFixtures.source("記録@260231"))
        XCTAssertEqual(value.content.title, "記録"); XCTAssertNil(value.content.shootingDate)
        XCTAssertTrue(value.invalidDateSuffix)
    }
    func testLeapCenturyAndYearRange() throws {
        let value = ArticleInitialContent(source: try DraftFixtures.source("先@991231")).content
        XCTAssertEqual(value.shootingDate?.year, 2099)
        XCTAssertNil(ArticleInitialContent(source: try DraftFixtures.source("@010229")).content.shootingDate)
    }
    func testOnlyFinalSuffixRemovedWithoutNormalizingTitle() throws {
        let value = ArticleInitialContent(source: try DraftFixtures.source(" e\u{301} @240101@260913")).content
        XCTAssertEqual(value.title, " e\u{301} @240101")
    }
    func testBodiesAndPrivateMetadataRemainEmpty() throws {
        let source = try DraftFixtures.source()
        let value = ArticleInitialContent(source: source).content
        XCTAssertEqual(value.photoTexts.map(\.assetID), source.orderedAssetIDs)
        XCTAssertTrue(value.photoTexts.allSatisfy { $0.text.isEmpty })
        XCTAssertEqual([value.introduction,value.closing,value.location,value.equipment,value.film,value.people], Array(repeating: "", count: 6))
        XCTAssertEqual(ArticleContent(source: source).title, source.albumTitle)
    }
}
