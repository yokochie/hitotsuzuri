import XCTest
import Photos
@testable import HitotsuzuriCore

@MainActor final class ArticleCloudImageTests: XCTestCase {
    // T1: 実PhotoKit adapterが作るoptionsを注入境界で観測する。
    func testPhotoKitOptionsPermitRequestedCloudDownload() {
        var flags: [Bool] = []
        let reader = PhotoKitArticleImageReader(requestInput: { _, options, _ in
            flags.append(options.isNetworkAccessAllowed); return flags.count
        })
        _ = reader.request("cloud", networkAllowed: true) { _ in }
        _ = reader.request("local", networkAllowed: false) { _ in }
        XCTAssertEqual(flags, [true, false])
    }

    func testExplicitCloudRequestReachesReaderWhileDefaultStaysLocal() async throws {
        let reader = CloudImageReader(), access = makeAccess(reader)
        reader.automatic = true
        _ = try await access.image("cloud", networkAllowed: true)
        _ = try await access.image("local")
        XCTAssertEqual(reader.flags, [true, false])
    }

    // T3: 進捗を直接UIへ書き込まず、ImageAccessから中継する。
    func testDownloadProgressFlowsThroughImageAccess() async throws {
        let reader = CloudImageReader(), access = makeAccess(reader)
        var values: [Double] = []
        let task = Task { try await access.image("cloud", networkAllowed: true, progress: { values.append($0) }) }
        let started = await wait { !reader.flags.isEmpty }; XCTAssertTrue(started)
        reader.emit(0); reader.emit(0.25); reader.emit(1)
        reader.complete(.success(input()))
        _ = try await task.value
        XCTAssertEqual(values, [0, 0.25, 1])
    }

    // T5: 旧30/40/180秒を越えても、取得完了後に成功する。
    func testCloudAcquisitionCanFinishAfterFormerDeadlines() async throws {
        let reader = CloudImageReader(), clock = DraftDeadlineClock()
        let access = makeAccess(reader, clock: clock)
        let task = Task { try await access.image("cloud", networkAllowed: true) }
        let started = await wait { !reader.flags.isEmpty }; XCTAssertTrue(started)
        clock.advance(301)
        reader.complete(.success(input()))
        do { _ = try await task.value }
        catch { XCTFail("取得待ち301秒を旧期限で失敗にした: \(error)") }
    }

    // 対照: 既定のlocal経路は既存30秒期限を維持する。
    func testDefaultLocalRequestStillTimesOut() async throws {
        let reader = CloudImageReader(), clock = DraftDeadlineClock()
        let access = makeAccess(reader, clock: clock)
        let task = Task { try await access.image("local") }
        let started = await wait { !reader.flags.isEmpty }; XCTAssertTrue(started)
        clock.advance(30)
        reader.complete(.failure(.assetUnavailable))
        do { _ = try await task.value; XCTFail("local期限を失った") }
        catch { XCTAssertEqual(error as? ArticleFailure, .timedOut) }
    }

    // T7/T8: 進捗なしでもUI actorは操作でき、取消と遅い終端を分離する。
    func testCloudWaitCancellationKeepsGateUntilReaderTerminal() async throws {
        let reader = CloudImageReader(), access = makeAccess(reader), id = UUID()
        let task = Task { try await access.image("cloud", requestID: id, networkAllowed: true) }
        let started = await wait { !reader.flags.isEmpty }; XCTAssertTrue(started)
        access.cancel(id)
        do { _ = try await task.value; XCTFail() }
        catch { XCTAssertEqual(error as? ArticleFailure, .cancelled) }
        XCTAssertEqual(reader.cancelled, [1]); XCTAssertTrue(access.isBusy)
        reader.complete(.success(input()))
        XCTAssertFalse(access.isBusy)
    }

    private func makeAccess(_ reader: CloudImageReader, clock: any ImageClock = ContinuousImageClock()) -> ArticleImageAccess {
        ArticleImageAccess(reader: reader, clock: clock, convert: { _, _ in ArticleJPEG(bytes: Data([1]), width: 1, height: 1) })
    }
    private func input() -> ArticleImageInput {
        ArticleImageInput(url: URL(fileURLWithPath: "/synthetic-unused-input"), orientation: 1)
    }
    private func wait(_ condition: () -> Bool) async -> Bool {
        let end = ContinuousClock().now + .seconds(2)
        while !condition() {
            if ContinuousClock().now >= end { return false }
            await Task.yield()
        }
        return true
    }
}

@MainActor private final class CloudImageReader: ArticleImageReading {
    var flags: [Bool] = [], cancelled: [Int] = []
    var automatic = false
    var callback: (@MainActor (Result<ArticleImageInput, ArticleFailure>) -> Void)?
    var progress: (@MainActor (Double) -> Void)?
    func request(_ id: String, networkAllowed: Bool, completion: @escaping @MainActor (Result<ArticleImageInput, ArticleFailure>) -> Void) -> Int {
        flags.append(networkAllowed); callback = completion
        if automatic { completion(.success(ArticleImageInput(url: URL(fileURLWithPath: "/synthetic-unused-input"), orientation: 1))) }
        return flags.count
    }
    func request(_ id: String, networkAllowed: Bool, progress: @escaping @MainActor (Double) -> Void, completion: @escaping @MainActor (Result<ArticleImageInput, ArticleFailure>) -> Void) -> Int {
        self.progress = progress
        return request(id, networkAllowed: networkAllowed, completion: completion)
    }
    func emit(_ value: Double) { progress?(value) }
    func complete(_ value: Result<ArticleImageInput, ArticleFailure>) { callback?(value) }
    func cancel(_ request: Int) { cancelled.append(request) }
}
