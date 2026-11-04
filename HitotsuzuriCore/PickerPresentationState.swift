import Foundation
import Observation

public enum PickerRegion:String,CaseIterable,Sendable {case folders="フォルダ",albums="アルバム",photos="写真"}
public struct FolderRow:Identifiable,Equatable,Sendable {
    public let folder:LibraryFolder
    public let depth:Int
    public var id:String {folder.id}
}
@MainActor @Observable public final class PickerPresentationState {
    public var region:PickerRegion = .photos
    public var expanded=Set<String>()
    public private(set) var focus=[PickerRegion:String]()
    public init() {}
    public static func isCompact(_ width:Double)->Bool {width<=820}
    public func remember(_ id:String?,in region:PickerRegion) {focus[region]=id}
    public func restore(in region:PickerRegion,available:[String])->String? {
        if let previous=focus[region],available.contains(previous) {return previous}
        return available.first
    }
    public func toggleExpanded(_ id:String) {if !expanded.insert(id).inserted {expanded.remove(id)}}
    public func rows(_ folders:[LibraryFolder])->[FolderRow] {
        let byID=Dictionary(folders.map {($0.id,$0)},uniquingKeysWith: {first,_ in first})
        let children=Set(folders.flatMap(\.children))
        var visited=Set<String>(),result=[FolderRow]()
        func visit(_ id:String,_ depth:Int) {
            guard let folder=byID[id],visited.insert(id).inserted else {return}
            result.append(.init(folder:folder,depth:depth))
            if expanded.contains(id) {for child in folder.children {visit(child,depth+1)}}
        }
        let roots=folders.filter {!children.contains($0.id)}
        for folder in roots {visit(folder.id,0)}
        // 閉じた子は追加しない。根を持たない循環成分だけを防御的に表示する。
        var reachable=Set<String>()
        func mark(_ id:String) {guard reachable.insert(id).inserted,let f=byID[id] else {return}; for child in f.children {mark(child)}}
        for folder in roots {mark(folder.id)}
        for folder in folders where !reachable.contains(folder.id) {visit(folder.id,0)}
        return result
    }
}
