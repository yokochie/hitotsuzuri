import Foundation
import AppKit
import Photos

@MainActor public final class LocalImageAccess: ImageAccessing {
    private struct Pending {
        let assetID: String
        let validation: Bool
        let continuation: CheckedContinuation<ImageBuffer,any Error>
        let deadline: ContinuousClock.Instant
        var driverID: Int?
        var timeoutTask: Task<Void,Never>?
    }
    private let driver: any ImageDriving
    private let timeout: Duration
    private let clock: any ImageClock
    private let budget: Int
    private let reservation=2*1024*1024
    private var pending: [UUID:Pending]=[:]
    private var queue=[UUID]()
    private var cache=[String:ImageBuffer]()
    private var lru=[String]()
    private final class WeakStorage {
        weak var value: ImageStorage?
        init(_ value: ImageStorage) { self.value=value }
    }
    private var liveBuffers=[ObjectIdentifier:WeakStorage]()
    private var isDraining=false
    private var necessaryIDs:Set<String>?
    public var retainedBytes: Int {
        liveBuffers=liveBuffers.filter {$0.value.value != nil}
        return liveBuffers.values.reduce(0) { $0+($1.value?.pixels.count ?? 0) }
    }
    public var activeCount: Int { pending.values.filter {$0.driverID != nil}.count }
    public var reservedBytes: Int { activeCount*reservation }
    public init(driver: any ImageDriving, timeout: Duration = .seconds(15), budget: Int = 256*1024*1024, clock: any ImageClock = ContinuousImageClock()) {
        self.driver=driver; self.timeout=timeout; self.budget=budget; self.clock=clock
    }
    public convenience init() { self.init(driver:SystemImageDriver()) }
    public func image(_ assetID: String, validation: Bool = false, deadline: ContinuousClock.Instant? = nil) async throws -> ImageBuffer {
        let now=clock.now()
        let localDeadline=now.advanced(by:timeout)
        let limit=min(localDeadline,deadline ?? localDeadline)
        guard now<limit else { throw PickerFailure.timedOut }
        guard !Task.isCancelled else { throw PickerFailure.cancelled }
        if !validation, let image=cache[assetID] { touch(assetID); return image }
        let id=UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending[id]=Pending(assetID:assetID,validation:validation,continuation:continuation,deadline:limit)
                if validation { queue.insert(id,at:0) } else { queue.append(id) }
                pending[id]?.timeoutTask=Task { [weak self, clock] in
                    do { try await clock.sleep(until:limit) } catch { return }
                    self?.finish(id,outcome:.failure(.timedOut))
                }
                drain()
            }
        } onCancel: { Task { @MainActor [weak self] in self?.finish(id,outcome:.cancelled) } }
    }
    public func cancelDisplayRequests() {
        let wasDraining=isDraining; isDraining=true
        for id in Array(pending.keys) where pending[id]?.validation==false { finish(id,outcome:.cancelled) }
        isDraining=wasDraining; drain()
    }
    public func release(except ids: Set<String>) {
        necessaryIDs=ids
        // 取消途中にdrainして不要キューを開始しない。
        let wasDraining=isDraining; isDraining=true
        for id in Array(pending.keys) {
            if let request=pending[id],!request.validation,!ids.contains(request.assetID) {finish(id,outcome:.cancelled)}
        }
        cache=cache.filter {ids.contains($0.key)}; lru.removeAll {!ids.contains($0)}
        isDraining=wasDraining; drain()
    }
    public var resourceSnapshot:ImageResourceSnapshot {
        .init(active:activeCount,queued:pending.values.filter {$0.driverID==nil}.count,retainedBuffers:liveBuffers.values.filter {$0.value != nil}.count,retainedBytes:retainedBytes,reservedBytes:reservedBytes,unnecessaryDisplay:pending.values.filter {!$0.validation && !(necessaryIDs?.contains($0.assetID) ?? true)}.count,necessaryCount:necessaryIDs?.count ?? 0)
    }
    public var resources:ImageResourceSnapshot? {resourceSnapshot}
    private func touch(_ id: String) { lru.removeAll {$0==id}; lru.append(id) }
    private func drain() {
        guard !isDraining else { return }
        isDraining=true; defer { isDraining=false }
        for id in queue {
            guard var request=pending[id], request.driverID==nil else { continue }
            guard clock.now()<request.deadline else { finish(id,outcome:.failure(.timedOut)); continue }
            let normal=pending.values.filter {$0.driverID != nil && !$0.validation}.count
            let validating=pending.values.contains {$0.validation}
            let activeValidation=pending.values.filter {$0.driverID != nil && $0.validation}.count
            guard activeCount<8, request.validation ? activeValidation<4 : (normal<4 && !validating) else { continue }
            while retainedBytes+reservedBytes+reservation>budget, let evict=lru.first { cache[evict]=nil; lru.removeFirst() }
            guard retainedBytes+reservedBytes+reservation<=budget else { continue }
            // 同期コールバックに備え、開始中もslotを予約する。
            request.driverID = -1; pending[id]=request
            let driverID=driver.request(request.assetID) { [weak self] result in self?.finish(id,outcome:result) }
            if pending[id] != nil { pending[id]?.driverID=driverID }
        }
    }
    private func finish(_ id: UUID, outcome: ImageOutcome) {
        guard let request=pending[id] else { return }
        let accepted=clock.now()<request.deadline ? outcome : .failure(.timedOut)
        if case .image(_,let final)=accepted, !final { return }
        pending[id]=nil; queue.removeAll {$0==id}; request.timeoutTask?.cancel()
        switch accepted {
        case .image(let buffer,_):
            guard buffer.byteCount<=reservation else { request.continuation.resume(throwing:PickerFailure.capacity); drain(); return }
            liveBuffers[ObjectIdentifier(buffer.storage)]=WeakStorage(buffer.storage)
            cache[request.assetID]=buffer; touch(request.assetID); request.continuation.resume(returning:buffer)
        case .unavailable: request.continuation.resume(throwing:PickerFailure.unavailable)
        case .cancelled: if let n=request.driverID { driver.cancel(n) }; request.continuation.resume(throwing:PickerFailure.cancelled)
        case .failure(let f): if let n=request.driverID { driver.cancel(n) }; request.continuation.resume(throwing:f)
        }
        drain()
    }
}

@MainActor final class SystemImageDriver: ImageDriving {
    private let manager=PHImageManager()
    func request(_ assetID: String, completion: @escaping @MainActor (ImageOutcome)->Void) -> Int {
        guard PHPhotoLibrary.authorizationStatus(for:.readWrite) == .authorized else { completion(.failure(.authorization)); return -1 }
        guard let asset=PHAsset.fetchAssets(withLocalIdentifiers:[assetID],options:nil).firstObject else { completion(.failure(.invalidReference)); return -1 }
        let options=Self.requestOptions()
        let request=manager.requestImage(for:asset,targetSize:CGSize(width:512,height:512),contentMode:.aspectFit,options:options) { image,info in
            let result: ImageOutcome
            if (info?[PHImageCancelledKey] as? Bool)==true { result = .cancelled }
            else if info?[PHImageErrorKey] != nil { result = .failure(.unavailable) }
            else if let image, let buffer=Self.decode(image) { result = .image(buffer,final:(info?[PHImageResultIsDegradedKey] as? Bool) != true) }
            else { result = .unavailable }
            Task { @MainActor in completion(result) }
        }
        return Int(request)
    }
    func cancel(_ requestID: Int) { if requestID>=0 { manager.cancelImageRequest(PHImageRequestID(requestID)) } }
    static func requestOptions() -> PHImageRequestOptions {
        let options=PHImageRequestOptions(); options.isNetworkAccessAllowed=false
        options.deliveryMode = .highQualityFormat; options.resizeMode = .exact
        return options
    }
    nonisolated static func decode(_ image: NSImage) -> ImageBuffer? {
        guard let source=image.cgImage(forProposedRect:nil,context:nil,hints:nil) else { return nil }
        let scale=min(1,512/Double(max(source.width,source.height)))
        let width=max(1,Int(Double(source.width)*scale)), height=max(1,Int(Double(source.height)*scale)), row=width*4
        var data=Data(count:row*height)
        let valid=data.withUnsafeMutableBytes { bytes -> Bool in
            guard let context=CGContext(data:bytes.baseAddress,width:width,height:height,bitsPerComponent:8,bytesPerRow:row,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(source,in:CGRect(x:0,y:0,width:width,height:height)); return true
        }
        return valid ? ImageBuffer(pixels:data,width:width,height:height,bytesPerRow:row) : nil
    }
}


