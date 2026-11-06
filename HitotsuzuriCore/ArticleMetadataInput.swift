import Foundation

/// 永続化できない入力途中の文字列も編集セッションが保持する。
public struct ArticleMetadataInput: Equatable, Sendable {
    public static func == (lhs:Self,rhs:Self)->Bool {
        lhs.year.utf8.elementsEqual(rhs.year.utf8) && lhs.month.utf8.elementsEqual(rhs.month.utf8)
            && lhs.day.utf8.elementsEqual(rhs.day.utf8) && lhs.candidateState == rhs.candidateState
    }
    public private(set) var year: String
    public private(set) var month: String
    public private(set) var day: String
    public private(set) var candidateState: ArticleDateCandidateState
    public init(content: ArticleContent) {
        year = content.shootingDate.map { String($0.year) } ?? ""
        month = content.shootingDate.map { String($0.month) } ?? ""
        day = content.shootingDate.map { String($0.day) } ?? ""
        candidateState = content.dateCandidateState
    }
    public mutating func change(year: String, month: String, day: String) {
        guard !self.year.utf8.elementsEqual(year.utf8) || !self.month.utf8.elementsEqual(month.utf8) || !self.day.utf8.elementsEqual(day.utf8) else { return }
        self.year = year; self.month = month; self.day = day
        candidateState = isEmpty ? .absent : .candidate
    }
    public mutating func confirm() throws {
        guard try validatedDate() != nil else { throw ArticleFailure.invalidInput }
        candidateState = .confirmed
    }
    public mutating func remove() { year = ""; month = ""; day = ""; candidateState = .absent }
    public func applying(to content: ArticleContent) throws -> ArticleContent {
        var value = content
        value.shootingDate = try validatedDate()
        value.dateCandidateState = isEmpty ? .absent : candidateState
        return value
    }
    public var validationMessage: String? {
        do { _ = try validatedDate(); return nil }
        catch { return "年は半角数字1〜9999、月・日は実在する年月日を入力してください。日付なしにする場合は全欄を削除してください。" }
    }
    private var isEmpty: Bool { year.isEmpty && month.isEmpty && day.isEmpty }
    private func validatedDate() throws -> ArticleCalendarDay? {
        if isEmpty { return nil }
        let raw = [year, month, day]
        guard raw.allSatisfy({ !$0.isEmpty && $0.utf8.allSatisfy { (48...57).contains($0) } }),
              let y = Int(year), let m = Int(month), let d = Int(day) else { throw ArticleFailure.invalidInput }
        let date = ArticleCalendarDay(year: y, month: m, day: d)
        guard date.isValid else { throw ArticleFailure.invalidInput }
        return date
    }
}
