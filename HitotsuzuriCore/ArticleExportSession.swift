import Foundation
import Observation

@MainActor @Observable public final class ArticleExportSession {
    public private(set) var isBusy = false
    public private(set) var result: ExportResult?
    public private(set) var progress: ExportProgress?
    public private(set) var message = ""
    public private(set) var focusReturn = 0
    public private(set) var activeJobID: UUID?
    private let presentation: ArticlePresentation
    private let actions: any ArticleOutputActions
    private var cancellationRequested = false
    public init(presentation: ArticlePresentation, actions: any ArticleOutputActions) {
        self.presentation = presentation; self.actions = actions
    }
    public func start(choice: ArticleLeaveChoice, destination: @escaping @MainActor () async throws -> ArticleExportDestination?) async {
        guard !isBusy, !presentation.isLoading, presentation.pendingNavigation == nil else { return }
        cancellationRequested = false
        isBusy = true; result = nil; message = "出力を準備しています…"; progress = nil
        defer { isBusy = false; activeJobID = nil; presentation.setExportLock(false); focusReturn += 1 }
        do {
            guard let session = presentation.session, let saved = try await presentation.prepareSavedExport(choice) else { message = "出力を取り消しました。"; return }
            let sessionID = session.sessionID
            let rendered = try await Task.detached { try ArticleProjectionContext(projectID: saved.article.projectID).renderArticle(source: saved.article.source, content: saved.article.content) }.value
            let prepared = try PreparedArticleExport(savedInput: saved, rendered: rendered)
            guard let destination = try await destination() else { message = "出力を取り消しました。"; return }
            defer { (actions as? any ArticleExportDestinationReleasing)?.releaseDestination(destination) }
            guard presentation.session?.sessionID == sessionID, !session.isDirty, !session.hasUncertainSave,
                  session.saved == saved.article, ArticleFingerprint.content(source: session.source, content: try session.validatedContent()) == saved.article.fingerprint else { throw ArticleFailure.invalidInput }
            presentation.setExportLock(true)
            let id = UUID(); activeJobID = id
            let completed = try await actions.runExport(jobID: id, savedInput: prepared.savedInput, rendered: prepared.rendered, destination: destination) { [weak self] value in self?.receive(value) }
            guard activeJobID == id, completed.jobID == id, completed.projectID == saved.article.projectID,
                  completed.fingerprint == saved.article.fingerprint, completed.savedRevision == saved.article.savedRevision else { throw ArticleFailure.invalidInput }
            result = completed; message = "記事と4枚の出力が完了しました。"
        } catch {
            message = (error as? ArticleFailure ?? .ioFailure).message
            if activeJobID != nil, let detail = (actions as? any ArticleExportFailureDescribing)?.lastFailureDetail {
                if let index = detail.photoIndex { message = "写真 \(index)：" + message }
                if let directory = detail.residualDirectory { message += " 確認が必要な場所：" + directory.path }
            }
        }
    }
    public func cancel() {
        guard let id = activeJobID else { return }
        message = "取消を受け付けました。画像処理と片付けの完了を待っています…"
        cancellationRequested = true
        actions.cancelExport(id)
    }
    public func receive(_ value: ExportProgress) {
        guard value.jobID == activeJobID, isBusy, !cancellationRequested, (0...4).contains(value.completedImages),
              value.completedImages >= (progress?.completedImages ?? 0) else { return }
        progress = value
        let label: String
        switch value.stage {
        case "acquiring": label = "画像を取得中"
        case "writing": label = "画像を書込み中"
        case "validating": label = "記事と4枚を確認中"
        case "committing": label = "出力を確定中"
        default: label = "出力処理中"
        }
        message = "画像 \(value.completedImages)/4：" + label
    }
    public func adoptRecoveredResult(_ result: ExportResult) {
        guard !isBusy else { return }
        self.result = result; message = "前回の記事と4枚の出力を照合しました。"; focusReturn += 1
    }
}
