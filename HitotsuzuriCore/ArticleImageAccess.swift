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
    private let convert:@Sendable (ArticleImageInput,ArticleImageBudget) throws ->ArticleJPEG
    private var current: Job?
    private let diagnostics:ArticleDiagnostics
    public init(reader: any ArticleImageReading, clock: any ImageClock = ContinuousImageClock(),convert:@escaping @Sendable (ArticleImageInput,ArticleImageBudget) throws ->ArticleJPEG = {try ArticleImageConverter.convert($0,budget:$1)},diagnostics:ArticleDiagnostics = .live) { self.reader = reader; self.clock = clock; self.convert=convert; self.diagnostics=diagnostics }
    public var isBusy:Bool {current != nil}
    public var reservedImageBytes:Int {budget.reservedBytes}
    public var peakReservedImageBytes:Int {budget.peakReservedBytes}
    public func image(_ assetID: String, requestID: UUID = UUID()) async throws -> ArticleJPEG {
        guard current == nil else { throw ArticleFailure.busy }
        diagnostics.record(.imageRequested)
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
                    if clock.now() >= job.deadline { finish(job, result: .failure(.timedOut)) }
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
