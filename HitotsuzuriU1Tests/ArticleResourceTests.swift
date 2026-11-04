import XCTest
@testable import HitotsuzuriCore

@MainActor final class ArticleResourceTests: XCTestCase {
    func testNetworkIsAlwaysFalseAndImageSucceeds() async throws {
        let driver = ArticleReaderFake(), access = ArticleImageAccess(reader: driver)
        let input = try ArticleImageFixture.make(width: 30, height: 20)
        driver.input = input
        let result = try await access.image("a")
        XCTAssertEqual(result.width, 30); XCTAssertEqual(driver.networkFlags, [false])
    }
    func testDeadlineWithoutResponseFinishes() async throws {
        let driver = ArticleReaderFake(), clock = ArticleClockFake()
        let access = ArticleImageAccess(reader: driver, clock: clock)
        let task = Task { try await access.image("a") }
        while driver.networkFlags.isEmpty { await Task.yield() }
        clock.advance(30)
        do { _ = try await task.value; XCTFail() } catch { XCTAssertEqual(error as? ArticleFailure, .timedOut) }
    }
    func testCompletionAtDeadlineDoesNotWinTimerRace() async throws {
        let driver = ArticleReaderFake(), clock = ArticleClockFake()
        let access = ArticleImageAccess(reader: driver, clock: clock)
        let task = Task { try await access.image("a") }
        while driver.networkFlags.isEmpty { await Task.yield() }
        clock.moveWithoutWaking(30)
        driver.complete(.success(try ArticleImageFixture.make(width: 30, height: 20)))
        do { _ = try await task.value; XCTFail() } catch { XCTAssertEqual(error as? ArticleFailure, .timedOut) }
    }
    func testCancelIsSingleTerminalAndLateResponseIgnored() async throws {
        let driver = ArticleReaderFake(), access = ArticleImageAccess(reader: driver), id = UUID()
        let task = Task { try await access.image("a", requestID: id) }
        while driver.networkFlags.isEmpty { await Task.yield() }
        access.cancel(id)
        driver.complete(.failure(.assetUnavailable))
        do { _ = try await task.value; XCTFail() } catch { XCTAssertEqual(error as? ArticleFailure, .cancelled) }
        XCTAssertEqual(driver.cancellations, 1)
    }
    func testBudgetRefusesOverReservation() throws {
        let input = try ArticleImageFixture.make(width: 30, height: 20)
        XCTAssertThrowsError(try ArticleImageConverter.convert(input, budget: ArticleImageBudget(limit: 1)))
    }
    func testConcurrentRequestIsRejected() async throws {
        let driver = ArticleReaderFake(), access = ArticleImageAccess(reader: driver), id = UUID()
        let first = Task { try await access.image("a", requestID: id) }
        while driver.networkFlags.isEmpty { await Task.yield() }
        do { _ = try await access.image("b"); XCTFail() } catch { XCTAssertEqual(error as? ArticleFailure, .busy) }
        access.cancel(id); _ = try? await first.value
    }
}

@MainActor final class ArticleReaderFake: ArticleImageReading {
    var input: ArticleImageInput?
    var networkFlags: [Bool] = []
    var cancellations = 0
    var callback: (@MainActor (Result<ArticleImageInput, ArticleFailure>) -> Void)?
    func request(_ id: String, networkAllowed: Bool, completion: @escaping @MainActor (Result<ArticleImageInput, ArticleFailure>) -> Void) -> Int {
        networkFlags.append(networkAllowed); callback = completion
        if let input { completion(.success(input)) }
        return networkFlags.count
    }
    func cancel(_ request: Int) { cancellations += 1 }
    func complete(_ result: Result<ArticleImageInput, ArticleFailure>) { callback?(result) }
}
@MainActor final class ArticleClockFake: ImageClock {
    var time = ContinuousClock().now
    var sleepers: [(ContinuousClock.Instant, CheckedContinuation<Void, Error>)] = []
    func now() -> ContinuousClock.Instant { time }
    func sleep(until deadline: ContinuousClock.Instant) async throws {
        if time >= deadline { return }
        try await withCheckedThrowingContinuation { sleepers.append((deadline, $0)) }
    }
    func moveWithoutWaking(_ seconds: Int) { time += .seconds(seconds) }
    func advance(_ seconds: Int) {
        time += .seconds(seconds)
        let ready = sleepers.filter { $0.0 <= time }; sleepers.removeAll { $0.0 <= time }
        for (_, c) in ready { c.resume() }
    }
}
