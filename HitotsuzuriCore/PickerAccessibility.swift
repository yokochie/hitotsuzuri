import Foundation

public struct PhotoSemantics:Equatable,Sendable {
    public let label:String
    public let value:String
    public let hint:String
    public init(position:Int,selectedIndex:Int?,available:Bool,failure:PickerFailure?) {
        label="写真 \(position)"
        value=selectedIndex.map {"選択済み、選択順 \($0+1)"} ?? "未選択"
        hint=failure?.message ?? (available ? "Spaceで選択・解除。矢印で移動、Tabで領域を退出。" : "画像を読み込み中です。選択は画像取得後に可能です。")
    }
    public static func slotLabel(slot:Int,position:Int?)->String {"選択枠 \(slot+1)、"+(position.map {"写真 \($0)"} ?? "未選択")}
}
public enum GridDirection:Sendable {case left,right,up,down,tab,backtab}
public enum GridDestination:Equatable,Sendable {case photo(String),previousRegion,confirmation}
public enum GridNavigation {
    public static func destination(_ direction:GridDirection,current:String?,ids:[String],columns:Int)->GridDestination {
        if direction == .tab {return .confirmation}
        if direction == .backtab {return .previousRegion}
        guard !ids.isEmpty else {return .previousRegion}
        let index=current.flatMap {ids.firstIndex(of:$0)} ?? 0
        let delta:Int
        switch direction {case .left:delta = -1; case .right:delta=1; case .up:delta = -max(1,columns); case .down:delta=max(1,columns); default:delta=0}
        return .photo(ids[min(ids.count-1,max(0,index+delta))])
    }
}
