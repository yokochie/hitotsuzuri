import XCTest
@testable import HitotsuzuriCore

final class U2IntegrationTests:XCTestCase {
    func directory()throws ->URL {
        let d=URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("U2Integration-"+UUID().uuidString)
        try FileManager.default.createDirectory(at:d,withIntermediateDirectories:true)
        addTeardownBlock {try? FileManager.default.removeItem(at:d)}; return d
    }
    @MainActor func make(_ store:any SelectionStoring)->SelectionWorkflow {SelectionWorkflow(library:PhotoLibraryAccess(source:U2Library()),images:U2Images(),store:store)}
    @MainActor func testRealSaveNewWorkflowRestoresOnlyLastCommit() async throws {
        let s=SelectionPersistence(directory:try directory()),w=make(s); await draft(w); await w.confirm(); let saved=w.lastCommitted
        w.toggle("1"); await w.loadImage("5"); w.toggle("5")
        let restored=make(s); await restored.start()
        XCTAssertEqual(restored.lastCommitted,saved); XCTAssertEqual(restored.selection.orderedIDs,["1","2","3","4"]); XCTAssertEqual(restored.images.count,4)
    }
    @MainActor func testCorruptOriginalUntouchedUntilNewExplicitConfirm() async throws {
        let d=try directory(),bytes=Data("bad".utf8),url=d.appendingPathComponent("selection.json")
        try bytes.write(to:url); let s=SelectionPersistence(directory:d),w=make(s); await w.start()
        XCTAssertEqual(try Data(contentsOf:url),bytes); XCTAssertFalse(FileManager.default.fileExists(atPath:d.appendingPathComponent("quarantine").path))
        await draft(w); await w.confirm(); XCTAssertNotNil(w.lastCommitted)
        let backups=try FileManager.default.contentsOfDirectory(at:d.appendingPathComponent("quarantine"),includingPropertiesForKeys:nil)
        XCTAssertEqual(backups.count,1); XCTAssertEqual(try Data(contentsOf:backups[0]),bytes)
        let restored=make(s); await restored.start(); XCTAssertEqual(restored.lastCommitted,w.lastCommitted)
    }
    @MainActor func testInjectedReplaceFailureThenExplicitRetryReusesBackup() async throws {
        let d=try directory(),url=d.appendingPathComponent("selection.json"),bytes=Data("bad".utf8)
        try bytes.write(to:url)
        let fail=SelectionPersistence(directory:d,checkpoint:{phase,_ in if phase == .beforeReplace {throw PickerFailure.ioFailure}})
        let first=make(fail); await draft(first); await first.confirm()
        XCTAssertEqual(first.error,.ioFailure); XCTAssertEqual(try Data(contentsOf:url),bytes)
        let next=make(SelectionPersistence(directory:d)); await draft(next); await next.confirm(); XCTAssertNotNil(next.lastCommitted)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:d.appendingPathComponent("quarantine").path).count,1)
    }
    @MainActor func testUnknownVersionCannotBeReplacedByConfirm() async throws {
        let d=try directory(),url=d.appendingPathComponent("selection.json"),bytes=Data("{\"schemaVersion\":99}".utf8)
        try bytes.write(to:url); let w=make(SelectionPersistence(directory:d)); await draft(w); await w.confirm()
        XCTAssertEqual(w.error,.unsupportedVersion); XCTAssertEqual(try Data(contentsOf:url),bytes); XCTAssertNil(w.lastCommitted); XCTAssertEqual(w.selection.orderedIDs.count,4)
    }
    @MainActor func testOversizedOriginalHasDistinctNonRecoveryGuidance() async throws {
        let d=try directory(),url=d.appendingPathComponent("selection.json"),bytes=Data(repeating:65,count:1024*1024+1)
        try bytes.write(to:url); let w=make(SelectionPersistence(directory:d)); await w.start()
        XCTAssertTrue(PresentationSnapshot(w).statusText.contains("上限")); XCTAssertFalse(PresentationSnapshot(w).statusText.contains("改めて4枚"))
        await draft(w); await w.confirm(); XCTAssertNil(w.lastCommitted); XCTAssertEqual(try Data(contentsOf:url),bytes)
    }
}
