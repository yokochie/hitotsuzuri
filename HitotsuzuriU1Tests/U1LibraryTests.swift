import XCTest
@testable import HitotsuzuriCore

final class U1LibraryTests: XCTestCase {
    @MainActor func testAuthorizationPreventsFetch() async { let s=FakeLibrarySource(); s.access = .denied; do { _ = try await PhotoLibraryAccess(source:s).hierarchy(); XCTFail() } catch {}; XCTAssertEqual(s.fetchCount,0) }
    @MainActor func testDeepAndOverlappingFolders() { let s=FakeLibrarySource(); let a=PhotoLibraryAccess(source:s).albums(in:["parent","child"],hierarchy:s.value); XCTAssertEqual(a.map(\.id),["a","b","c"]) }
    @MainActor func testEmptyFolders() { let s=FakeLibrarySource(); XCTAssertTrue(PhotoLibraryAccess(source:s).albums(in:[],hierarchy:s.value).isEmpty) }
    @MainActor func testUnknownFolderExcluded() { let s=FakeLibrarySource(); XCTAssertTrue(PhotoLibraryAccess(source:s).albums(in:["unknown"],hierarchy:s.value).isEmpty) }
    @MainActor func testAssetOrder() async throws { let s=FakeLibrarySource(); s.photos["a"]=["4","2","1"]; let ids=try await PhotoLibraryAccess(source:s).assets(in:"a").map(\.id); XCTAssertEqual(ids,["4","2","1"]) }
    @MainActor func testInvalidMembership() async { let s=FakeLibrarySource(); do { try await PhotoLibraryAccess(source:s).validate(folders:["child"],albumID:"b",assets:["1","2","3","4"]); XCTFail() } catch {} }
}

