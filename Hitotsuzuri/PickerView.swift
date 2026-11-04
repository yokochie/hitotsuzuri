import SwiftUI
import HitotsuzuriCore

struct PickerView: View {
    let workflow: SelectionWorkflow
    @Bindable var articles: ArticleAppCoordinator
    var body: some View {
        Group {
            if let session = articles.session { ArticleView(session:session,coordinator:articles).background(ArticleWindowAttachment(coordinator:articles)) }
            else { VStack(spacing:0) {
                PickerContent(workflow:workflow,measurement:NativeMeasurement(enabled:ProcessInfo.processInfo.arguments.contains("--measure-native")),onArticle:{Task {await articles.openArticle()}},canOpenArticle:articles.canOpenCurrentSelection)
                if !articles.canOpenCurrentSelection {Text("記事を始めるには写真4枚を確定してください。保存済みの下書きは記事メニューから開けます。").font(.caption).padding(8)}
                if articles.presentation.isLoading {Text("記事を読み込み中…").accessibilityIdentifier("article-loading").padding(8)}
                if let message=articles.presentation.message {Text(message).padding(8)}
                if articles.presentation.failure != nil {Button("記事の読込を再試行") {Task {await articles.openArticle()}}.padding(8)}
                if !articles.message.isEmpty { Text(articles.message).padding(8) }
                if articles.recovery != nil {Button("前回の出力を照合") {Task {await articles.recoverProbe()}}.padding(8)}
            } }
        }
        .sheet(isPresented:Binding(get:{articles.presentation.candidates != nil && !articles.suspendsCandidates},set:{if !$0 && !articles.suspendsCandidates {articles.presentation.cancelCandidates()}}),onDismiss:{articles.candidateDidDismiss()}) {
            ArticleDraftPicker(coordinator:articles).onAppear {articles.candidateSheetVisible=true}
        }
        .task {
            await articles.refreshEntryAvailability()
            #if DEBUG
            if articles.fixtureMeasuresPerformance,ProcessInfo.processInfo.environment["HZS_DRAFT_AUTO_OPEN"] == "1" {await articles.openArticle()}
            #endif
            await workflow.start(); await articles.loadRecovery()
        }
        .onChange(of:workflow.selectionSaveState) {_,_ in Task {await articles.refreshEntryAvailability()}}
    }
}

private struct ArticleDraftPicker:View {
    @Bindable var coordinator:ArticleAppCoordinator
    @State private var selected:UUID?
    var body:some View {
        VStack(alignment:.leading,spacing:16) {
            Text("下書きを選択").font(.title2)
            if let list=coordinator.presentation.candidates {
                if list.articles.isEmpty {Text(list.failures.isEmpty ? "保存した下書きはありません。" : "下書きを読み取れませんでした。")}
                ScrollView {
                    Picker("開く下書き",selection:$selected) {
                        ForEach(list.articles) {article in
                            Text(summary(article)).tag(Optional(article.id))
                        }
                    }.pickerStyle(.radioGroup)
                }
                if !list.failures.isEmpty {Text("読込失敗：\(list.failures.count)件。読めた下書きは選択して開けます。").fixedSize(horizontal:false,vertical:true)}
                if coordinator.presentation.isLoading {Text("下書きを読み込み中…").accessibilityIdentifier("draft-loading")}
                if let message=coordinator.presentation.message {Text(message).fixedSize(horizontal:false,vertical:true)}
                Button(coordinator.presentation.pendingAssociationProjectID == nil ? "一覧を再読込" : "関連付け結果を照合") {Task {await coordinator.retryDraftList()}}.disabled(coordinator.presentation.isLoading).accessibilityIdentifier("draft-retry")
                HStack {
                    if coordinator.presentation.allowsNew {Button("新しく記事を作る") {Task {await coordinator.createDraft()}}.accessibilityIdentifier("draft-new")}
                    Button("既存の下書きを再開") {if let selected {Task {await coordinator.chooseDraft(selected)}}}.disabled(selected == nil || coordinator.presentation.isLoading).accessibilityIdentifier("draft-open")
                    Button("キャンセル") {coordinator.presentation.cancelCandidates()}.keyboardShortcut(.cancelAction).disabled(coordinator.presentation.pendingAssociationProjectID != nil || coordinator.presentation.isLoading).accessibilityIdentifier("draft-cancel")
                }
            }
        }.padding(20).frame(minWidth:480,idealWidth:600,minHeight:280,maxHeight:500)
    }
    private func summary(_ article:SavedArticle)->String {
        let ids=coordinator.presentation.candidates?.articles.map {$0.id.uuidString} ?? []
        var length=8
        while length < 36, ids.filter({$0.prefix(length) == article.id.uuidString.prefix(length)}).count > 1 {length=min(36,length+4)}
        return (article.content.title.isEmpty ? "無題の記事" : article.content.title)+"\n"+article.source.albumTitle+" · "+article.updatedAt.formatted(date:.numeric,time:.shortened)+" · "+String(article.id.uuidString.prefix(length))
    }
}

