import SwiftUI
import HitotsuzuriCore

struct ArticleExportView: View {
    @Bindable var coordinator: ArticleAppCoordinator
    var focus: FocusState<String?>.Binding
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button("本文をコピー") { Task { _ = await coordinator.presentation.copyCurrent() } }
                .disabled(coordinator.working).focusable().focused(focus, equals: "article-copy")
                .accessibilityIdentifier("article-copy").id("article-copy")
            Button("記事と4枚を出力") { Task { await coordinator.exportArticle() } }
                .disabled(coordinator.working || coordinator.session?.isSaving == true || coordinator.pendingExportRecovery != nil)
                .focusable().focused(focus, equals: "article-export")
                .accessibilityIdentifier("article-export").id("article-export")
            if coordinator.articleExport.isBusy {
                ProgressView().controlSize(.small)
                Button("出力を取り消す") { coordinator.articleExport.cancel() }
                    .focusable().focused(focus, equals: "article-export-cancel")
                    .accessibilityIdentifier("article-export-cancel").id("article-export-cancel")
            }
            if !coordinator.articleExport.message.isEmpty {
                Text(coordinator.articleExport.message).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("article-export-message")
            }
            if let result = coordinator.articleExport.result, result.projectID == coordinator.session?.projectID {
                Text("記事と画像4枚の出力が完了しました。\n" + result.directory.path)
                    .textSelection(.enabled).fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("article-export-result")
                Button("出力時点の本文をコピー") {
                    #if DEBUG
                    coordinator.markCompletedCopyActivation()
                    #endif
                    Task { await coordinator.copyCompletedExport() }
                }
                    // マウス押下でedit focusを新規取得して移動しない。独自Tabの明示対象には従来の全focusを許す。
                    .disabled(coordinator.working)
                    .focusable(interactions: focus.wrappedValue == "article-export-copy-fixed" ? [.edit, .activate] : .activate)
                    .focused(focus, equals: "article-export-copy-fixed")
                    .accessibilityIdentifier("article-export-copy-fixed").id("article-export-copy-fixed")
                    #if DEBUG
                    .accessibilityValue(coordinator.fixtureCopiedExportText)
                    #endif
                Button("Finderで出力フォルダを開く") { Task { await coordinator.revealCompletedExport() } }
                    .disabled(coordinator.working).focusable().focused(focus, equals: "article-export-reveal")
                    .accessibilityIdentifier("article-export-reveal").id("article-export-reveal")
            }
            if coordinator.pendingExportRecovery != nil {
                Text("前回の出力に確認待ちの記録があります。同じ保存先を選び直してください。")
                    .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("article-export-recovery-message")
                Button("前回の記事出力を照合") { Task { await coordinator.recoverExport() } }
                    .disabled(coordinator.working).focusable().focused(focus, equals: "article-export-recover")
                    .accessibilityIdentifier("article-export-recover").id("article-export-recover")
                if coordinator.exportRecoveryNeedsCleanup {
                    Button("未完の一時出力を片付ける") { Task { await coordinator.recoverExport(cleanup: true) } }
                        .disabled(coordinator.working).focusable().focused(focus, equals: "article-export-cleanup")
                        .accessibilityIdentifier("article-export-cleanup").id("article-export-cleanup")
                }
            }
            if !coordinator.exportOSMessage.isEmpty {
                Text(coordinator.exportOSMessage).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("article-export-os-message")
            }
            Text("本文をnoteへ貼り付け、imagesフォルダの01〜04を順番に手動で挿入してください。")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
}
