import XCTest
@testable import HitotsuzuriCore

final class ArticleExportModelTests: XCTestCase {
    func testManifestRoundTripsAndPreservesFreeText() throws {
        let prepared = try ExportFixture.prepared()
        let manifest = ArticleExportManifest(jobID: UUID(), prepared: prepared)
        try manifest.validate(prepared: prepared)
        XCTAssertEqual(try ArticleExportManifest.decode(manifest.encoded()), manifest)
        XCTAssertTrue(prepared.rendered.plainText.contains("👨‍👩‍👧‍👦"))
    }
    func testUnknownManifestVersionIsRejected() throws {
        let prepared = try ExportFixture.prepared(); var value = ArticleExportManifest(jobID: UUID(), prepared: prepared)
        value.schemaVersion = 2
        XCTAssertThrowsError(try value.validate(prepared: prepared)) { XCTAssertEqual($0 as? ArticleFailure, .unsupportedVersion) }
    }
    func testMissingPhotoIsRejected() throws {
        let prepared = try ExportFixture.prepared(); var value = ArticleExportManifest(jobID: UUID(), prepared: prepared)
        value.orderedAssetIDs.removeLast()
        XCTAssertThrowsError(try value.validate(prepared: prepared))
    }
    func testWrongOrderIsRejected() throws {
        let prepared = try ExportFixture.prepared(); var value = ArticleExportManifest(jobID: UUID(), prepared: prepared)
        value.orderedAssetIDs.swapAt(0, 1)
        XCTAssertThrowsError(try value.validate(prepared: prepared))
    }
    func testFingerprintMismatchIsRejected() throws {
        let prepared = try ExportFixture.prepared(); var value = ArticleExportManifest(jobID: UUID(), prepared: prepared)
        value.inputFingerprint = "wrong"
        XCTAssertThrowsError(try value.validate(prepared: prepared))
    }
    func testChangedImageSettingsAreRejected() throws {
        let prepared = try ExportFixture.prepared(); var value = ArticleExportManifest(jobID: UUID(), prepared: prepared)
        value.quality = 0.5
        XCTAssertThrowsError(try value.validate(prepared: prepared))
    }
    func testPathTraversalAndAbsolutePathAreRejected() throws {
        let prepared = try ExportFixture.prepared(); var value = ArticleExportManifest(jobID: UUID(), prepared: prepared)
        value.relativeImagePaths[0] = "../01.jpg"
        XCTAssertThrowsError(try value.validate(prepared: prepared))
        value.relativeImagePaths[0] = "/01.jpg"
        XCTAssertThrowsError(try value.validate(prepared: prepared))
    }
    func testRecoveryUnknownVersionAndUnsafeExternalTitleAreSeparated() throws {
        let prepared = try ExportFixture.prepared(title: "../../\"$(anything)\"")
        var record = ArticleExportRecoveryRecord(jobID: UUID(), prepared: prepared, parentIdentity: ExportFixture.identity)
        XCTAssertFalse(record.finalName.contains("/")); XCTAssertFalse(record.stagingName.contains("$"))
        try record.validate()
        record.schemaVersion = 2
        XCTAssertThrowsError(try record.validate())
    }
}
