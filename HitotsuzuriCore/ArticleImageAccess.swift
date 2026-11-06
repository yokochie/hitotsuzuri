import Foundation
import Photos
import Observation

public enum ArticlePhotoPreviewState:Sendable {
    case waiting,loading,ready(ImageBuffer),failed(ArticleFailure)
    public var message:String {
        switch self {
        case .waiting:"画像の取得待ち"
        case .loading:"画像を取得中…"
        case .ready:"画像を取得しました"
        case .failed(let error):error.message
        }
    }
}

/// 表示用512px経路。記事正本・本文入力・出力用JPEGとは独立して取得する。
@MainActor @Observable public final class ArticlePhotoPreviews {
    public private(set) var states:[String:ArticlePhotoPreviewState]
    public private(set) var isLoading=false
    private let assetIDs:[String]
    private let images:any ImageAccessing
    private let clock:any ImageClock
    private var generation=UUID()
    public init(assetIDs:[String],images:any ImageAccessing,clock:any ImageClock = ContinuousImageClock()) {
        self.assetIDs=assetIDs; self.images=images; self.clock=clock
        states=Dictionary(uniqueKeysWithValues:assetIDs.map {($0,.waiting)})
    }
    public func load() async {
        guard !isLoading else {return}
        isLoading=true; let current=generation, deadline=clock.now() + .seconds(15)
        defer {if generation == current {isLoading=false}}
        images.release(except:Set(assetIDs))
        for id in assetIDs {
            guard generation == current, !Task.isCancelled else {return}
            await request(id,generation:current,deadline:deadline)
        }
    }
    private func request(_ id:String,generation current:UUID,deadline:ContinuousClock.Instant) async {
            guard clock.now() < deadline else {states[id] = .failed(.timedOut); return}
            states[id] = .loading
            do {
                let image=try await images.image(id,validation:false,deadline:deadline)
                guard generation == current, !Task.isCancelled else {return}
                guard clock.now() < deadline else { states[id] = .failed(.timedOut); return }
                guard image.byteCount <= 256*1024*1024 else { states[id] = .failed(.capacity); return }
                states[id] = .ready(image)
            } catch {
                guard generation == current, !Task.isCancelled else {return}
                let failure:ArticleFailure
                switch error as? PickerFailure {
                case .authorization:failure = .permissionDenied
                case .invalidReference:failure = .invalidReference
                case .timedOut:failure = .timedOut
                case .cancelled:failure = .cancelled
                case .capacity,.oversizedData:failure = .capacity
                default:failure = .assetUnavailable
                }
                states[id] = .failed(failure)
            }
    }
    public func cancel() {generation=UUID(); isLoading=false; images.cancelDisplayRequests(); images.release(except:[]); states=[:]}
    public func retry(_ assetID: String) async {
        guard assetIDs.contains(assetID), !isLoading, !states.isEmpty else { return }
        isLoading=true; let current=generation
        defer { if current == generation { isLoading=false } }
        await request(assetID,generation:current,deadline:clock.now() + .seconds(15))
    }
}

@MainActor public protocol ArticleImageReading {
    func request(_ id: String, networkAllowed: Bool, completion: @escaping @MainActor (Result<ArticleImageInput, ArticleFailure>) -> Void) -> Int
    func request(_ id: String, networkAllowed: Bool, progress: @escaping @MainActor (Double) -> Void, completion: @escaping @MainActor (Result<ArticleImageInput, ArticleFailure>) -> Void) -> Int
    func cancel(_ request: Int)
}
extension ArticleImageReading {
    public func request(_ id: String, networkAllowed: Bool, progress: @escaping @MainActor (Double) -> Void, completion: @escaping @MainActor (Result<ArticleImageInput, ArticleFailure>) -> Void) -> Int {
        request(id, networkAllowed: networkAllowed, completion: completion)
    }
}

@MainActor public final class PhotoKitArticleImageReader: ArticleImageReading {
    typealias RequestInput = @MainActor (String, PHContentEditingInputRequestOptions, @escaping @MainActor (Result<ArticleImageInput, ArticleFailure>) -> Void) -> Int
    private final class Cancellation: @unchecked Sendable {
        private let lock = NSLock()
        private var value = false
        var isCancelled: Bool { lock.withLock { value } }
        func cancel() { lock.withLock { value = true } }
    }
    private final class Request {
        let cancellation = Cancellation()
        let progress: @MainActor (Double) -> Void
        let completion: @MainActor (Result<ArticleImageInput, ArticleFailure>) -> Void
        var cancelInput: (() -> Void)?
        init(progress: @escaping @MainActor (Double) -> Void, completion: @escaping @MainActor (Result<ArticleImageInput, ArticleFailure>) -> Void) {
            self.progress = progress; self.completion = completion
        }
    }
    private let requestInput: RequestInput?
    private let cancelInput: ((Int) -> Void)?
    private var requests: [Int: Request] = [:]
    private var nextRequest = 0
    public init() { requestInput = nil; cancelInput = nil }
    // optionsを含む実adapter境界を、写真ライブラリへ触れずに観測する。
    init(requestInput: @escaping RequestInput, cancelInput: @escaping (Int) -> Void = { _ in }) {
        self.requestInput = requestInput; self.cancelInput = cancelInput
    }
    public func request(_ id: String, networkAllowed: Bool, completion: @escaping @MainActor (Result<ArticleImageInput, ArticleFailure>) -> Void) -> Int {
        request(id, networkAllowed: networkAllowed, progress: { _ in }, completion: completion)
    }
    public func request(_ id: String, networkAllowed: Bool, progress: @escaping @MainActor (Double) -> Void, completion: @escaping @MainActor (Result<ArticleImageInput, ArticleFailure>) -> Void) -> Int {
        nextRequest += 1
        let ticket = nextRequest, request = Request(progress: progress, completion: completion)
        requests[ticket] = request
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = networkAllowed
        options.canHandleAdjustmentData = { _ in false }
        let cancellation = request.cancellation
        options.progressHandler = { [weak self] fraction, stop in
            if cancellation.isCancelled { stop.pointee = true; return }
            Task { @MainActor in self?.receivedProgress(fraction, ticket: ticket) }
        }
        if let requestInput {
            let token = requestInput(id, options) { [weak self] result in self?.complete(ticket, result: result) }
            request.cancelInput = { [cancelInput] in cancelInput?(token) }
        } else if let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject {
            let token = asset.requestContentEditingInput(with: options) { [weak self] input, info in
                let result = Self.inputResult(input, info: info)
                Task { @MainActor in self?.complete(ticket, result: result) }
            }
            request.cancelInput = { asset.cancelContentEditingInputRequest(token) }
        } else {
            complete(ticket, result: .failure(.invalidReference))
        }
        // 同期callback/要求ID確定前の取消も取り落とさない。
        if request.cancellation.isCancelled { request.cancelInput?() }
        return ticket
    }
    private func receivedProgress(_ value: Double, ticket: Int) {
        guard let request = requests[ticket], !request.cancellation.isCancelled else { return }
        request.progress(value)
    }
    private func complete(_ ticket: Int, result: Result<ArticleImageInput, ArticleFailure>) {
        guard let request = requests.removeValue(forKey: ticket) else { return }
        request.completion(request.cancellation.isCancelled ? .failure(.cancelled) : result)
    }
    nonisolated static func inputResult(_ input: PHContentEditingInput?, info: [AnyHashable: Any]) -> Result<ArticleImageInput, ArticleFailure> {
        if (info[PHContentEditingInputCancelledKey] as? NSNumber)?.boolValue == true { return .failure(.cancelled) }
        if let error = info[PHContentEditingInputErrorKey] as? NSError {
            if error.domain == NSURLErrorDomain { return .failure(.networkUnavailable) }
            return .failure(.assetUnavailable)
        }
        guard let input, let url = input.fullSizeImageURL else { return .failure(.assetUnavailable) }
        return .success(ArticleImageInput(url: url, orientation: UInt32(bitPattern: input.fullSizeImageOrientation), owner: input))
    }
    public func cancel(_ ticket: Int) {
        guard let request = requests[ticket], !request.cancellation.isCancelled else { return }
        request.cancellation.cancel(); request.cancelInput?()
    }
}

@MainActor public final class ArticleImageAccess {
    private final class Job {
        let id: UUID, started: ContinuousClock.Instant, networkAllowed: Bool
        var deadline: ContinuousClock.Instant?
        var fraction: Double?
        let progress: @MainActor (Double) -> Void
        var continuation: CheckedContinuation<ArticleJPEG, Error>?
        var token: Int?, timer: Task<Void, Never>?, converting = false, readerPending = true
        init(id: UUID, started: ContinuousClock.Instant, networkAllowed: Bool, progress: @escaping @MainActor (Double) -> Void, continuation: CheckedContinuation<ArticleJPEG, Error>) {
            self.id = id; self.started = started; self.networkAllowed = networkAllowed
            self.progress = progress; self.continuation = continuation
        }
    }
    private let reader: any ArticleImageReading
    private let clock: any ImageClock
    private let budget = ArticleImageBudget()
    private let convert:@Sendable (ArticleImageInput,ArticleImageBudget) throws ->ArticleJPEG
    private var current: Job?
    private let diagnostics:ArticleDiagnostics
    public init(reader: any ArticleImageReading, clock: any ImageClock = ContinuousImageClock(),convert:@escaping @Sendable (ArticleImageInput,ArticleImageBudget) throws ->ArticleJPEG = {try ArticleImageConverter.convert($0,budget:$1)},diagnostics:ArticleDiagnostics = .live) { self.reader = reader; self.clock = clock; self.convert=convert; self.diagnostics=diagnostics }
    public var isBusy:Bool {current != nil}
    public var reservedImageBytes:Int {budget.reservedBytes}
    public var peakReservedImageBytes:Int {budget.peakReservedBytes}
    public private(set) var lastAcquisitionDuration: Duration = .zero
    public func image(_ assetID: String, requestID: UUID = UUID(), networkAllowed: Bool, progress: @escaping @MainActor (Double) -> Void = { _ in }) async throws -> ArticleJPEG {
        guard current == nil else { throw ArticleFailure.busy }
        lastAcquisitionDuration = .zero
        diagnostics.record(.imageRequested)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let job = Job(id: requestID, started: clock.now(), networkAllowed: networkAllowed, progress: progress, continuation: continuation)
                current = job
                if !networkAllowed { startTimer(job, deadline: job.started + .seconds(30)) }
                job.token = reader.request(assetID, networkAllowed: networkAllowed, progress: { [weak self] value in
                    self?.receivedProgress(value, job: job)
                }) { [weak self] result in self?.received(result, job: job) }
                if job.continuation == nil, job.readerPending, let token = job.token {
                    reader.cancel(token)
                }
                if Task.isCancelled { finish(job, result: .failure(.cancelled)) }
            }
        } onCancel: { Task { @MainActor [weak self] in self?.cancel(requestID) } }
    }
    public func image(_ assetID: String, requestID: UUID = UUID()) async throws -> ArticleJPEG {
        try await image(assetID, requestID: requestID, networkAllowed: false)
    }
    private func startTimer(_ job: Job, deadline: ContinuousClock.Instant) {
        job.timer?.cancel(); job.deadline = deadline
        job.timer = Task { [weak self] in
            guard let self else { return }
            do { try await clock.sleep(until: deadline) } catch { return }
            guard current === job, job.deadline == deadline, !Task.isCancelled else { return }
            finish(job, result: .failure(.timedOut))
        }
    }
    private func receivedProgress(_ value: Double, job: Job) {
        guard current === job, job.readerPending, job.continuation != nil,
              value.isFinite, (0...1).contains(value), value >= (job.fraction ?? 0) else { return }
        job.fraction = value; job.progress(value)
    }
    public func cancel(_ id: UUID) { if let job = current, job.id == id { finish(job, result: .failure(.cancelled)) } }
    private func received(_ result: Result<ArticleImageInput, ArticleFailure>, job: Job) {
        guard current === job, !job.converting else { return }
        job.readerPending = false
        guard job.continuation != nil else { current = nil; return }
        if let deadline = job.deadline, clock.now() >= deadline { finish(job, result: .failure(.timedOut)); return }
        if job.networkAllowed { lastAcquisitionDuration = max(.zero, job.started.duration(to: clock.now())) }
        switch result {
        case .failure(let error): finish(job, result: .failure(error))
        case .success(let input):
            if job.networkAllowed { startTimer(job, deadline: clock.now() + .seconds(30)) }
            diagnostics.record(.imageConverting)
            job.converting = true
            let budget = budget
            let convert=convert
            Task { [weak self] in
                let result = await Task.detached { () -> Result<ArticleJPEG, ArticleFailure> in
                    do { return .success(try convert(input,budget)) }
                    catch { return .failure(error as? ArticleFailure ?? .assetUnavailable) }
                }.value
                guard let self else { return }
                job.converting = false
                if current === job {
                    if let deadline = job.deadline, clock.now() >= deadline { finish(job, result: .failure(.timedOut)) }
                    else { finish(job, result: result) }
                }
            }
        }
    }
    private func finish(_ job: Job, result: Result<ArticleJPEG, ArticleFailure>) {
        guard current === job else { return }
        if let continuation = job.continuation {
            switch result {
            case .success: diagnostics.record(.imageSucceeded)
            case .failure(let error): diagnostics.record(.failed,failure:error)
            }
            job.continuation = nil; job.timer?.cancel(); job.timer = nil
            if let token = job.token { reader.cancel(token) }
            continuation.resume(with: result.mapError { $0 as Error })
        }
        // 論理終端後も同期デコーダが戻るまで次の実処理を開始しない。
        if !job.converting && !job.readerPending { current = nil }
    }
}
