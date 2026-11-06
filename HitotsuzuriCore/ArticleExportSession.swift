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
    public var downloadFraction: Double? {
        guard isBusy, !cancellationRequested, progress?.stage == "acquiring" else { return nil }
        return progress?.fraction
    }
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
            message = exportFailureMessage(error as? ArticleFailure ?? .ioFailure)
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
        guard value.jobID == activeJobID, isBusy, !cancellationRequested,
              let rank = progressRank(value) else { return }
        if let previous = progress, let oldRank = progressRank(previous) {
            guard rank >= oldRank else { return }
            if rank == oldRank, let fraction = previous.fraction {
                guard let next = value.fraction, next >= fraction else { return }
            }
        }
        progress = value
        switch value.stage {
        case "acquiring":
            let percent = value.fraction.map { " \(Int(($0 * 100).rounded(.down)))%" } ?? ""
            message = "写真 \(value.completedImages + 1)/4：画像を取得中…" + percent
        case "writing": message = "画像 \(value.completedImages)/4：画像を書込み中"
        case "validating": message = "記事と4枚を確認中"
        case "committing": message = "出力を確定中"
        default: break
        }
    }
    private func progressRank(_ value: ExportProgress) -> Int? {
        if let fraction = value.fraction {
            guard value.stage == "acquiring", fraction.isFinite, (0...1).contains(fraction) else { return nil }
        }
        switch value.stage {
        case "acquiring" where (0..<4).contains(value.completedImages): return value.completedImages * 2 + 1
        case "writing" where (1...4).contains(value.completedImages): return value.completedImages * 2
        case "validating" where value.completedImages == 4: return 9
        case "committing" where value.completedImages == 4: return 10
        default: return nil
        }
    }
    private func exportFailureMessage(_ failure: ArticleFailure) -> String {
        switch failure {
        case .assetUnavailable: return "画像を取得できませんでした。もう一度出力してください。"
        case .invalidReference: return "写真または保存先の参照を確認できません。対象とアクセス許可を確認して、もう一度出力してください。"
        default: return failure.message
        }
    }
    public func adoptRecoveredResult(_ result: ExportResult) {
        guard !isBusy else { return }
        self.result = result; message = "前回の記事と4枚の出力を照合しました。"; focusReturn += 1
    }
}
