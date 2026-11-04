import SwiftUI
import AppKit

private enum PickerFocus:Hashable {case folder(String),albums,photo(String),regionSwitch,confirm}
public struct PickerContent:View {
    @Bindable private var workflow:SelectionWorkflow
    @State private var presentation:PickerPresentationState
    @State private var visible=Set<String>()
    @State private var measurement:NativeMeasurement
    @State private var measuredResources:ImageResourceSnapshot?
    @State private var folderFocusRequest=0
    @State private var lastInteractionRegion:PickerRegion?
    @State private var compactLayout=false
    @State private var focusTransfer=0
    @FocusState private var focus:PickerFocus?
    private let onArticle: (() -> Void)?
    private let canOpenArticle:Bool?
    public init(workflow:SelectionWorkflow,presentation:PickerPresentationState=PickerPresentationState(),measurement:NativeMeasurement=NativeMeasurement(),onArticle:(() -> Void)?=nil,canOpenArticle:Bool?=nil) {self.workflow=workflow; _presentation=State(initialValue:presentation); _measurement=State(initialValue:measurement); self.onArticle=onArticle; self.canOpenArticle=canOpenArticle}
    public var body:some View {
        GeometryReader { proxy in
            let compact=PickerPresentationState.isCompact(proxy.size.width)
            VStack(spacing:0) {
                HStack {Text("ひとつづり").font(.title2.bold()); Spacer(); Text("写真4枚をひとつづりに").foregroundStyle(.secondary)}.padding()
                Divider()
                if measurement.enabled {measurementView}
                if workflow.authorization == .authorized {
                    if compact {
                        Picker("表示領域",selection:$presentation.region) {ForEach(PickerRegion.allCases,id:\.self) {Text($0.rawValue).tag($0)}}.pickerStyle(.segmented).padding(8).focusable().focused($focus,equals:.regionSwitch).accessibilityIdentifier("region-picker")
                            .onKeyPress(keys:[.leftArrow,.rightArrow]) {press in
                                let regions=PickerRegion.allCases
                                guard let index=regions.firstIndex(of:presentation.region) else {return .ignored}
                                let next=max(0,min(regions.count-1,index+(press.key == .leftArrow ? -1 : 1)))
                                presentation.region=regions[next]; return .handled
                            }
                        region(presentation.region)
                    } else {
                        HSplitView {folderList.frame(minWidth:170,idealWidth:220); albumList.frame(minWidth:160,idealWidth:200); photoGrid.frame(minWidth:280)}
                    }
                } else {permission}
                Divider(); tray
            }
            .onChange(of:presentation.region) {_,value in restoreFocus(value)}
            .onChange(of:compact,initial:true) {_,value in
                compactLayout=value
                if let region=lastInteractionRegion {presentation.region=region; restoreFocus(region); return}
                let region:PickerRegion?
                switch focus {case .folder:region = .folders; case .albums:region = .albums; case .photo:region = .photos; default:region=nil}
                if let region {presentation.region=region; restoreFocus(region)}
            }
            .onChange(of:focus) {_,value in
                switch value {case .folder(let id):presentation.remember(id,in:.folders); lastInteractionRegion = .folders; case .albums:lastInteractionRegion = .albums; _=selectFirstAlbumForTabEntry(); case .photo(let id):presentation.remember(id,in:.photos); lastInteractionRegion = .photos; default:break}
            }
            .onChange(of:workflow.activeAlbum?.id) {_,id in
                if let id {presentation.remember(id,in:.albums)}
            }
        }.frame(minWidth:640,minHeight:560)
    }
    @ViewBuilder private func region(_ value:PickerRegion)->some View {
        switch value {case .folders:folderList; case .albums:albumList; case .photos:photoGrid}
    }
    private func heading(_ region:PickerRegion)->some View {
        Text(region.rawValue).font(.headline).padding(.horizontal).accessibilityAddTraits(.isHeader)
    }
    private var permission:some View {
        VStack(spacing:16) {
            Image(systemName:"photo.on.rectangle.angled").font(.system(size:48))
            Text("写真ライブラリから4枚を選びます").font(.title2)
            Text("写真・アルバムは変更しません。画像の取得のために通信しません。").foregroundStyle(.secondary)
            Text(PresentationSnapshot(workflow).statusText).multilineTextAlignment(.center)
            if workflow.authorization == .notDetermined {
                Button("写真へのアクセスを許可") {Task {await workflow.requestAuthorization()}}.buttonStyle(.borderedProminent).disabled(workflow.isLoading).accessibilityIdentifier("permission-allow")
            }
        }.padding().frame(maxWidth:.infinity,maxHeight:.infinity)
    }
    private var folderList:some View {
        VStack(alignment:.leading) {
            heading(.folders)
            NativeFolderBrowser(folders:workflow.hierarchy.folders,selection:workflow.targetFolders,expanded:$presentation.expanded,frozen:workflow.isEditingFrozen,focusRequest:folderFocusRequest,focusID:presentation.focus[.folders],onSelection:{ids in Task {await workflow.setTargetFolders(ids)}},onFocus:{id in presentation.remember(id,in:.folders); lastInteractionRegion = .folders})
            Text("Commandキーで複数選択。左右キーで展開。").font(.caption).padding(.horizontal)
        }.disabled(workflow.isEditingFrozen)
    }
    private var albumList:some View {
        VStack(alignment:.leading) {
            heading(.albums)
            List(selection:Binding(get:{workflow.activeAlbum?.id},set:{id in if let album=workflow.albums.first(where:{$0.id==id}) {Task {await workflow.selectAlbum(album)}}})) {
                ForEach(workflow.albums) {album in Text(name(album.title)).lineLimit(1).help(name(album.title)).accessibilityLabel(name(album.title))
                    .tag(album.id)}
            }.focused($focus,equals:.albums)
                .onKeyPress(keys:[.tab,KeyEquivalent("\u{19}")]) {press in
                    if selectFirstAlbumForTabEntry() {return .handled}
                    let backwards=press.modifiers.contains(.shift) || press.key==KeyEquivalent("\u{19}")
                    if compactLayout,workflow.canConfirm,!backwards {focusConfirmation(); return .handled}
                    let next:PickerRegion=backwards ? .folders : .photos
                    presentation.region=next; restoreFocus(next); return .handled
                }
                .accessibilityLabel("アルバム").accessibilityIdentifier("album-list")
        }.disabled(workflow.isEditingFrozen)
    }
    private var photoGrid:some View {
        VStack(alignment:.leading) {
            heading(.photos)
            GeometryReader {proxy in
                let columns=max(1,Int((proxy.size.width-20)/152))
                ScrollViewReader {scroll in
                    ScrollView {
                        LazyVGrid(columns:[GridItem(.adaptive(minimum:140),spacing:12)],spacing:12) {
                            ForEach(Array(workflow.assets.enumerated()),id:\.element.id) {index,asset in photo(asset,index:index,columns:columns).id(asset.id)}
                        }.padding()
                    }.accessibilityLabel("写真").accessibilityValue("\(workflow.assets.count)枚").accessibilityIdentifier("photo-grid")
                        .onChange(of:focus) {_,value in if case .photo(let id)=value {scroll.scrollTo(id)}}
                }
            }
        }.onAppear {if compactLayout,presentation.region == .photos {restoreFocus(.photos)}}
    }
    private func photo(_ asset:LibraryAsset,index:Int,columns:Int)->some View {
        let semantics=PhotoSemantics(position:index+1,selectedIndex:workflow.selection.orderedIDs.firstIndex(of:asset.id),available:workflow.images[asset.id] != nil,failure:workflow.imageFailures[asset.id])
        return Button {toggleFromUI(asset.id)} label: {
            VStack(spacing:4) {
                ZStack(alignment:.topTrailing) {
                    thumbnail(workflow.images[asset.id]).frame(height:100).frame(maxWidth:.infinity).clipped()
                    if let number=workflow.selection.orderedIDs.firstIndex(of:asset.id) {Text("\(number+1)").font(.headline).padding(6).background(.selection,in:Circle()).foregroundStyle(.primary)}
                }
                Text(workflow.imageFailures[asset.id] == nil ? "写真 \(index+1)" : "取得不可").font(.caption)
            }.padding(4).background(.quaternary.opacity(0.4),in:RoundedRectangle(cornerRadius:8))
        }.buttonStyle(.plain).disabled(workflow.isEditingFrozen)
            .focusable()
            .focused($focus,equals:.photo(asset.id))
            .overlay(RoundedRectangle(cornerRadius:8).stroke(focus == .photo(asset.id) ? Color.primary : Color.clear,lineWidth:2))
            .help(semantics.hint).accessibilityHint(semantics.hint)
            .accessibilityLabel(semantics.label).accessibilityValue(semantics.value)
            .accessibilityIdentifier("photo-cell")
            .onKeyPress(.space) {toggleFromUI(asset.id); return .handled}
            .onKeyPress(keys:[.leftArrow,.rightArrow,.upArrow,.downArrow,.tab,KeyEquivalent("\u{19}")]) {press in
                let direction:GridDirection
                switch press.key {case .leftArrow:direction = .left; case .rightArrow:direction = .right; case .upArrow:direction = .up; case .downArrow:direction = .down; default:direction = (press.modifiers.contains(.shift) || press.key==KeyEquivalent("\u{19}")) ? .backtab : .tab}
                switch GridNavigation.destination(direction,current:asset.id,ids:workflow.assets.map(\.id),columns:columns) {
                case .photo(let id):focus = .photo(id)
                case .previousRegion:presentation.region = .albums; restoreFocus(.albums)
                case .confirmation:
                    if workflow.canConfirm {focusConfirmation()}
                    else {presentation.region = .folders; restoreFocus(.folders)}
                }
                return .handled
            }
            .task(id:asset.id) {await workflow.loadImage(asset.id)}
            .onAppear {visible.insert(asset.id); workflow.updateVisibleImages(visible)}
            .onDisappear {visible.remove(asset.id); workflow.updateVisibleImages(visible)}
    }
    private var tray:some View {
        let snapshot=PresentationSnapshot(workflow)
        return VStack(alignment:.leading,spacing:8) {
            HStack {
                Text("選んだ写真").font(.headline).accessibilityAddTraits(.isHeader); Text(snapshot.countText).monospacedDigit(); Spacer()
                if let onArticle, canOpenArticle != nil || workflow.lastCommitted != nil {
                    Button("記事を開く", action:onArticle).focusable(false).disabled(canOpenArticle.map {!$0} ?? workflow.isEditingFrozen).accessibilityIdentifier("article-open")
                }
                if workflow.isSaving || workflow.restoreState.isBusy {ProgressView().controlSize(.small)}
                Button(snapshot.confirmTitle) {confirmFromUI()}.buttonStyle(.borderedProminent).disabled(!snapshot.canConfirm).focusable().focused($focus,equals:.confirm).accessibilityIdentifier("selection-confirm")
                    .onKeyPress(.space) {confirmFromUI(); return .handled}
                    .onKeyPress(keys:[.tab,KeyEquivalent("\u{19}")]) {press in
                        guard compactLayout,press.modifiers.contains(.shift) || press.key==KeyEquivalent("\u{19}") else {return .ignored}
                        restoreFocus(presentation.region); return .handled
                    }
            }
            HStack(spacing:8) {ForEach(0..<4,id:\.self) {index in
                let id=snapshot.slotIDs[index]
                VStack {
                    HStack {Text("\(index+1)"); thumbnail(id.flatMap {workflow.images[$0]}).frame(maxWidth:.infinity).frame(height:52).clipped()}
                    if measurement.enabled {Text("HZS \(index+1) \(id.flatMap {v in workflow.assets.firstIndex(where:{$0.id==v}).map {$0+1}} ?? 0)").font(.system(size:13,design:.monospaced))}
                }
                    .padding(4).frame(maxWidth:.infinity).background(.quaternary.opacity(0.4),in:RoundedRectangle(cornerRadius:8))
                    .accessibilityElement(children:.ignore)
                    .accessibilityLabel(PhotoSemantics.slotLabel(slot:index,position:id.flatMap {selected in workflow.assets.firstIndex(where:{$0.id==selected}).map {$0+1}}))
                    .accessibilityIdentifier("selection-slot-\(index+1)")
            }}
            Text(snapshot.statusText).font(.callout).fixedSize(horizontal:false,vertical:true).accessibilityIdentifier("selection-status")
            if measurement.enabled {Text("HZC \(workflow.selection.orderedIDs.count)").font(.system(size:13,design:.monospaced))}
        }.padding(12)
    }
    private var measurementView:some View {
        VStack(spacing:2) {
            Text(measurement.unavailable ? "測定未確認：入力時刻を照合できません。" : (measurement.stamp?.marker ?? "測定準備：選択操作を待っています。")).font(.system(size:13,design:.monospaced)).textSelection(.enabled)
            if let r=measuredResources ?? workflow.imageResources {Text("要求 \(r.active)、待機 \(r.queued)、保持 \(r.retainedBuffers)、bytes \(r.retainedBytes)、予約 \(r.reservedBytes)、必要 \(r.necessaryCount)、不要 \(r.unnecessaryDisplay)").font(.caption)}
            Button("資源を確認") {measuredResources=workflow.imageResources}.accessibilityIdentifier("measurement-resources")
        }.padding(4)
    }
    func toggleFromUI(_ id:String,eventSeconds:Double?=nil) {
        let timestamp=eventSeconds ?? NSApp.currentEvent?.timestamp
        let before=workflow.selection.orderedIDs
        workflow.toggle(id)
        let after=workflow.selection.orderedIDs
        guard before != after else {return}
        func positions(_ ids:[String])->[Int] {ids.compactMap {id in workflow.assets.firstIndex(where:{$0.id==id}).map {$0+1}}}
        let beforePositions=positions(before),afterPositions=positions(after)
        guard beforePositions.count==before.count,afterPositions.count==after.count else {return}
        measurement.record(eventSeconds:timestamp,beforePositions:beforePositions,positions:afterPositions)
    }
    private func confirmFromUI() {Task {await workflow.confirm()}}
    private func focusConfirmation() {focusTransfer += 1; focus = .confirm}
    @discardableResult private func selectFirstAlbumForTabEntry()->Bool {
        guard let event=NSApp.currentEvent,event.type == .keyDown || event.type == .keyUp,
              event.keyCode==48,
              event.modifierFlags.intersection([.command,.control,.option]).isEmpty,
              !workflow.isEditingFrozen,workflow.activeAlbum==nil,let first=workflow.albums.first else {return false}
        Task {
            guard !workflow.isEditingFrozen,workflow.activeAlbum==nil,workflow.albums.first?.id==first.id else {return}
            await workflow.selectAlbum(first)
        }
        return true
    }
    private func restoreFocus(_ region:PickerRegion) {
        focusTransfer += 1
        lastInteractionRegion=region
        if region == .folders,!workflow.hierarchy.folders.isEmpty {folderFocusRequest += 1; return}
        let ids:[String]
        switch region {case .folders:ids=presentation.rows(workflow.hierarchy.folders).map(\.id); case .albums:ids=workflow.albums.map(\.id); case .photos:ids=workflow.assets.map(\.id)}
        guard let id=presentation.restore(in:region,available:ids) else {
            if compactLayout {focus = .regionSwitch}
            else if workflow.canConfirm {focus = .confirm}
            else if !workflow.hierarchy.folders.isEmpty {folderFocusRequest += 1}
            else {focus = nil}
            return
        }
        switch region {
        case .folders:focus = .folder(id)
        case .albums:
            _=selectFirstAlbumForTabEntry()
            if compactLayout {restoreConnectedFocus(.albums,in:.albums,id:id)} else {focus = .albums}
        case .photos:restoreConnectedFocus(.photo(id),in:.photos,id:id)
        }
    }
    private func restoreConnectedFocus(_ target:PickerFocus,in region:PickerRegion,id:String) {
        let transfer=focusTransfer,album=workflow.activeAlbum?.id,folders=workflow.targetFolders,draft=workflow.selection.orderedIDs
        focus=nil
        // 明示的な領域入場のみ。View接続後に渡し、画像応答からは呼ばない。
        Task { @MainActor in
            await Task.yield()
            let sameAlbum=workflow.activeAlbum?.id==album || (region == .albums && album==nil && workflow.activeAlbum?.id==id)
            let exists=region == .photos ? workflow.assets.contains(where:{$0.id==id}) : workflow.albums.contains(where:{$0.id==id})
            guard transfer==focusTransfer,lastInteractionRegion==region,
                  (!compactLayout || presentation.region==region),workflow.authorization == .authorized,sameAlbum,
                  workflow.targetFolders==folders,workflow.selection.orderedIDs==draft,focus==nil,
                  exists,!workflow.isEditingFrozen else {return}
            focus=target
        }
    }
    private func name(_ title:String)->String {title.isEmpty ? "名称なし" : title}
    @ViewBuilder private func thumbnail(_ buffer:ImageBuffer?)->some View {
        if let image=buffer?.displayImage {Image(nsImage:image).resizable().scaledToFit()}
        else {Image(systemName:"photo").font(.title2).foregroundStyle(.secondary).frame(maxWidth:.infinity,maxHeight:.infinity)}
    }
}
extension ImageBuffer {
    public var displayImage: NSImage? {
        guard let provider=makeProvider(),
              let cg=CGImage(width:width,height:height,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:bytesPerRow,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedLast.rawValue),provider:provider,decode:nil,shouldInterpolate:true,intent:.defaultIntent) else { return nil }
        return NSImage(cgImage:cg,size:NSSize(width:width,height:height))
    }
    private func makeProvider() -> CGDataProvider? {
        let owner=ImageProviderOwner(storage:storage)
        let retained=Unmanaged.passRetained(owner)
        guard let provider=CGDataProvider(dataInfo:retained.toOpaque(),data:owner.bytes.bytes,size:owner.bytes.length,releaseData:{ info,_,_ in
            if let info { Unmanaged<ImageProviderOwner>.fromOpaque(info).release() }
        }) else { retained.release(); return nil }
        return provider
    }
}
// CFの描画プロバイダが返却バッファの寿命を保持する。NSDataは不変の橋渡し値で、
// bytesのポインタはownerの生存中だけ使用し、releaseDataでownerを解放する。
private final class ImageProviderOwner {
    let storage: ImageStorage
    let bytes: NSData
    init(storage: ImageStorage) { self.storage=storage; bytes=storage.pixels as NSData }
}

