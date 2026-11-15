import Foundation

public struct ArticleRenderedContent: Equatable, Sendable {
    public let title: String
    public let introduction: String
    public let photoTexts: [ArticlePhotoText]
    public let closing: String
    public let shootingMemo: [String]
}

public struct RenderedArticle: Equatable, Sendable {
    public let projectID: UUID
    public let sourceFingerprint: String
    public let plainText: String
    public let markdown: String
    public let imagePaths: [String]
    public let content: ArticleRenderedContent
}

enum ArticleProjectionFormat: Int {
    case legacy = 1
    case placeholder = 2
}

public struct ArticleProjectionContext: Sendable {
    public let projectID: UUID
    public init(projectID: UUID) throws {
        guard projectID != UUID(uuid: (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)) else { throw ArticleFailure.invalidInput }
        self.projectID = projectID
    }
    public func renderArticle(source: ArticleSource, content: ArticleContent) throws -> RenderedArticle {
        try renderArticle(source: source, content: content, format: .placeholder)
    }
    func renderArticle(source: ArticleSource, content: ArticleContent, format: ArticleProjectionFormat) throws -> RenderedArticle {
        try content.validate(source: source)
        let display = displayContent(content, format: format)
        let paths = ArticleExportLayout.imagePaths
        var plain:[String]=[], markdown:[String]=[]
        if !display.title.isEmpty { plain.append(display.title); markdown.append("# "+escape(display.title)) }
        if !display.introduction.isEmpty { plain.append(display.introduction); markdown.append(escape(display.introduction)) }
        for (index,photo) in display.photoTexts.enumerated() {
            plain.append("写真\(index+1)"+(photo.text.isEmpty ? "" : "\n"+photo.text))
            markdown.append("![写真\(index+1)](\(paths[index]))"+(photo.text.isEmpty ? "" : "\n\n"+escape(photo.text)))
        }
        if !display.closing.isEmpty { plain.append(display.closing); markdown.append(escape(display.closing)) }
        let memo = display.shootingMemo
        if !memo.isEmpty {
            let section = format == .legacy ? "撮影メモ" : "撮影情報"
            plain.append(section+"\n"+memo.joined(separator:"\n"))
            markdown.append("## "+section+"\n\n"+memo.map(escape).joined(separator:"  \n"))
        }
        return RenderedArticle(projectID: projectID, sourceFingerprint: ArticleFingerprint.content(source: source, content: content), plainText: plain.joined(separator:"\n\n"), markdown: markdown.joined(separator:"\n\n"), imagePaths: paths, content: display)
    }
    private func displayContent(_ content: ArticleContent, format: ArticleProjectionFormat) -> ArticleRenderedContent {
        let memo = Self.shootingMemo(content)
        switch format {
        case .legacy:
            return ArticleRenderedContent(title: content.title, introduction: content.introduction,
                                          photoTexts: content.photoTexts, closing: content.closing,
                                          shootingMemo: memo + legacyMetadata(content))
        case .placeholder:
            let photos = content.photoTexts.enumerated().map { index, photo in
                ArticlePhotoText(assetID: photo.assetID, text: "【ダミー】写真\(index + 1)の文章です。")
            }
            return ArticleRenderedContent(title: content.title, introduction: "【ダミー】導入文です。",
                                          photoTexts: photos, closing: "【ダミー】締めの文章です。", shootingMemo: memo)
        }
    }
    public static func shootingMemo(_ content: ArticleContent) -> [String] {
        guard let date = content.shootingDate else { return [] }
        let label = content.dateCandidateState == .candidate ? "撮影日（未確認）" : "撮影日"
        return [label + String(format:"：%04d-%02d-%02d", date.year, date.month, date.day)]
    }
    private func legacyMetadata(_ content: ArticleContent) -> [String] {
        var values: [String] = []
        for (label,value) in [("場所",content.location),("機材",content.equipment),("フィルム",content.film),("人物名",content.people)] {
            if !value.unicodeScalars.allSatisfy({ CharacterSet.whitespacesAndNewlines.contains($0) }) { values.append(label+"："+value) }
        }
        return values
    }
    private func escape(_ value:String) ->String {
        var result=""; result.reserveCapacity(value.utf8.count)
        for scalar in value.unicodeScalars {
            switch scalar {
            case "&":result += "&amp;"
            case "<":result += "&lt;"
            case ">":result += "&gt;"
            case "\n":result += "  \n"
            default:
                if "\\`*_{}[]()#+-.!|~".unicodeScalars.contains(scalar) { result += "\\" }
                result.unicodeScalars.append(scalar)
            }
        }
        return result
    }
}
