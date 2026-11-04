import XCTest
@testable import HitotsuzuriCore
final class U3SaveCompletionTests:XCTestCase {
    func testRunnerReady() {XCTAssertTrue(candidate().isValid)}
    @MainActor func prepare(_ callback:@escaping @Sendable () async ->Void) async throws ->(SelectionWorkflow,CompletionStore,U3Library) {
        let dir=URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("U3-"+UUID().uuidString)
        addTeardownBlock {try? FileManager.default.removeItem(at:dir)}
        let s=CompletionStore(directory:dir),l=U3Library()
        try await s.base.saveSettings(.init(folderIDs:["f"])); try await s.base.saveSelection(candidate())
        let w=SelectionWorkflow(library:PhotoLibraryAccess(source:l),images:U3Images(),store:s)
        await w.start(); w.toggle("4"); await w.loadImage("5"); w.toggle("5")
        await s.setCallback(callback); return(w,s,l)
    }
    @MainActor func testAuthorizationLostAfterActualWriteKeepsSuccess() async throws {
        let(w,s,l)=try await prepare({})
        await s.setCallback {await MainActor.run {l.access = .denied}}
        await w.confirm()
        if case .valid(let disk)=await s.loadSelection() {XCTAssertEqual(w.lastCommitted,disk)} else {XCTFail()}
        XCTAssertEqual(w.selectionSaveState,.saved); XCTAssertEqual(w.authorization,.denied); XCTAssertNil(w.error)
        XCTAssertTrue(PresentationSnapshot(w).statusText.contains("保存")); XCTAssertTrue(PresentationSnapshot(w).statusText.contains("許可"))
    }
    @MainActor func testCancellationAfterActualWriteKeepsSuccess() async throws {
        let(w,s,_)=try await prepare({withUnsafeCurrentTask {$0?.cancel()}})
        let task=Task {await w.confirm()}; await task.value
        if case .valid(let disk)=await s.loadSelection() {XCTAssertEqual(w.lastCommitted,disk)} else {XCTFail()}
        XCTAssertEqual(w.selectionSaveState,.saved); XCTAssertNil(w.error)
    }
    @MainActor func testActualWriteFailureKeepsOldCommit() async throws {
        let(w,s,_)=try await prepare({}); let old=w.lastCommitted; await s.setFailure()
        await w.confirm(); XCTAssertEqual(w.lastCommitted,old); XCTAssertEqual(w.selectionSaveState,.failed(.ioFailure))
        if case .valid(let disk)=await s.loadSelection() {XCTAssertEqual(disk,old)} else {XCTFail()}
    }
    @MainActor func testAuthorizationBeforeWriteStillRequired() async throws {
        let(w,s,l)=try await prepare({}); let old=w.lastCommitted; l.access = .denied
        await w.confirm(); XCTAssertEqual(w.lastCommitted,old); XCTAssertEqual(w.error,.authorization)
        if case .valid(let disk)=await s.loadSelection() {XCTAssertEqual(disk,old)} else {XCTFail()}
    }
    @MainActor func testPlainSuccessMatchesDisk() async throws {
        let(w,s,_)=try await prepare({}); await w.confirm()
        if case .valid(let disk)=await s.loadSelection() {XCTAssertEqual(w.lastCommitted,disk)} else {XCTFail()}
        XCTAssertEqual(w.selectionSaveState,.saved)
    }
}

actor CompletionStore:SelectionStoring {
    let base:SelectionPersistence
    var callback:(@Sendable () async ->Void)?
    var failure=false
    init(directory:URL) {base=SelectionPersistence(directory:directory)}
    func setCallback(_ value:@escaping @Sendable () async ->Void) {callback=value}
    func setFailure() {failure=true}
    func loadSettings() async ->StoredValue<TargetFolderSettings> {await base.loadSettings()}
    func saveSettings(_ value:TargetFolderSettings) async throws {try await base.saveSettings(value)}
    func loadSelection() async ->StoredValue<CommittedSelection> {await base.loadSelection()}
    func saveSelection(_ value:CommittedSelection) async throws {
        if failure {throw PickerFailure.ioFailure}
        try await base.saveSelection(value); if let callback {await callback()}
    }
}
