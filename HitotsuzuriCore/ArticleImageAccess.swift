import Foundation
import Photos

@MainActor public protocol ArticleImageReading {
    func request(_ id: String, networkAllowed: Bool, completion: @escaping @MainActor (Result<ArticleImageInput, ArticleFailure>) -> Void) -> Int
    func cancel(_ request: Int)
}

@MainActor public final class PhotoKitArticleImageReader: ArticleImageReading {
    public init() {}
    public func request(_ id: String, networkAllowed: Bool, completion: @escaping @MainActor (Result<ArticleImageInput, ArticleFailure>) -> Void) -> Int {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject else { completion(.failure(.assetUnavailable)); return 0 }
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = false
        options.canHandleAdjustmentData = { _ in false }
        let token = Int(asset.requestContentEditingInput(with: options) { input, _ in
            Task { @MainActor in
                guard let input, let url = input.fullSizeImageURL else { completion(.failure(.assetUnavailable)); return }
                completion(.success(ArticleImageInput(url: url, orientation: UInt32(bitPattern: input.fullSizeImageOrientation), owner: input)))
            }
        })
        requests[token] = asset
        return token
    }
    // PhotoKit の取消には要求元 asset が必要なため、driver が保持する。
    private var requests: [Int: PHAsset] = [:]
    public func cancel(_ request: Int) { requests.removeValue(forKey: request)?.cancelContentEditingInputRequest(PHContentEditingInputRequestID(request)) }
}

@MainActor public final class ArticleImageAccess {
    private final class Job {
        let id: UUID, deadline: ContinuousClock.Instant
        var continuation: CheckedContinuation<ArticleJPEG, Error>?
        var token: Int?, timer: Task<Void, Never>?, converting = false, readerPending = true
        init(id: UUID, deadline: ContinuousClock.Instant, continuation: CheckedContinuation<ArticleJPEG, Error>) { self.id = id; self.deadline = deadline; self.continuation = continuation }
    }
    private let reader: any ArticleImageReading
    private let clock: any ImageClock
    private let budget = ArticleImageBudget()
    private var current: Job?
    public init(reader: any ArticleImageReading, clock: any ImageClock = ContinuousImageClock()) { self.reader = reader; self.clock = clock }
    public func image(_ assetID: String, requestID: UUID = UUID()) async throws -> ArticleJPEG {
        guard current == nil else { throw ArticleFailure.busy }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let job = Job(id: requestID, deadline: clock.now() + .seconds(30), continuation: continuation)
                current = job
                job.timer = Task { [weak self] in
                    guard let self else { return }
                    do { try await clock.sleep(until: job.deadline) } catch { return }
                    if current === job { finish(job, result: .failure(.timedOut)) }
                }
                job.token = reader.request(assetID, networkAllowed: false) { [weak self] result in self?.received(result, job: job) }
                if Task.isCancelled { finish(job, result: .failure(.cancelled)) }
            }
        } onCancel: { Task { @MainActor [weak self] in self?.cancel(requestID) } }
    }
    public func cancel(_ id: UUID) { if let job = current, job.id == id { finish(job, result: .failure(.cancelled)) } }
    private func received(_ result: Result<ArticleImageInput, ArticleFailure>, job: Job) {
        guard current === job, !job.converting else { return }
        job.readerPending = false
        guard job.continuation != nil else { current = nil; return }
        guard clock.now() < job.deadline else { finish(job, result: .failure(.timedOut)); return }
        switch result {
        case .failure(let error): finish(job, result: .failure(error))
        case .success(let input):
            job.converting = true
            let budget = budget
            Task { [weak self] in
                let result = await Task.detached { () -> Result<ArticleJPEG, ArticleFailure> in
                    do { return .success(try ArticleImageConverter.convert(input, budget: budget)) }
                    catch { return .failure(error as? ArticleFailure ?? .assetUnavailable) }
                }.value
                guard let self else { return }
                job.converting = false
                if current === job {
                    if clock.now() >= job.deadline { finish(job, result: .failure(.timedOut)) }
                    else { finish(job, result: result) }
                }
            }
        }
    }
    private func finish(_ job: Job, result: Result<ArticleJPEG, ArticleFailure>) {
        guard current === job else { return }
        if let continuation = job.continuation {
            job.continuation = nil; job.timer?.cancel(); job.timer = nil
            if let token = job.token { reader.cancel(token) }
            continuation.resume(with: result.mapError { $0 as Error })
        }
        // 論理終端後も同期デコーダが戻るまで次の実処理を開始しない。
        if !job.converting && !job.readerPending { current = nil }
    }
}
