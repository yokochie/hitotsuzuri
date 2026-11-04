import XCTest
@testable import HitotsuzuriCore

final class U1ModelTests: XCTestCase {
    func testSelectionLimit() { var s = EditingSelection(); for id in ["a","b","c","d","e"] { s.toggle(id, available: true) }; XCTAssertEqual(s.orderedIDs, ["a","b","c","d"]) }
    func testDeselectAndReselect() { var s = EditingSelection(); for id in ["a","b","c","d","b","b"] { s.toggle(id, available: true) }; XCTAssertEqual(s.orderedIDs, ["a","c","d","b"]) }
    func testUnavailableCannotSelect() { var s = EditingSelection(); s.toggle("x", available: false); XCTAssertTrue(s.orderedIDs.isEmpty) }
    func testOpaqueIDsAreDistinct() { var s = EditingSelection(); s.toggle("A", available: true); s.toggle("a", available: true); XCTAssertEqual(s.orderedIDs.count, 2) }
    func testCommitRequiresExactlyFourUniqueIDs() { XCTAssertFalse(CommittedSelection(albumID: "a", albumTitle: "", orderedAssetIDs: ["1","1","2","3"]).isValid); XCTAssertFalse(CommittedSelection(albumID: "a", albumTitle: "", orderedAssetIDs: []).isValid) }
    func testCommitRoundTrip() throws { let s = CommittedSelection(albumID: "a", albumTitle: "名前\n引用\"", orderedAssetIDs: ["1","2","3","4"]); XCTAssertEqual(try JSONDecoder().decode(CommittedSelection.self, from: JSONEncoder().encode(s)), s) }
}

