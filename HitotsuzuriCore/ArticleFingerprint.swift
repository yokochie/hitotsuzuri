import Foundation
import CryptoKit

/// 型タグ・長さ・順序を共有し、本文のUnicode/改行を正規化しない。
public enum ArticleFingerprint {
    public static func content(source: ArticleSource, content: ArticleContent) -> String {
        digest(canonicalBytes(source:source,content:content))
    }
    static func canonicalBytes(source:ArticleSource,content:ArticleContent) ->Data {
        var writer = CanonicalWriter()
        writer.string("hitotsuzuri.article.content.v1")
        writer.source(source); writer.content(content)
        return writer.data
    }

    static func operation(kind: String, projectID: UUID, revision: Int?, source: ArticleSource, content: ArticleContent) -> String {
        var writer = CanonicalWriter()
        writer.string("hitotsuzuri.article.operation.v1"); writer.string(kind)
        writer.string(projectID.uuidString.lowercased()); writer.optionalInteger(revision)
        writer.source(source); writer.content(content)
        return digest(writer.data)
    }

    static func digest(_ bytes: Data) -> String { SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined() }

    static func association(projectID: UUID, expected: SavedArticle, source: ArticleSource) -> String {
        var writer = CanonicalWriter()
        writer.string("hitotsuzuri.article.operation.v1"); writer.string("associate")
        writer.string(projectID.uuidString.lowercased()); writer.integer(expected.savedRevision)
        writer.source(source)
        return digest(writer.data)
    }
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
        string("source")
        named("selectionID",value.selectionID.uuidString.lowercased()); named("albumID",value.albumID); named("albumTitle",value.albumTitle)
        string("orderedAssetIDs"); integer(value.orderedAssetIDs.count)
        for id in value.orderedAssetIDs { string(id) }
        string("confirmedAtUTCms"); integer(Int((value.confirmedAt.timeIntervalSince1970 * 1000).rounded()))
        string("selectionRevision"); integer(value.selectionRevision)
    }
    mutating func content(_ value: ArticleContent) {
        string("content")
        named("title",value.title); named("introduction",value.introduction); string("photoTexts"); integer(value.photoTexts.count)
        for photo in value.photoTexts { named("assetID",photo.assetID); named("text",photo.text) }
        named("closing",value.closing); string("shootingDate")
        if let date = value.shootingDate { string("year"); integer(date.year); string("month"); integer(date.month); string("day"); integer(date.day) }
        else { field(0, Data()) }
        named("dateCandidateState",value.dateCandidateState.rawValue)
        named("location",value.location); named("equipment",value.equipment); named("film",value.film); named("people",value.people)
    }
    mutating func named(_ name:String,_ value:String) {string(name); string(value)}
}
