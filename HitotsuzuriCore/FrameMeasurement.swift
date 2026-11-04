import Foundation

public struct FrameMeasurement:Sendable {
    public private(set) var inputs=[UInt64:UInt64]()
    public private(set) var upperMilliseconds=[UInt64:Double]()
    public private(set) var rejected=0
    private let numerator:UInt32
    private let denominator:UInt32
    private var lastFrame:UInt64=0
    private var lastPositions:[Int]?
    public init(numerator:UInt32=1,denominator:UInt32=1) {self.numerator=numerator; self.denominator=denominator}
    public mutating func input(sequence:UInt64,ticks:UInt64,beforePositions:[Int],positions:[Int]) {
        guard let change=MeasurementTransition(before:beforePositions,after:positions),
              lastPositions==nil || lastPositions==change.before,
              sequence>0,ticks>0,inputs[sequence]==nil,sequence==UInt64(inputs.count+1) else {rejected += 1; return}
        inputs[sequence]=ticks; lastPositions=change.after
    }
    public mutating func input(sequence:UInt64,ticks:UInt64) {
        // 時刻だけの旧入口では選択変化が立証できない。
        rejected += 1
    }
    public mutating func frame(sequence:UInt64,ticks:UInt64,interval:UInt64,selectionMatches:Bool,calibrated:Bool) {
        guard let input=inputs[sequence],sequence>lastFrame,upperMilliseconds[sequence]==nil,ticks>=input,interval>0,selectionMatches,calibrated,denominator>0 else {rejected += 1; return}
        let upper=(Double(ticks-input)+Double(interval))*Double(numerator)/Double(denominator)/1_000_000
        guard upper.isFinite else {rejected += 1; return}
        upperMilliseconds[sequence]=upper; lastFrame=sequence
    }
    public var passed:Bool {inputs.count>=30 && upperMilliseconds.count==inputs.count && rejected==0 && Double(upperMilliseconds.values.filter {$0<=200}.count)/Double(inputs.count)>=0.95}
}
