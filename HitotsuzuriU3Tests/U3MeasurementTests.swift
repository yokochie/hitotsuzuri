import XCTest
@testable import HitotsuzuriCore
final class U3MeasurementTests:XCTestCase {
    @MainActor func testMarkerRoundTripPreservesInitialAndResultState() {
        let m=NativeMeasurement(enabled:true); m.record(eventSeconds:ProcessInfo.processInfo.systemUptime,beforePositions:[4,2],positions:[4])
        XCTAssertEqual(m.stamp.flatMap {MeasurementStamp.parse($0.marker)},m.stamp)
        XCTAssertEqual(m.stamp?.beforePositions,[4,2])
    }
    func testMalformedAndLegacyMarkersCannotProveChanges() {
        for marker in ["HZM 1 1 0","HZM2 1 1 0 0","HZM2 1 1 1 1 2 2","HZM2 1 1 0 1 -2","HZM2 1 1 0 1 x","HZM2 1 1 0 1 2 9","HZM2 1 1 5 0","HZM2 0 1 0 1 2"] {XCTAssertNil(MeasurementStamp.parse(marker))}
    }
    @MainActor func testUnchangedAndRejectedActionsDoNotPoisonNextValidMeasurement() {
        let m=NativeMeasurement(enabled:true),time=ProcessInfo.processInfo.systemUptime
        m.record(eventSeconds:nil,beforePositions:[],positions:[])
        m.record(eventSeconds:time,beforePositions:[],positions:[1])
        m.record(eventSeconds:nil,beforePositions:[1],positions:[1])
        m.record(eventSeconds:time,beforePositions:[1],positions:[])
        XCTAssertFalse(m.unavailable); XCTAssertEqual(m.stamp?.sequence,2)
    }
    @MainActor func testUnobservedStateGapStopsMeasurementInsteadOfHidingMissingAction() {
        let m=NativeMeasurement(enabled:true),time=ProcessInfo.processInfo.systemUptime
        m.record(eventSeconds:time,beforePositions:[],positions:[1])
        m.record(eventSeconds:time,beforePositions:[2],positions:[])
        XCTAssertTrue(m.unavailable); XCTAssertEqual(m.stamp?.sequence,1)
        m.record(eventSeconds:time,beforePositions:[1],positions:[])
        XCTAssertEqual(m.stamp?.sequence,1)
    }
    @MainActor func testUnchangedProvenStatesCannotBecomeThirtySamples() {
        let native=NativeMeasurement(enabled:true); var frames=FrameMeasurement()
        for n in 1...30 {
            native.record(eventSeconds:ProcessInfo.processInfo.systemUptime,beforePositions:[],positions:[])
            frames.input(sequence:UInt64(n),ticks:1,beforePositions:[],positions:[])
            frames.frame(sequence:UInt64(n),ticks:2,interval:1,selectionMatches:true,calibrated:true)
        }
        XCTAssertNil(native.stamp); XCTAssertTrue(frames.inputs.isEmpty); XCTAssertFalse(frames.passed)
    }
    @MainActor func testFirstOperationCanBeDeselection() {
        let m=NativeMeasurement(enabled:true); m.record(eventSeconds:ProcessInfo.processInfo.systemUptime,beforePositions:[4,2],positions:[4])
        XCTAssertEqual(m.stamp?.sequence,1); XCTAssertEqual(m.stamp?.positions,[4])
    }
    @MainActor func testValidChangesCanReturnToPriorState() {
        let m=NativeMeasurement(enabled:true),time=ProcessInfo.processInfo.systemUptime
        m.record(eventSeconds:time,beforePositions:[1],positions:[])
        m.record(eventSeconds:time,beforePositions:[],positions:[1])
        XCTAssertEqual(m.stamp?.sequence,2); XCTAssertEqual(m.stamp?.positions,[1])
    }
    @MainActor func testDuplicateTransitionDoesNotAdvanceSequence() {
        let m=NativeMeasurement(enabled:true),time=ProcessInfo.processInfo.systemUptime
        m.record(eventSeconds:time,beforePositions:[],positions:[1]); let first=m.stamp
        m.record(eventSeconds:time,beforePositions:[],positions:[1])
        XCTAssertEqual(m.stamp,first)
        m.record(eventSeconds:time,beforePositions:[1],positions:[])
        XCTAssertEqual(m.stamp?.sequence,2)
    }
    @MainActor func testInvalidPositionsCannotCreateMarker() {
        let m=NativeMeasurement(enabled:true)
        m.record(eventSeconds:ProcessInfo.processInfo.systemUptime,beforePositions:[],positions:[0])
        XCTAssertNil(m.stamp)
        m.record(eventSeconds:ProcessInfo.processInfo.systemUptime,beforePositions:[1],positions:[1,1])
        XCTAssertNil(m.stamp)
    }
    func testFrameCannotAcceptUnprovenStateContinuity() {
        var m=FrameMeasurement()
        m.input(sequence:1,ticks:1,beforePositions:[],positions:[1])
        m.frame(sequence:1,ticks:2,interval:1,selectionMatches:true,calibrated:true)
        m.input(sequence:2,ticks:3,beforePositions:[9],positions:[9,2])
        m.frame(sequence:2,ticks:4,interval:1,selectionMatches:true,calibrated:true)
        XCTAssertNil(m.upperMilliseconds[2]); XCTAssertFalse(m.passed)
    }
    @MainActor func testRepeatedEmptyPositionsCannotQualifyThirtyOperations() {
        let native=NativeMeasurement(enabled:true); var frames=FrameMeasurement()
        for _ in 0..<30 {
            native.record(eventSeconds:ProcessInfo.processInfo.systemUptime,positions:[])
            if let s=native.stamp {frames.input(sequence:s.sequence,ticks:s.inputTicks); frames.frame(sequence:s.sequence,ticks:s.inputTicks+1,interval:1,selectionMatches:true,calibrated:true)}
        }
        XCTAssertNil(native.stamp); XCTAssertFalse(frames.passed)
    }
    func testLegacyTimestampOnlyInputsCannotQualifyThirtyOperations() {
        var m=FrameMeasurement()
        for n in 1...30 {m.input(sequence:UInt64(n),ticks:1); m.frame(sequence:UInt64(n),ticks:2,interval:1,selectionMatches:true,calibrated:true)}
        XCTAssertFalse(m.passed); XCTAssertTrue(m.upperMilliseconds.isEmpty)
    }
    @MainActor func testNormalMeasurementIsDisabled() {let m=NativeMeasurement(); m.record(eventSeconds:1,positions:[1]); XCTAssertNil(m.stamp); XCTAssertFalse(m.unavailable)}
    @MainActor func testMeasurementWithoutEventIsUnconfirmed() {let m=NativeMeasurement(enabled:true); m.record(eventSeconds:nil,beforePositions:[],positions:[1]); XCTAssertNil(m.stamp); XCTAssertTrue(m.unavailable)}
    @MainActor func testCurrentEventEquivalentTimeCreatesMarker() {let m=NativeMeasurement(enabled:true); m.record(eventSeconds:ProcessInfo.processInfo.systemUptime,beforePositions:[4],positions:[4,2]); XCTAssertEqual(m.stamp?.sequence,1); XCTAssertTrue(m.stamp?.marker.hasPrefix("HZM2 1 ") ?? false)}
    @MainActor func testInvalidEventTimeCannotBecomeMeasurement() {let m=NativeMeasurement(enabled:true); m.record(eventSeconds:1,beforePositions:[1],positions:[]); XCTAssertNil(m.stamp); XCTAssertTrue(m.unavailable)}
    func testFrameIntervalIsAddedAsUpperUncertainty() {var m=FrameMeasurement(); m.provenInput(sequence:1,ticks:1_000_000); m.frame(sequence:1,ticks:101_000_000,interval:16_000_000,selectionMatches:true,calibrated:true); XCTAssertEqual(m.upperMilliseconds[1],116)}
    func testMarkerOnlyCannotFinish() {var m=FrameMeasurement(); m.provenInput(sequence:1,ticks:1); m.frame(sequence:1,ticks:2,interval:1,selectionMatches:false,calibrated:true); XCTAssertTrue(m.upperMilliseconds.isEmpty); XCTAssertFalse(m.passed)}
    func testMismatchedTimebaseCannotFinish() {var m=FrameMeasurement(); m.provenInput(sequence:1,ticks:1); m.frame(sequence:1,ticks:2,interval:1,selectionMatches:true,calibrated:false); XCTAssertTrue(m.upperMilliseconds.isEmpty)}
    func testMissingInputAndOldSequenceCannotFinish() {var m=FrameMeasurement(); m.frame(sequence:2,ticks:2,interval:1,selectionMatches:true,calibrated:true); XCTAssertFalse(m.passed); XCTAssertTrue(m.upperMilliseconds.isEmpty)}
    func testNegativeTimeRejected() {var m=FrameMeasurement(); m.provenInput(sequence:1,ticks:10); m.frame(sequence:1,ticks:9,interval:1,selectionMatches:true,calibrated:true); XCTAssertTrue(m.upperMilliseconds.isEmpty)}
    func testMissingFramesCannotPassWithThirtyOtherSamples() {var m=FrameMeasurement(); for n in 1...31 {m.provenInput(sequence:UInt64(n),ticks:1); if n<31 {m.frame(sequence:UInt64(n),ticks:2,interval:1,selectionMatches:true,calibrated:true)}}; XCTAssertFalse(m.passed)}
    func testNinetyFivePercentThresholdAndTimebaseConversion() {
        var pass=FrameMeasurement(numerator:2,denominator:1),fail=FrameMeasurement()
        for n in 1...40 {let i=UInt64(n); pass.provenInput(sequence:i,ticks:1); pass.frame(sequence:i,ticks:n<=38 ? 50_000_001 : 200_000_001,interval:1,selectionMatches:true,calibrated:true); fail.provenInput(sequence:i,ticks:1); fail.frame(sequence:i,ticks:n<=37 ? 100_000_001 : 300_000_001,interval:1,selectionMatches:true,calibrated:true)}
        XCTAssertTrue(pass.passed); XCTAssertFalse(fail.passed)
    }
    func testOutOfOrderAndDuplicateDoNotOverwriteFirstFrame() {var m=FrameMeasurement(); m.provenInput(sequence:1,ticks:1); m.provenInput(sequence:2,ticks:1); m.frame(sequence:2,ticks:2,interval:1,selectionMatches:true,calibrated:true); m.frame(sequence:1,ticks:3,interval:1,selectionMatches:true,calibrated:true); XCTAssertNil(m.upperMilliseconds[1]); XCTAssertFalse(m.passed)}
}

private extension FrameMeasurement {
    mutating func provenInput(sequence:UInt64,ticks:UInt64) {
        input(sequence:sequence,ticks:ticks,beforePositions:sequence%2==1 ? [] : [1],positions:sequence%2==1 ? [1] : [])
    }
}
