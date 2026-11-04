import Foundation
import AppKit
import Observation
import Darwin

// 表示位置の前後差の証拠。選択可否を決めず、1回の採用済み追加/解除かだけ確認する。
public struct MeasurementTransition:Equatable,Sendable {
    public let before:[Int]
    public let after:[Int]
    public init?(before:[Int],after:[Int]) {
        guard before.count<=4,after.count<=4,Set(before).count==before.count,Set(after).count==after.count,
              (before+after).allSatisfy({$0>0}),abs(before.count-after.count)==1,
              Set(before).symmetricDifference(Set(after)).count==1 else {return nil}
        let commonBefore=before.filter {after.contains($0)},commonAfter=after.filter {before.contains($0)}
        guard commonBefore==commonAfter else {return nil}
        self.before=before; self.after=after
    }
}
public struct MeasurementStamp:Equatable,Sendable {
    public let sequence:UInt64
    public let inputTicks:UInt64
    public let transition:MeasurementTransition
    public var beforePositions:[Int] {transition.before}
    public var positions:[Int] {transition.after}
    public var marker:String {"HZM2 \(sequence) \(inputTicks) \(beforePositions.count) \(positions.count) "+(beforePositions+positions).map(String.init).joined(separator:" ")}
    public static func parse(_ marker:String)->Self? {
        let tokens=marker.split(separator:" ")
        guard tokens.first=="HZM2",tokens.count>=5 else {return nil}
        let values=tokens.dropFirst().map {UInt64($0)}
        guard values.allSatisfy({$0 != nil}) else {return nil}
        let numbers=values.compactMap {$0}
        guard numbers[0]>0,numbers[1]>0,numbers[2]<=4,numbers[3]<=4,numbers.count==4+Int(numbers[2]+numbers[3]),
              numbers.dropFirst(4).allSatisfy({$0<=UInt64(Int.max)}) else {return nil}
        let positions=numbers.dropFirst(4).map(Int.init),split=Int(numbers[2])
        guard let change=MeasurementTransition(before:Array(positions.prefix(split)),after:Array(positions.dropFirst(split))) else {return nil}
        return .init(sequence:numbers[0],inputTicks:numbers[1],transition:change)
    }
}
@MainActor @Observable public final class NativeMeasurement {
    public let enabled:Bool
    public private(set) var stamp:MeasurementStamp?
    public private(set) var unavailable=false
    public init(enabled:Bool=false) {self.enabled=enabled}
    // 前状態の証拠がない旧入口は、測定数として認定しない。
    public func record(eventSeconds:Double?,positions:[Int]) {if enabled {unavailable=true}}
    public func record(eventSeconds:Double?,beforePositions:[Int],positions:[Int]) {
        guard enabled,!unavailable,let change=MeasurementTransition(before:beforePositions,after:positions) else {return}
        if stamp?.transition==change {return} // 同じ入力の再通知で連番を増やさない。
        if let previous=stamp,previous.positions != beforePositions {unavailable=true; return}
        guard let seconds=eventSeconds,seconds.isFinite,seconds>0 else {unavailable=true; return}
        var info=mach_timebase_info_data_t(); mach_timebase_info(&info)
        let ticks=seconds*1_000_000_000*Double(info.denom)/Double(info.numer)
        let current=Double(mach_absolute_time())
        guard ticks>=0,ticks<Double(UInt64.max),abs(current-ticks)*Double(info.numer)/Double(info.denom)<5_000_000_000 else {unavailable=true; return}
        stamp = .init(sequence:(stamp?.sequence ?? 0)+1,inputTicks:UInt64(ticks),transition:change)
    }
}
