import XCTest
@testable import HitotsuzuriCore

final class U2ModelTests: XCTestCase {
    func testRunnerReady() { XCTAssertTrue(CommittedSelection(albumID:"a",albumTitle:"",orderedAssetIDs:["1","2","3","4"]).isValid) }
    func testRestoreBusyOnlyWhileLoadingOrValidating() { XCTAssertTrue(RestoreState.loading.isBusy); XCTAssertTrue(RestoreState.validating.isBusy); XCTAssertFalse(RestoreState.restored.isBusy); XCTAssertFalse(RestoreState.failed(.unavailable).isBusy) }
    func testSettingsAndSelectionSaveStatesAreIndependentValues() { let settings=SaveState.failed(.ioFailure), selection=SaveState.saved; XCTAssertNotEqual(settings,selection) }
    func testInvalidDateRejected() { XCTAssertFalse(CommittedSelection(albumID:"a",albumTitle:"",orderedAssetIDs:["1","2","3","4"],confirmedAt:Date(timeIntervalSince1970:.infinity)).isValid) }
    func testDuplicateCandidateRejected() { XCTAssertFalse(CommittedSelection(albumID:"a",albumTitle:"",orderedAssetIDs:["1","1","3","4"]).isValid) }
    func testEmptyIDRejected() { XCTAssertFalse(CommittedSelection(albumID:"",albumTitle:"",orderedAssetIDs:["1","2","3","4"]).isValid) }
    func testOpaqueIDsAndOrderPreserved() { XCTAssertEqual(CommittedSelection(albumID:"a/b",albumTitle:"",orderedAssetIDs:["4/x","2","3","1"]).orderedAssetIDs,["4/x","2","3","1"]) }
    func testDatePrecisionPreserved() { XCTAssertEqual(CommittedSelection(albumID:"a",albumTitle:"",orderedAssetIDs:["1","2","3","4"],confirmedAt:Date(timeIntervalSince1970:123)).confirmedAt,Date(timeIntervalSince1970:123)) }
}
