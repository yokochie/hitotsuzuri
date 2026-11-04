import SwiftUI
import HitotsuzuriCore

struct PickerView: View {
    let workflow: SelectionWorkflow
    @Bindable var articles: ArticleAppCoordinator
    var body: some View {
        Group {
            if let session = articles.session { ArticleView(session:session,coordinator:articles) }
            else { VStack(spacing:0) {
                PickerContent(workflow:workflow,measurement:NativeMeasurement(enabled:ProcessInfo.processInfo.arguments.contains("--measure-native")),onArticle:{Task {await articles.openArticle()}})
                if !articles.message.isEmpty { Text(articles.message).padding(8) }
                if articles.recovery != nil {Button("前回の出力を照合") {Task {await articles.recoverProbe()}}.padding(8)}
            } }
        }.background(ArticleWindowAttachment(coordinator:articles)).task { await workflow.start(); await articles.loadRecovery() }
    }
}

