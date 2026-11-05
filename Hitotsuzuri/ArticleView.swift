import SwiftUI
import HitotsuzuriCore

struct ArticleView: View {
    @Bindable var session: ArticleEditSession
    @Bindable var coordinator: ArticleAppCoordinator
    @FocusState private var focusedField:String?
    @State private var lastField="article-title"
    @State private var keyboardFocusRequest=0
    private var presentation:ArticlePresentation {coordinator.presentation}
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing:0) {
                header
                Divider()
                ScrollViewReader { scroll in
                    ScrollView {
                        if presentation.mode == .preview, let rendered=presentation.rendered, let content=try? session.validatedContent() {
                            ArticlePreviewView(content:content,rendered:rendered,previews:coordinator.previews)
                                .frame(maxWidth:720).frame(maxWidth:.infinity).padding(16).id("article-preview-top")
                        } else {
                            let wide=geometry.size.width >= 960
                            let layout=wide ? AnyLayout(HStackLayout(alignment:.top,spacing:16)) : AnyLayout(VStackLayout(alignment:.leading,spacing:16))
                            layout {
                                photos(wide:wide).frame(width:wide ? 280 : nil)
                                form.frame(minWidth:wide ? 400 : 0,maxWidth:.infinity)
                            }.padding(16)
                        }
                        actions.padding(16)
                    }
                    .onChange(of:focusedField) {_,field in
                        if let field {
                            if inputOrder.contains(field) {lastField=field}
                        }
                    }
                    .onChange(of:keyboardFocusRequest) {_,_ in if let field=focusedField {scroll.scrollTo(field,anchor:.center)}}
                    .onChange(of:session.sessionID) {_,_ in
                        lastField="article-title"; scroll.scrollTo("article-title",anchor:.top)
                        Task {await Task.yield(); focusedField="article-title"}
                    }
                    .onChange(of:presentation.mode) {_,mode in
                        if mode == .editing {Task {await Task.yield(); focusedField=lastField; scroll.scrollTo(lastField,anchor:.center)}}
                        else {scroll.scrollTo("article-preview-top",anchor:.top)}
                    }
                }
            }.onAppear {focusedField="article-title"}
            .overlay(alignment:.topLeading) {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--article-test-fixture") {
                    Text(String(format:"%.2f:%@",geometry.size.width,geometry.size.width >= 960 ? "wide" : "narrow"))
                        .font(.system(size:1)).foregroundStyle(.clear).frame(width:1,height:1).clipped().allowsHitTesting(false)
                        .accessibilityElement().accessibilityLabel(String(format:"%.2f:%@",geometry.size.width,geometry.size.width >= 960 ? "wide" : "narrow")).accessibilityIdentifier("article-layout")
                }
                if coordinator.fixtureMeasuresPerformance {
                    ArticleFixtureDisplayProbe(coordinator:coordinator,revision:"\(presentation.mode)-\(presentation.isLoading)-\(session.stateMessage)-\(session.content.title)-\(session.sessionID)",sessionID:session.sessionID).frame(width:1,height:1).allowsHitTesting(false)
                }
                #endif
            }
        }.frame(minWidth:640,minHeight:560)
        .onKeyPress(keys:[.tab,KeyEquivalent("\u{19}")]) {press in moveFocus(backward:press.modifiers.contains(.shift) || press.key == KeyEquivalent("\u{19}"))}
        .onKeyPress(.space) {activateFocusedButton()}
    }
    private var header:some View {
        VStack(alignment:.leading,spacing:8) {
            HStack {navigation; Spacer(); save}
            if presentation.isLoading {Text("下書きを読み込み中…").accessibilityIdentifier("article-loading")}
            #if DEBUG
            if let release=coordinator.fixtureReleaseSave {Button("試験：保存応答を返す") {Task {await release()}}.accessibilityIdentifier("draft-release-save")}
            if ProcessInfo.processInfo.arguments.contains("--article-test-fixture") {
                if let counts=coordinator.fixturePreviewRequestCounts {
                    Text("試験：写真要求数").font(.caption2)
                        .accessibilityIdentifier("draft-photo-request-counts")
                        .accessibilityValue(counts().map(String.init).joined(separator:","))
                }
                HStack {
                    ForEach([640,959,960,961,1200],id:\.self) {width in
                        Button("\(width)pt") {coordinator.resizeFixtureWindow(width:width)}.accessibilityIdentifier("draft-width-\(width)")
                    }
                }.fixedSize()
            }
            if coordinator.fixtureMeasuresPerformance {
                Button("試験：下書きを再開") {Task {await coordinator.reopenFixtureDraft()}}.accessibilityIdentifier("draft-reopen")
                Button("試験：写真の取得を再開") {coordinator.restartFixturePreviews()}.accessibilityIdentifier("draft-restart-photos")
            }
            if coordinator.fixturePrepareRead != nil {
                HStack {
                    Button("試験：読込応答を保留") {Task {await coordinator.armFixtureRead()}}.accessibilityIdentifier("draft-arm-read")
                    Button("試験：読込応答を返す") {Task {await coordinator.releaseFixtureRead()}}.accessibilityIdentifier("draft-release-read")
                    if coordinator.fixtureReadArmed {Text("試験読込保留中").accessibilityIdentifier("draft-read-armed")}
                }
            }
            if coordinator.fixtureMeasuresPerformance {
                Text(coordinator.fixtureMetricsText).font(.caption2).lineLimit(1).accessibilityIdentifier("draft-display-metrics")
            }
            #endif
            Text(session.stateMessage).fixedSize(horizontal:false,vertical:true).accessibilityIdentifier("article-save-state")
            Text("元アルバム："+session.source.albumTitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
        }.padding(12)
    }
    private var navigation:some View {
        HStack {
            Button("写真選択へ戻る") {Task {_=await coordinator.leave()}}.focusable().focused($focusedField,equals:"article-back").accessibilityIdentifier("article-back")
            Button("編集") {showEditor()}.focusable().focused($focusedField,equals:"article-mode-edit").accessibilityIdentifier("article-mode-edit")
            Button(presentation.isProjecting ? "プレビュー準備中…" : "プレビュー") {showPreview()}
                .disabled(presentation.isProjecting || coordinator.working).focusable().focused($focusedField,equals:"article-mode-preview").accessibilityIdentifier("article-mode-preview")
        }.disabled(coordinator.working || presentation.isLoading)
    }
    private var save:some View {
        Button("保存") {saveDraft()}.keyboardShortcut("s")
            .disabled(session.isSaving || coordinator.working || presentation.isLoading).focusable().focused($focusedField,equals:"article-save").accessibilityIdentifier("article-save")
    }
    private var form:some View {
        VStack(alignment:.leading,spacing:16) {
            VStack(alignment:.leading) {
                Text("記事タイトル").font(.headline)
                TextField("記事タイトル",text:Binding(get:{session.content.title},set:{value in
                    #if DEBUG
                    if !value.utf8.elementsEqual(session.content.title.utf8) {coordinator.beginFixtureMetric("input-draw",title:value)}
                    #endif
                    session.content.title=value
                })).textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("article-title").focused($focusedField,equals:"article-title")
            }.id("article-title")
            field("導入文",text:$session.content.introduction,id:"article-introduction")
            ForEach(0..<session.content.photoTexts.count,id:\.self) {index in
                field("写真 \(index+1) の文章",text:$session.content.photoTexts[index].text,id:"article-photo-\(index+1)")
            }
            field("締めの文章",text:$session.content.closing,id:"article-closing")
            ArticleMetadataFields(session:session,focus:$focusedField)
                .onKeyPress(keys:[.tab,KeyEquivalent("\u{19}")]) {press in moveFocus(backward:press.modifiers.contains(.shift) || press.key == KeyEquivalent("\u{19}"))}
        }.disabled(coordinator.working || presentation.isLoading)
    }
    private func field(_ label:String,text:Binding<String>,id:String)->some View {
        VStack(alignment:.leading) {
            Text(label).font(.headline)
            TextEditor(text:text).frame(height:140).border(.quaternary).accessibilityIdentifier(id)
                .focused($focusedField,equals:id)
                .onKeyPress(keys:[.tab,KeyEquivalent("\u{19}")]) {press in moveFocus(backward:press.modifiers.contains(.shift) || press.key == KeyEquivalent("\u{19}"))}
        }.id(id)
    }
    private func photos(wide:Bool)->some View {
        LazyVGrid(columns:Array(repeating:GridItem(.flexible(),alignment:.top),count:wide ? 1 : 2),alignment:.leading,spacing:16) {
            ForEach(0..<session.source.orderedAssetIDs.count,id:\.self) {index in
                let id=session.source.orderedAssetIDs[index]
                let state=coordinator.previews?.states[id] ?? .waiting
                VStack(alignment:.leading,spacing:6) {
                    Text("写真 \(index+1)").font(.headline)
                    if case .ready(let buffer)=state, let image=buffer.displayImage {
                        Image(nsImage:image).resizable().scaledToFit().frame(maxHeight:160).accessibilityIdentifier("article-preview-\(index+1)")
                    }
                    Text(state.message).font(.callout).fixedSize(horizontal:false,vertical:true).accessibilityIdentifier("article-preview-state-\(index+1)")
                    Button("写真 \(index+1) を再試行") {retryPhoto(index)}
                        .disabled(coordinator.previews?.isLoading == true)
                        .focusable().focused($focusedField,equals:"article-retry-\(index+1)")
                        .accessibilityIdentifier("article-retry-\(index+1)").id("article-retry-\(index+1)")
                }.frame(maxWidth:.infinity,alignment:.leading)
            }
        }
    }
    private var actions:some View {
        VStack(alignment:.leading,spacing:12) {
            Text("写真を取得できない場合も文章を保存・再開できます。").foregroundStyle(.secondary)
            VStack(alignment:.leading,spacing:8) {outputActions}
            Text("本文コピー・4枚一式の出力は現在利用できません。画像1枚の検証出力とは別の操作です。").font(.caption).foregroundStyle(.secondary)
            if let message=presentation.message {Text(message).textSelection(.enabled).fixedSize(horizontal:false,vertical:true).accessibilityIdentifier("article-action-message")}
            Text(coordinator.message).textSelection(.enabled).fixedSize(horizontal:false,vertical:true)
            if !coordinator.outputPath.isEmpty {Text(coordinator.outputPath).textSelection(.enabled).fixedSize(horizontal:false,vertical:true)}
            if coordinator.recovery != nil {Button("前回の出力を照合") {Task {await coordinator.recoverProbe()}}.disabled(coordinator.working)}
        }.frame(maxWidth:.infinity,alignment:.leading)
    }
    @ViewBuilder private var outputActions:some View {
        Button("本文をコピー") {Task {_=await presentation.copyCurrent()}}.disabled(!presentation.capabilities.copy || coordinator.working).accessibilityIdentifier("article-copy")
        Text("記事と4枚を出力（現在利用できません）").foregroundStyle(.secondary).accessibilityIdentifier("article-export-unavailable")
        Button("画像1枚の検証出力") {coordinator.probe()}.keyboardShortcut("e",modifiers:[.command,.shift])
            .disabled(coordinator.working || session.isSaving).focusable().focused($focusedField,equals:"article-probe").accessibilityIdentifier("article-probe").id("article-probe")
        if coordinator.working {ProgressView().controlSize(.small); Button("取り消す") {coordinator.cancelProbe()}}
    }
    private var inputOrder:[String] {
        ["article-title","article-introduction","article-photo-1","article-photo-2","article-photo-3","article-photo-4","article-closing","article-year","article-month","article-day","article-date-confirm","article-date-remove","article-location","article-equipment","article-film","article-people"]
    }
    private var photoRetryOrder:[String] {
        session.source.orderedAssetIDs.indices.map {"article-retry-\($0+1)"}
    }
    private func moveFocus(backward:Bool)->KeyPress.Result {
        guard !coordinator.working, !presentation.isLoading else {return .ignored}
        var order=presentation.mode == .editing ? inputOrder : []
        if session.metadataInput.validationMessage != nil || session.metadataInput.year.isEmpty {order.removeAll {$0 == "article-date-confirm"}}
        order += ["article-probe","article-back","article-mode-edit","article-mode-preview","article-save"]
        if presentation.mode == .editing, coordinator.previews?.isLoading == false {order += photoRetryOrder}
        guard let current=focusedField, let index=order.firstIndex(of:current) else {return .ignored}
        focusedField=order[(index+(backward ? order.count-1 : 1)) % order.count]
        keyboardFocusRequest += 1
        return .handled
    }
    private func activateFocusedButton()->KeyPress.Result {
        guard !coordinator.working, !presentation.isLoading else {return .ignored}
        switch focusedField {
        case "article-mode-preview":showPreview()
        case "article-mode-edit":showEditor()
        case "article-save":guard !session.isSaving else {return .handled}; saveDraft()
        case "article-back":Task {_=await coordinator.leave()}
        case "article-date-confirm":try? session.metadataInput.confirm()
        case "article-date-remove":session.metadataInput.remove()
        case "article-probe":coordinator.probe()
        default:
            guard presentation.mode == .editing, let focusedField,
                  let index=photoRetryOrder.firstIndex(of:focusedField) else {return .ignored}
            retryPhoto(index)
        }
        return .handled
    }
    private func retryPhoto(_ index:Int) {
        guard let previews=coordinator.previews, !previews.isLoading,
              session.source.orderedAssetIDs.indices.contains(index) else {return}
        let assetID=session.source.orderedAssetIDs[index]
        Task {await previews.retry(assetID)}
    }
    private func showPreview() {
        #if DEBUG
        coordinator.beginFixtureMetric("preview-draw")
        #endif
        Task {await presentation.showPreview()}
    }
    private func showEditor() {
        #if DEBUG
        coordinator.beginFixtureMetric("editor-input-ready")
        #endif
        presentation.showEditor()
    }
    private func saveDraft() {
        #if DEBUG
        coordinator.beginFixtureMetric("saving-draw")
        #endif
        Task {_=await session.save()}
    }
}
