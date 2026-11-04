import XCTest
import CryptoKit
@testable import HitotsuzuriCore

final class U2PersistenceTests:XCTestCase {
    func directory() throws ->URL {
        let value=URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("U2-"+UUID().uuidString)
        try FileManager.default.createDirectory(at:value,withIntermediateDirectories:true)
        addTeardownBlock { try? FileManager.default.removeItem(at:value) }; return value
    }
    func backup(_ dir:URL,_ bytes:Data)->URL {
        let hash=SHA256.hash(data:bytes).map {String(format:"%02x",$0)}.joined()
        return dir.appendingPathComponent("quarantine").appendingPathComponent("selection-"+hash+".json")
    }
    func testExplicitConfirmBacksUpExactCorruptBytesThenSaves() async throws {
        let dir=try directory(), bytes=Data("broken".utf8), original=dir.appendingPathComponent("selection.json")
        try bytes.write(to:original); let p=SelectionPersistence(directory:dir)
        let expected=candidate(); try await p.confirmSelection(expected)
        XCTAssertEqual(try Data(contentsOf:backup(dir,bytes)),bytes)
        if case .valid(let s)=await p.loadSelection() {XCTAssertEqual(s,expected)} else {XCTFail()}
    }
    func testMatchingBackupReused() async throws {
        let dir=try directory(), bytes=Data("broken".utf8), target=backup(dir,bytes)
        try FileManager.default.createDirectory(at:target.deletingLastPathComponent(),withIntermediateDirectories:true)
        try bytes.write(to:target); try bytes.write(to:dir.appendingPathComponent("selection.json"))
        try await SelectionPersistence(directory:dir).confirmSelection(candidate())
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:target.deletingLastPathComponent().path).count,1)
    }
    func testMismatchedBackupProtectsOriginal() async throws {
        let dir=try directory(), bytes=Data("broken".utf8), target=backup(dir,bytes), original=dir.appendingPathComponent("selection.json")
        try FileManager.default.createDirectory(at:target.deletingLastPathComponent(),withIntermediateDirectories:true)
        try Data("different".utf8).write(to:target); try bytes.write(to:original)
        do {try await SelectionPersistence(directory:dir).confirmSelection(candidate()); XCTFail()} catch { XCTAssertEqual(error as? PickerFailure,.ioFailure) }
        XCTAssertEqual(try Data(contentsOf:original),bytes)
    }
    func testUnknownVersionNeverBackedUpOrReplaced() async throws {
        let dir=try directory(), bytes=Data("{\"schemaVersion\":99}".utf8), original=dir.appendingPathComponent("selection.json")
        try bytes.write(to:original); do {try await SelectionPersistence(directory:dir).confirmSelection(candidate()); XCTFail()} catch {XCTAssertEqual(error as? PickerFailure,.unsupportedVersion)}
        XCTAssertEqual(try Data(contentsOf:original),bytes); XCTAssertFalse(FileManager.default.fileExists(atPath:backup(dir,bytes).path))
    }
    func testOversizeNeverRecovered() async throws {
        let dir=try directory(), bytes=Data(repeating:65,count:1024*1024+1), original=dir.appendingPathComponent("selection.json")
        try bytes.write(to:original); do {try await SelectionPersistence(directory:dir).confirmSelection(candidate()); XCTFail()} catch {}
        XCTAssertEqual(try Data(contentsOf:original),bytes); XCTAssertFalse(FileManager.default.fileExists(atPath:backup(dir,bytes).path))
    }
    func testSymlinkQuarantineRefused() async throws {
        let dir=try directory(), other=try directory(), bytes=Data("broken".utf8)
        try bytes.write(to:dir.appendingPathComponent("selection.json")); try FileManager.default.createSymbolicLink(at:dir.appendingPathComponent("quarantine"),withDestinationURL:other)
        do {try await SelectionPersistence(directory:dir).confirmSelection(candidate()); XCTFail()} catch {}
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath:other.path).isEmpty)
    }
    func testCorruptSettingsAlwaysPreserved() async throws {
        let dir=try directory(), bytes=Data("{\"schemaVersion\":1,\"folderIDs\":[\"\"]}".utf8), original=dir.appendingPathComponent("settings.json")
        try bytes.write(to:original); do {try await SelectionPersistence(directory:dir).saveSettings(.init(folderIDs:["f"])); XCTFail()} catch {}
        XCTAssertEqual(try Data(contentsOf:original),bytes)
    }
    func testInjectedFailuresNeverReplaceOriginal() async throws {
        for step in [PersistenceCheckpoint.beforeBackup,.afterBackup,.beforeReplace] {
            let dir=try directory(), bytes=Data("broken".utf8), original=dir.appendingPathComponent("selection.json")
            try bytes.write(to:original)
            let p=SelectionPersistence(directory:dir,checkpoint:{ phase,_ in if phase==step {throw PickerFailure.ioFailure} })
            do {try await p.confirmSelection(candidate()); XCTFail()} catch {XCTAssertEqual(error as? PickerFailure,.ioFailure)}
            XCTAssertEqual(try Data(contentsOf:original),bytes)
        }
    }
    func testOriginalChangedAfterBackupIsNeverOverwritten() async throws {
        let dir=try directory(), original=dir.appendingPathComponent("selection.json"), bytes=Data("broken".utf8), changed=Data("changed".utf8)
        try bytes.write(to:original)
        let p=SelectionPersistence(directory:dir,checkpoint:{ phase,url in if phase == .afterBackup {try changed.write(to:url)} })
        do {try await p.confirmSelection(candidate()); XCTFail()} catch {XCTAssertEqual(error as? PickerFailure,.ioFailure)}
        XCTAssertEqual(try Data(contentsOf:original),changed); XCTAssertEqual(try Data(contentsOf:backup(dir,bytes)),bytes)
    }
}
