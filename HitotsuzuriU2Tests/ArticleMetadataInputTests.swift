import XCTest
@testable import HitotsuzuriCore

final class ArticleMetadataInputTests: XCTestCase {
    func testInvalidRawUnicodeChangesAreComparedByBytes() throws {
        var first=ArticleMetadataInput(content:try content()), second=first
        first.change(year:"e\u{301}",month:"",day:"")
        second.change(year:"\u{e9}",month:"",day:"")
        XCTAssertNotEqual(first,second)
        XCTAssertEqual(Array(first.year.utf8),[0x65,0xcc,0x81])
        let prior=first
        first.change(year:"\u{e9}",month:"",day:"")
        XCTAssertNotEqual(first,prior); XCTAssertEqual(Array(first.year.utf8),[0xc3,0xa9])
    }
    private func content() throws -> ArticleContent { ArticleContent(source: try DraftFixtures.source()) }
    func testEmptyDateIsAbsent() throws {
        let input = ArticleMetadataInput(content: try content())
        XCTAssertNil(input.validationMessage)
        XCTAssertNil(try input.applying(to: content()).shootingDate)
    }
    func testYearBoundariesAreValidWithoutTimezoneConversion() throws {
        for year in ["1", "9999"] {
            var input = ArticleMetadataInput(content: try content())
            input.change(year: year, month: "12", day: "31")
            let result = try input.applying(to: content())
            XCTAssertEqual(result.shootingDate?.year, Int(year)); XCTAssertEqual(result.dateCandidateState, .candidate)
        }
    }
    func testPartialAndNonAsciiRawAreRetainedAndRejected() throws {
        for values in [("2026", "", "1"), ("２０２６", "1", "1"), (" 2026", "1", "1"), ("0", "1", "1"), ("10000", "1", "1")] {
            var input = ArticleMetadataInput(content: try content())
            input.change(year: values.0, month: values.1, day: values.2)
            XCTAssertEqual(input.year, values.0); XCTAssertNotNil(input.validationMessage)
            XCTAssertThrowsError(try input.applying(to: content()))
        }
    }
    func testGregorianLeapValidation() throws {
        var input = ArticleMetadataInput(content: try content())
        input.change(year: "1900", month: "2", day: "29")
        XCTAssertThrowsError(try input.applying(to: content()))
        input.change(year: "2000", month: "2", day: "29")
        XCTAssertEqual(try input.applying(to: content()).shootingDate?.day, 29)
    }
    func testConfirmIsExplicitAndChangeReturnsToCandidate() throws {
        var input = ArticleMetadataInput(content: try content())
        input.change(year: "2026", month: "9", day: "13")
        try input.confirm(); XCTAssertEqual(input.candidateState, .confirmed)
        input.change(year: "2026", month: "9", day: "14")
        XCTAssertEqual(input.candidateState, .candidate)
        XCTAssertEqual(try input.applying(to: content()).dateCandidateState, .candidate)
    }
    func testInvalidCannotBeConfirmed() throws {
        var input = ArticleMetadataInput(content: try content())
        input.change(year: "2026", month: "2", day: "31")
        XCTAssertThrowsError(try input.confirm())
    }
    func testRemovalAndRawDifference() throws {
        var input = ArticleMetadataInput(content: try content())
        let baseline = input
        input.change(year: "2026", month: "", day: "")
        XCTAssertNotEqual(input, baseline)
        input.remove(); XCTAssertEqual(input, baseline)
        XCTAssertEqual(try input.applying(to: content()).dateCandidateState, .absent)
    }
    func testExistingContentRestoresWithoutCandidateReapplication() throws {
        var original = try content()
        original.title = ""; original.shootingDate = ArticleCalendarDay(year: 2024, month: 2, day: 29)
        original.dateCandidateState = .confirmed; original.people = "人👨‍👩‍👧\n"
        let input = ArticleMetadataInput(content: original)
        XCTAssertEqual(try input.applying(to: original), original)
        XCTAssertEqual(input.year, "2024"); XCTAssertEqual(input.candidateState, .confirmed)
    }
}
