import Foundation
import CryptoKit

/// 型タグ・長さ・順序を共有し、本文のUnicode/改行を正規化しない。
public enum ArticleFingerprint {
    public static func content(source: ArticleSource, content: ArticleContent) -> String {
        var writer = CanonicalWriter()
        writer.string("hitotsuzuri.article.content.v1")
        writer.source(source); writer.content(content)
        return digest(writer.data)
    }

    static func operation(kind: String, projectID: UUID, revision: Int?, source: ArticleSource, content: ArticleContent) -> String {
        var writer = CanonicalWriter()
        writer.string("hitotsuzuri.article.operation.v1"); writer.string(kind)
        writer.string(projectID.uuidString.lowercased()); writer.optionalInteger(revision)
        writer.source(source); writer.content(content)
        return digest(writer.data)
    }

    static func digest(_ bytes: Data) -> String { SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined() }
}

private struct CanonicalWriter {
    var data = Data()
    mutating func field(_ tag: UInt8, _ payload: Data) {
        data.append(tag)
        var length = UInt64(payload.count).bigEndian
        withUnsafeBytes(of: &length) { data.append(contentsOf: $0) }
        data.append(payload)
    }
    mutating func string(_ value: String) { field(1, Data(value.utf8)) }
    mutating func integer(_ value: Int) {
        var encoded = Int64(value).bigEndian
        withUnsafeBytes(of: &encoded) { field(2, Data($0)) }
    }
    mutating func optionalInteger(_ value: Int?) {
        if let value { integer(value) } else { field(0, Data()) }
    }
    mutating func source(_ value: ArticleSource) {
        string(value.selectionID.uuidString.lowercased()); string(value.albumID); string(value.albumTitle)
        integer(value.orderedAssetIDs.count)
        for id in value.orderedAssetIDs { string(id) }
        integer(Int((value.confirmedAt.timeIntervalSince1970 * 1000).rounded()))
        integer(value.selectionRevision)
    }
    mutating func content(_ value: ArticleContent) {
        string(value.title); string(value.introduction); integer(value.photoTexts.count)
        for photo in value.photoTexts { string(photo.assetID); string(photo.text) }
        string(value.closing)
        if let date = value.shootingDate { integer(date.year); integer(date.month); integer(date.day) }
        else { field(0, Data()) }
        string(value.dateCandidateState.rawValue)
        string(value.location); string(value.equipment); string(value.film); string(value.people)
    }
}
