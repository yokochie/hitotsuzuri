import XCTest
@testable import HitotsuzuriCore

final class U1PersistenceTests: XCTestCase {
    func testMalformedSettingsAreRejectedAndOriginalPreserved() async throws {
        let dir=directory(); try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        let bytes=Data("{\"schemaVersion\":1,\"folderIDs\":[\"\"]}".utf8)
        let url=dir.appendingPathComponent("settings.json"); try bytes.write(to:url)
        let store=SelectionPersistence(directory:dir)
        if case .failure(.corruptData)=await store.loadSettings() {} else { XCTFail("意味上破損した設定を正常扱いした") }
        do { try await store.saveSettings(.init(folderIDs:["valid"])); XCTFail("破損設定を上書きした") } catch { XCTAssertEqual(error as? PickerFailure,.corruptData) }
        XCTAssertEqual(try Data(contentsOf:url),bytes)
    }
    func directory() -> URL { URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("HitotsuzuriTests-"+UUID().uuidString) }
    func testMissing() async { let p=SelectionPersistence(directory:directory()); if case .missing = await p.loadSelection() {} else { XCTFail() } }
    func testSelectionRoundTrip() async throws { let p=SelectionPersistence(directory:directory()); let s=testSelection(); try await p.saveSelection(s); if case .valid(let v) = await p.loadSelection() { XCTAssertEqual(v,s) } else { XCTFail() } }
    func testSettingsRoundTrip() async throws { let p=SelectionPersistence(directory:directory()); let s=TargetFolderSettings(folderIDs:["親","子","親"]); try await p.saveSettings(s); if case .valid(let v)=await p.loadSettings() { XCTAssertEqual(v,s) } else { XCTFail() } }
    func testInvalidSelectionRejected() async { let p=SelectionPersistence(directory:directory()); do { try await p.saveSelection(.init(albumID:"",albumTitle:"",orderedAssetIDs:[])); XCTFail() } catch {} }
    func testUnknownVersionProtected() async throws { let dir=directory(); try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true); let bytes=Data("{\"schemaVersion\":99}".utf8); try bytes.write(to:dir.appendingPathComponent("selection.json")); let p=SelectionPersistence(directory:dir); do { try await p.saveSelection(testSelection()); XCTFail() } catch { XCTAssertEqual(error as? PickerFailure,.unsupportedVersion) }; XCTAssertEqual(try Data(contentsOf:dir.appendingPathComponent("selection.json")),bytes) }
    func testCorruptProtected() async throws { let dir=directory(); try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true); let bytes=Data("bad".utf8); try bytes.write(to:dir.appendingPathComponent("selection.json")); let p=SelectionPersistence(directory:dir); do { try await p.saveSelection(testSelection()); XCTFail() } catch { XCTAssertEqual(error as? PickerFailure,.corruptData) } }
}

