import Foundation

/// 新規作成だけで使う初期化境界。保存済み記事の読込には適用しない。
public struct ArticleInitialContent: Sendable {
    public let content: ArticleContent
    public let invalidDateSuffix: Bool
    public init(source: ArticleSource) {
        var value = ArticleContent(source: source)
        let suffix = Array(source.albumTitle.utf8.suffix(7))
        if suffix.count == 7, suffix[0] == 64, suffix.dropFirst().allSatisfy({ (48...57).contains($0) }) {
            // GraphemeのPrepend文字が@へ結合していても、一致したASCII byteだけ除く。
            value.title = String(decoding: source.albumTitle.utf8.dropLast(7), as: UTF8.self)
            let numbers = suffix.dropFirst().map { Int($0 - 48) }
            let date = ArticleCalendarDay(year: 2000 + numbers[0] * 10 + numbers[1], month: numbers[2] * 10 + numbers[3], day: numbers[4] * 10 + numbers[5])
            invalidDateSuffix = !date.isValid
            if date.isValid { value.shootingDate = date; value.dateCandidateState = .candidate }
        } else { invalidDateSuffix = false }
        content = value
    }
}
