import Foundation

public struct RenderedArticle: Equatable, Sendable {
    public let projectID: UUID
    public let sourceFingerprint: String
    public let plainText: String
    public let markdown: String
    public let imagePaths: [String]
}

public struct ArticleProjectionContext: Sendable {
    public let projectID: UUID
    public init(projectID: UUID) throws {
        guard projectID != UUID(uuid: (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)) else { throw ArticleFailure.invalidInput }
        self.projectID = projectID
    }
    public func renderArticle(source: ArticleSource, content: ArticleContent) throws -> RenderedArticle {
        try content.validate(source: source)
        let paths=(1...4).map { String(format:"images/%02d.jpg",$0) }
        var plain:[String]=[], markdown:[String]=[]
        if !content.title.isEmpty { plain.append(content.title); markdown.append("# "+escape(content.title)) }
        if !content.introduction.isEmpty { plain.append(content.introduction); markdown.append(escape(content.introduction)) }
        for (index,photo) in content.photoTexts.enumerated() {
            plain.append("写真\(index+1)"+(photo.text.isEmpty ? "" : "\n"+photo.text))
            markdown.append("![写真\(index+1)](\(paths[index]))"+(photo.text.isEmpty ? "" : "\n\n"+escape(photo.text)))
        }
        if !content.closing.isEmpty { plain.append(content.closing); markdown.append(escape(content.closing)) }
        let memo=Self.shootingMemo(content)
        if !memo.isEmpty { plain.append("撮影メモ\n"+memo.joined(separator:"\n")); markdown.append("## 撮影メモ\n\n"+memo.map(escape).joined(separator:"  \n")) }
        return RenderedArticle(projectID: projectID, sourceFingerprint: ArticleFingerprint.content(source: source, content: content), plainText: plain.joined(separator:"\n\n"), markdown: markdown.joined(separator:"\n\n"), imagePaths: paths)
    }
    public static func shootingMemo(_ content: ArticleContent) -> [String] {
        var values:[String]=[]
        if let date=content.shootingDate {
            let label=content.dateCandidateState == .candidate ? "撮影日（未確認）" : "撮影日"
            values.append(label+String(format:"：%04d-%02d-%02d",date.year,date.month,date.day))
        }
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
