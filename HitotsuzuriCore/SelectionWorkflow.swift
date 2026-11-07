import Foundation
import Observation

@MainActor @Observable public final class SelectionWorkflow {
    struct RandomAlbumDraw {
        let album:LibraryAlbum
        let requiresConfirmation:Bool
        fileprivate let revision:Int
        fileprivate let operationID:UUID?
    }

    public private(set) var authorization:AccessStatus = .notDetermined
    public private(set) var hierarchy=LibraryHierarchy(folders:[],albums:[])
    public private(set) var targetFolders=Set<String>()
    public private(set) var albums=[LibraryAlbum]()
    public private(set) var activeAlbum:LibraryAlbum?
    public private(set) var assets=[LibraryAsset]()
    public private(set) var selection=EditingSelection()
    public private(set) var images=[String:ImageBuffer]()
    public private(set) var imageFailures=[String:PickerFailure]()
    public private(set) var lastCommitted:CommittedSelection?
    public private(set) var restoreState:RestoreState = .notStarted
    public private(set) var settingsSaveState:SaveState = .idle
    public private(set) var selectionSaveState:SaveState = .idle
    public private(set) var settingsReadFailure:PickerFailure?
    public private(set) var isLoading=false
    public private(set) var isSaving=false
    public private(set) var error:PickerFailure?
    public private(set) var notice=""
    @ObservationIgnored private let library:any LibraryAccessing
    @ObservationIgnored private let imageAccess:any ImageAccessing
    @ObservationIgnored private let store:any SelectionStoring
    @ObservationIgnored private let clock:any ImageClock
    @ObservationIgnored private let validationTimeout:Duration
    @ObservationIgnored private var generation=0
    @ObservationIgnored private var revision=0
    @ObservationIgnored private var operationID:UUID?
    @ObservationIgnored private var settingsOperationID:UUID?
    @ObservationIgnored private var startup:Task<Void,Never>?
    @ObservationIgnored private var displayOperations=[String:UUID]()
    public init(library:any LibraryAccessing,images:any ImageAccessing,store:any SelectionStoring,clock:any ImageClock=ContinuousImageClock(),validationTimeout:Duration = .seconds(15)) {
        self.library=library; imageAccess=images; self.store=store; self.clock=clock; self.validationTimeout=validationTimeout
    }
    public var isEditingFrozen:Bool {restoreState.isBusy || isSaving}
    public var imageResources:ImageResourceSnapshot? {imageAccess.resources}
    public var canConfirm:Bool {authorization == .authorized && activeAlbum != nil && !isEditingFrozen && !isLoading && selection.orderedIDs.count==4 && selection.orderedIDs.allSatisfy {images[$0] != nil}}
    public var isDirty:Bool {lastCommitted?.albumID != activeAlbum?.id || lastCommitted?.orderedAssetIDs != selection.orderedIDs}
    var canDrawRandomAlbum:Bool {authorization == .authorized && !isEditingFrozen && !albums.isEmpty}

    func drawRandomAlbum(selectIndex:(Range<Int>)->Int = {Int.random(in:$0)})->RandomAlbumDraw? {
        guard canDrawRandomAlbum else {return nil}
        let index=selectIndex(albums.indices)
        guard albums.indices.contains(index) else {return nil}
        let album=albums[index]
        return RandomAlbumDraw(
            album:album,
            requiresConfirmation:album.id != activeAlbum?.id && !selection.orderedIDs.isEmpty && isDirty,
            revision:revision,
            operationID:operationID
        )
    }

    @discardableResult
    func applyRandomAlbum(_ draw:RandomAlbumDraw,afterConfirmation:Bool=false) async ->Bool {
        guard canDrawRandomAlbum,draw.revision==revision,draw.operationID==operationID,
              !draw.requiresConfirmation || afterConfirmation else {return false}
        await selectAlbum(draw.album)
        return activeAlbum?.id==draw.album.id
    }

    public func start() async {
        if let startup {await startup.value; return}
        guard restoreState == .notStarted else {return}
        let task=Task {await self.restore()}; startup=task; await task.value; startup=nil
    }
    private func restore() async {
        let op=UUID(); operationID=op; restoreState = .loading; isLoading=true; error=nil
        defer {isLoading=false}
        do {
            try requireAuthorization()
            // 独立読込。一方の失敗で他方の原本を変更しない。
            let savedSettings=await store.loadSettings(),savedSelection=await store.loadSelection()
            try requireOperation(op)
            let currentHierarchy=try await library.hierarchy()
            try requireOperation(op); hierarchy=currentHierarchy
            switch savedSettings {
            case .valid(let value):
                guard value.isValid else {throw PickerFailure.corruptData}
                targetFolders=Set(value.folderIDs).intersection(hierarchy.folders.map(\.id))
            case .missing: targetFolders=[]
            case .failure(let failure): settingsReadFailure=failure; targetFolders=[]
            }
            albums=library.albums(in:targetFolders,hierarchy:hierarchy)
            switch savedSelection {
            case .missing: restoreState = .missing
            case .failure(let failure): throw failure
            case .valid(let candidate):
                if let settingsReadFailure {throw settingsReadFailure}
                guard candidate.isValid,let album=albums.first(where:{$0.id==candidate.albumID}) else {throw PickerFailure.invalidReference}
                restoreState = .validating
                try await library.validate(folders:targetFolders,albumID:candidate.albumID,assets:candidate.orderedAssetIDs)
                try requireOperation(op)
                let currentAssets=try await library.assets(in:candidate.albumID)
                try requireOperation(op)
                guard Set(candidate.orderedAssetIDs).isSubset(of:Set(currentAssets.map(\.id))) else {throw PickerFailure.invalidReference}
                let validated=try await validateImages(candidate.orderedAssetIDs)
                try requireOperation(op)
                // 全候補の成功後に同期区間で一括公開。バッファは共有する。
                activeAlbum=album; assets=currentAssets; images=validated
                for id in candidate.orderedAssetIDs {selection.toggle(id,available:true)}
                lastCommitted=candidate; restoreState = .restored; notice="前回保存した4枚を復元しました。"
            }
        } catch {
            clearAlbum(); let failure=classify(error); setError(failure)
            restoreState = failure == .authorization ? .blocked : .failed(failure)
        }
    }
    public func requestAuthorization() async {
        guard authorization == .notDetermined,!isLoading else {return}
        isLoading=true; authorization=await library.requestAuthorization(); isLoading=false
        restoreState = .notStarted; await start()
    }
    public func setTargetFolders(_ ids:Set<String>) async {
        guard !isEditingFrozen else {return}
        targetFolders=ids.intersection(hierarchy.folders.map(\.id)); albums=library.albums(in:targetFolders,hierarchy:hierarchy); revision += 1
        if let album=activeAlbum,!albums.contains(where:{$0.id==album.id}) {clearAlbum()}
        let op=UUID(); settingsOperationID=op; settingsSaveState = .saving
        do {
            try await store.saveSettings(.init(folderIDs:Array(targetFolders)))
            if settingsOperationID==op {settingsSaveState = .saved; settingsReadFailure=nil}
        } catch {if settingsOperationID==op {let failure=classify(error); settingsSaveState = .failed(failure); Diagnostics.failure(failure)}}
    }
    public func selectAlbum(_ album:LibraryAlbum) async {
        guard !isEditingFrozen,album.id != activeAlbum?.id,albums.contains(where:{$0.id==album.id}) else {return}
        clearAlbum(); activeAlbum=album; let current=generation; isLoading=true; error=nil; notice=""; revision += 1
        do {
            try requireAuthorization(); let result=try await library.assets(in:album.id)
            guard current==generation else {return}
            try requireAuthorization(); assets=result; isLoading=false
        } catch {if current==generation {isLoading=false; setError(error)}}
    }
    public func loadImage(_ id:String) async {
        guard !isEditingFrozen,assets.contains(where:{$0.id==id}),images[id]==nil,imageFailures[id]==nil else {return}
        let current=generation
        let request=UUID(); displayOperations[id]=request
        do {let image=try await imageAccess.image(id,validation:false); guard current==generation,displayOperations[id]==request else {return}; images[id]=image}
        catch {if current==generation,displayOperations[id]==request,classify(error) != .cancelled {imageFailures[id]=classify(error)}}
    }
    public func toggle(_ id:String) {
        guard !isEditingFrozen,!isLoading,assets.contains(where:{$0.id==id}) else {return}
        if !selection.orderedIDs.contains(id),selection.orderedIDs.count==4 {
            notice="写真は4枚まで選べます。選択済みの写真を解除してから選んでください。"; return
        }
        selection.toggle(id,available:images[id] != nil); revision += 1; notice=""; error=nil; selectionSaveState = .idle
    }
    public func confirm() async {
        guard canConfirm,let album=activeAlbum else {return}
        let op=UUID(),current=generation,editRevision=revision,ids=selection.orderedIDs,folders=targetFolders
        operationID=op; isSaving=true; selectionSaveState = .saving; error=nil; notice="参照と画像を確認しています…"
        defer {isSaving=false}
        do {
            try requireOperation(op)
            try await library.validate(folders:folders,albumID:album.id,assets:ids)
            try requireOperation(op)
            let validated=try await validateImages(ids)
            try requireOperation(op)
            guard current==generation,editRevision==revision,ids==selection.orderedIDs else {throw PickerFailure.cancelled}
            let committed=CommittedSelection(albumID:album.id,albumTitle:album.title,orderedAssetIDs:ids)
            notice="保存しています…"; try await store.confirmSelection(committed)
            // 永続化の実成功は、その後の取消や認可変化から独立した事実。
            // ここでは固定内容と操作IDだけ照合し、Photosへ問い合わせない。
            guard operationID==op,current==generation,editRevision==revision,ids==selection.orderedIDs else {throw PickerFailure.cancelled}
            authorization=library.authorization
            images.merge(validated) {_,new in new}; lastCommitted=committed; selectionSaveState = .saved; notice="4枚を保存しました。"
        } catch {
            let failure=classify(error); setError(failure); selectionSaveState = .failed(failure); notice=""
            imageAccess.release(except:Set(images.keys))
        }
    }
    private func validateImages(_ ids:[String]) async throws ->[String:ImageBuffer] {
        let access=imageAccess,clock=clock,deadline=clock.now().advanced(by:validationTimeout)
        let result=try await withThrowingTaskGroup(of:(String,ImageBuffer).self) { group in
            for id in ids {group.addTask {(id,try await access.image(id,validation:true,deadline:deadline))}}
            group.addTask {try await clock.sleep(until:deadline); throw PickerFailure.timedOut}
            var buffers=[String:ImageBuffer]()
            defer {group.cancelAll()}
            for try await (id,image) in group {buffers[id]=image; if buffers.count==4 {break}}
            return buffers
        }
        guard clock.now()<deadline,result.count==4 else {throw PickerFailure.timedOut}; return result
    }
    public func updateVisibleImages(_ visible:Set<String>) {
        guard !isEditingFrozen else {return}
        let needed=visible.union(selection.orderedIDs); images=images.filter {needed.contains($0.key)}; imageAccess.release(except:needed)
        displayOperations=displayOperations.filter {needed.contains($0.key)}
    }
    private func clearAlbum() {
        generation += 1; imageAccess.cancelDisplayRequests(); imageAccess.release(except:[])
        displayOperations=[:]
        activeAlbum=nil; assets=[]; images=[:]; imageFailures=[:]; selection.clear(); isLoading=false; notice=""
    }
    private func requireAuthorization() throws {
        authorization=library.authorization
        guard authorization == .authorized else {throw PickerFailure.authorization}
    }
    private func requireOperation(_ op:UUID) throws {
        try Task.checkCancellation()
        guard operationID==op else {throw PickerFailure.cancelled}
        try requireAuthorization()
    }
    private func classify(_ error:any Error)->PickerFailure {error is CancellationError ? .cancelled : (error as? PickerFailure) ?? .ioFailure}
    private func setError(_ error:any Error) {self.error=classify(error); Diagnostics.failure(self.error ?? .ioFailure)}
}

