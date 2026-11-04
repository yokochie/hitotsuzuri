import Foundation

public enum ArticleFailure: String, Error, Codable, Sendable {
    case invalidInput, missing, corruptData, unsupportedVersion, conflict
    case permissionDenied, assetUnavailable, invalidReference, capacity, timedOut
    case cancelled, ioFailure, uncertainResult, cleanupFailure, busy

    public var message: String {
        switch self {
        case .invalidInput: "入力内容と写真の対応を確認してください。"
        case .missing: "保存された記事が見つかりません。"
        case .corruptData: "記事を読み取れません。原本を保護するため変更しません。"
        case .unsupportedVersion: "この記事の保存形式には対応していません。"
        case .conflict: "保存済み記事が変更されています。入力を保持して保存を止めました。"
        case .permissionDenied: "アクセスが許可されていません。写真や保存先の許可を確認してください。"
        case .assetUnavailable: "画像を取得できません。写真アプリで事前取得してから再試行してください。"
        case .invalidReference: "写真または保存先の参照を確認できません。"
        case .capacity: "安全に処理できる容量を超えています。"
        case .timedOut: "処理が時間内に完了しませんでした。準備後に再試行してください。"
        case .cancelled: "処理を取り消しました。"
        case .ioFailure: "保存できませんでした。入力と前回の保存内容は保持しています。"
        case .uncertainResult: "保存結果を確認できません。再試行の前に結果を照合します。"
        case .cleanupFailure: "一時出力を片付けられませんでした。残存場所を確認してください。"
        case .busy: "前の処理の終了を待っています。"
        }
    }
}

public struct ArticleSource: Codable, Equatable, Sendable {
    public let selectionID: UUID
    public let albumID: String
    public let albumTitle: String
    public let orderedAssetIDs: [String]
    public let confirmedAt: Date
    public let selectionRevision: Int

    public init(selection: CommittedSelection) throws {
        guard selection.isValid, articleTimestampIsRepresentable(selection.confirmedAt) else { throw ArticleFailure.invalidInput }
        selectionID = selection.selectionID
        albumID = selection.albumID
        albumTitle = selection.albumTitle
        orderedAssetIDs = selection.orderedAssetIDs
        confirmedAt = selection.confirmedAt
        selectionRevision = 1
    }

    public var isValid: Bool {
        !albumID.isEmpty && orderedAssetIDs.count == 4
            && Set(orderedAssetIDs).count == 4 && orderedAssetIDs.allSatisfy { !$0.isEmpty }
            && articleTimestampIsRepresentable(confirmedAt) && selectionRevision == 1
    }
}

private func articleTimestampIsRepresentable(_ date:Date) ->Bool {
    let milliseconds=(date.timeIntervalSince1970*1000).rounded()
    return milliseconds.isFinite && milliseconds >= Double(Int64.min) && milliseconds < Double(Int64.max)
}

public struct ArticleCalendarDay: Codable, Equatable, Sendable {
    public var year: Int
    public var month: Int
    public var day: Int
    public init(year: Int, month: Int, day: Int) { self.year = year; self.month = month; self.day = day }
    public var isValid: Bool {
        guard (1...9999).contains(year), (1...12).contains(month), day > 0 else { return false }
        let leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
        return day <= [31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]
    }
}

public struct ArticlePhotoText: Codable, Equatable, Sendable {
    public let assetID: String
    public var text: String
    public init(assetID: String, text: String = "") { self.assetID = assetID; self.text = text }
}

public enum ArticleDateCandidateState: String, Codable, Sendable { case absent, candidate, confirmed }

public struct ArticleContent: Codable, Equatable, Sendable {
    public var title: String
    public var introduction = ""
    public var photoTexts: [ArticlePhotoText]
    public var closing = ""
    public var shootingDate: ArticleCalendarDay?
    public var dateCandidateState: ArticleDateCandidateState = .absent
    public var location = ""
    public var equipment = ""
    public var film = ""
    public var people = ""

    public init(source: ArticleSource) {
        title = source.albumTitle
        photoTexts = source.orderedAssetIDs.map { ArticlePhotoText(assetID: $0) }
    }

    public func validate(source: ArticleSource) throws {
        guard source.isValid, photoTexts.map(\.assetID) == source.orderedAssetIDs,
              shootingDate?.isValid != false,
              (shootingDate == nil) == (dateCandidateState == .absent) else { throw ArticleFailure.invalidInput }
    }
}

public struct SavedArticle: Codable, Equatable, Sendable, Identifiable {
    public var schemaVersion = 1
    public let projectID: UUID
    public let source: ArticleSource
    public var sourceSelectionIDs: [UUID]
    public var content: ArticleContent
    public var savedRevision: Int
    public var fingerprint: String
    public let createdAt: Date
    public var updatedAt: Date
    public var id: UUID { projectID }

    public init(projectID: UUID, source: ArticleSource, content: ArticleContent, now: Date = Date()) throws {
        try content.validate(source: source)
        self.projectID = projectID; self.source = source; self.content = content
        sourceSelectionIDs = [source.selectionID]; savedRevision = 1
        fingerprint = ArticleFingerprint.content(source: source, content: content)
        let storedNow = Date(timeIntervalSince1970: (now.timeIntervalSince1970 * 1000).rounded() / 1000)
        createdAt = storedNow; updatedAt = storedNow
    }

    public func validate() throws {
        guard schemaVersion == 1 else { throw ArticleFailure.unsupportedVersion }
        try content.validate(source: source)
        guard savedRevision >= 1, sourceSelectionIDs.contains(source.selectionID),
              Set(sourceSelectionIDs).count == sourceSelectionIDs.count,
              createdAt.timeIntervalSince1970.isFinite, updatedAt.timeIntervalSince1970.isFinite,
              fingerprint == ArticleFingerprint.content(source: source, content: content) else {
            throw ArticleFailure.corruptData
        }
    }
}

public struct ArticleDraftList: Sendable {
    public var articles: [SavedArticle]
    public var failures: [UUID: ArticleFailure]
    public init(articles: [SavedArticle] = [], failures: [UUID: ArticleFailure] = [:]) {
        self.articles = articles; self.failures = failures
    }
}
