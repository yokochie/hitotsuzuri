// 開発者専用の任意測定。画面フレームはメモリ内のOCR照合後に破棄する。
// 通常アプリから起動せず、OS許可も要求しない。判定本体は製品Coreで自動試験する。
import Foundation
import AppKit
import ScreenCaptureKit
import Vision
import CoreMedia
import Darwin
import HitotsuzuriCore

// SF Monoの斜線zeroがVisionでø(U+00F8)になる実測事象だけを補正する。
// 既知prefix・数値欄・完全な文法を満たすマーカー以外には適用しない。
func normalizedMeasurementMarker(_ raw:String)->String? {
    let tokens=raw.split(separator:" ")
    guard let prefix=tokens.first,["HZM2","HZS","HZC"].contains(String(prefix)),tokens.count>1 else {return nil}
    let fields=tokens.dropFirst().map {String($0).replacingOccurrences(of:"ø",with:"0")}
    guard fields.allSatisfy({!$0.isEmpty && $0.utf8.allSatisfy {(48...57).contains($0)}}) else {return nil}
    let marker=([String(prefix)]+fields).joined(separator:" ")
    if prefix=="HZM2" {return MeasurementStamp.parse(marker)==nil ? nil : marker}
    let values=fields.compactMap(UInt64.init)
    guard values.count==fields.count else {return nil}
    if prefix=="HZS" {
        guard values.count==2,(1...4).contains(values[0]),values[1]<=UInt64(Int.max) else {return nil}
    } else {
        guard values.count==1,values[0]<=4 else {return nil}
    }
    return marker
}
func normalizationSelfTest()throws {
    let cases:[(String,String?)]=[
        ("HZM2 1 100 0 1 2","HZM2 1 100 0 1 2"),
        ("HZS 1 0","HZS 1 0"),("HZC 0","HZC 0"),
        ("HZS 1 ø","HZS 1 0"),("HZC ø","HZC 0"),
        ("HZM2 1 1øø ø 1 2","HZM2 1 100 0 1 2"),
        ("HZS 1 O",nil),("HZC o",nil),("HZS 1 x",nil),
        ("HZSø 1 0",nil),("other 1 ø",nil),("ø HZC 0",nil),
        ("HZS 5 0",nil),("HZC 5",nil),("HZS 1 ø 2",nil),
        ("HZM2 0 100 0 1 2",nil),("HZM2 1 100 0 0",nil),
        ("HZM2 1 100 0 1",nil),("HZS 1 18446744073709551616",nil),
        ("HZC -0",nil),("HZC ０",nil)
    ]
    guard cases.allSatisfy({normalizedMeasurementMarker($0.0)==$0.1}) else {
        throw NSError(domain:"MeasurementNormalizationSelfTest",code:1)
    }
    let timing=diagnosticMilliseconds(input:100,ticks:2_400_100,interval:400_000,numerator:125,denominator:3)
    guard abs(timing.delta-100)<0.000001,abs(timing.interval-16.6666666667)<0.000001 else {
        throw NSError(domain:"MeasurementTimingDiagnosticSelfTest",code:1)
    }
    print("マーカー数値正規化自己試験: \(cases.count)件成功（画面取得なし）")
    print("時間内訳診断自己試験: 1件成功（画面取得なし）")
}
// 診断表示専用。採否・上限値の算出は既存FrameMeasurementだけが行う。
func diagnosticMilliseconds(input:UInt64,ticks:UInt64,interval:UInt64,numerator:UInt32,denominator:UInt32)->(delta:Double,interval:Double) {
    let scale=Double(numerator)/Double(denominator)/1_000_000
    return (Double(ticks-input)*scale,Double(interval)*scale)
}
func timebaseCalibration()->(Bool,mach_timebase_info_data_t) {
    var info=mach_timebase_info_data_t(); mach_timebase_info(&info)
    let before=mach_absolute_time(),uptime=ProcessInfo.processInfo.systemUptime,after=mach_absolute_time()
    let scale=Double(info.numer)/Double(info.denom)/1_000_000_000
    return (uptime>=Double(before)*scale-0.005 && uptime<=Double(after)*scale+0.005,info)
}
// 全可変状態はSCStreamへ渡す専用直列queueに限定。終了時の読み取りも同queueで行う。
final class FrameReceiver:NSObject,SCStreamOutput {
    let queue=DispatchQueue(label:"Hitotsuzuri.measurement")
    private var ledger:FrameMeasurement
    private let calibrated:Bool
    private var previousTicks:UInt64=0
    private var observedSequence:UInt64=0
    private var unmatched=0
    private let numerator:UInt32
    private let denominator:UInt32
    private var timingDetails=[UInt64:(delta:Double,interval:Double)]()
    private let diagnose:Bool
    private var diagnosis:String?
    init(calibrated:Bool,info:mach_timebase_info_data_t,diagnose:Bool=false) {self.calibrated=calibrated; self.diagnose=diagnose; numerator=info.numer; denominator=info.denom; ledger=FrameMeasurement(numerator:info.numer,denominator:info.denom)}
    var diagnosticResult:String? {queue.sync {diagnosis}}
    func stream(_ stream:SCStream,didOutputSampleBuffer sampleBuffer:CMSampleBuffer,of type:SCStreamOutputType) {
        if diagnose,diagnosis != nil {return}
        guard type == .screen,
              let attachments=CMSampleBufferGetSampleAttachmentsArray(sampleBuffer,createIfNecessary:false) as? [[SCStreamFrameInfo:Any]],
              let frame=attachments.first,
              (frame[.status] as? NSNumber)?.intValue==SCFrameStatus.complete.rawValue,
              let ticks=(frame[.displayTime] as? NSNumber)?.uint64Value,
              ticks>previousTicks,let pixels=sampleBuffer.imageBuffer else {return}
        let interval=previousTicks==0 ? 0 : ticks-previousTicks
        previousTicks=ticks
        autoreleasepool {
            let request=VNRecognizeTextRequest()
            request.recognitionLevel = .accurate; request.usesLanguageCorrection=false; request.recognitionLanguages=["en-US"]
            do {try VNImageRequestHandler(cvPixelBuffer:pixels,options:[:]).perform([request])} catch {
                if diagnose {diagnosis="単一フレーム診断：OCR実行失敗（内容は出力しません）"}
                unmatched += 1; return
            }
            let rawStrings=(request.results ?? []).compactMap {$0.topCandidates(1).first?.string}.map {$0.split(whereSeparator:{$0.isWhitespace}).joined(separator:" ")}
            if diagnose {diagnosis=Self.diagnose(rawStrings); return}
            let strings=rawStrings.map {normalizedMeasurementMarker($0) ?? $0}
            guard let marker=strings.first(where:{$0.hasPrefix("HZM2 ")}) else {
                if strings.contains(where:{$0.hasPrefix("HZM ")}) {unmatched += 1}
                return
            }
            guard let stamp=MeasurementStamp.parse(marker) else {unmatched += 1; return}
            let seq=stamp.sequence,input=stamp.inputTicks,positions=stamp.positions,count=positions.count
            guard seq>observedSequence else {return}
            guard seq==observedSequence+1,count==positions.count,count<=4,positions.allSatisfy({$0>0}) else {unmatched += 1; return}
            // 連番だけでは採用しない。同一フレームの実際の4枠と枚数を照合する。
            let sameFrame=strings.contains("HZC \(count)") && (0..<4).allSatisfy {slot in strings.contains("HZS \(slot+1) \(slot<positions.count ? positions[slot] : 0)")}
            guard sameFrame,interval>0,ticks<=mach_absolute_time() else {unmatched += 1; return}
            ledger.input(sequence:seq,ticks:input,beforePositions:stamp.beforePositions,positions:positions)
            ledger.frame(sequence:seq,ticks:ticks,interval:interval,selectionMatches:true,calibrated:calibrated)
            if ledger.upperMilliseconds[seq] != nil {
                timingDetails[seq]=diagnosticMilliseconds(input:input,ticks:ticks,interval:interval,numerator:numerator,denominator:denominator)
            }
            observedSequence=seq
        }
    }
    // 既知の測定prefixと数値以外は出力しない。OCRの全文・画像・写真名は保持しない。
    // 診断は合否判定へ流さず、厳密な既存parser/同一frame条件をそのまま調べる。
    static func diagnose(_ strings:[String])->String {
        var lines=["単一フレーム診断（合否判定なし）"]
        lines.append("HZ開始のOCR領域数 \(strings.filter {$0.hasPrefix("HZ")}.count)、旧/分離HZM prefix数 \(strings.filter {$0.hasPrefix("HZM ")}.count)")
        for prefix in ["HZM2","HZS","HZC"] {
            let candidates=strings.filter {$0.hasPrefix(prefix)}
            lines.append("\(prefix)候補 \(candidates.count)")
            for candidate in candidates {
                let tokens=candidate.split(separator:" ")
                let numeric=tokens.dropFirst().map {UInt64($0)}
                let oCount=candidate.filter {$0=="O" || $0=="o"}.count
                lines.append("\(prefix): token数 \(tokens.count)、全後続token数値 \(numeric.allSatisfy {$0 != nil})、O/o数 \(oCount)")
                // HZS/HZCの期待token数が合う行だけ、数値欄の誤認文字を符号位置で示す。
                // 自由なOCR文字列や結合された別領域の全文は表示しない。
                if (prefix=="HZS" && tokens.count==3) || (prefix=="HZC" && tokens.count==2) {
                    for (index,token) in tokens.dropFirst().enumerated() where UInt64(token)==nil {
                        let codes=token.unicodeScalars.prefix(8).map {String(format:"U+%04X",$0.value)}.joined(separator:" ")
                        lines.append("\(prefix)非数値欄\(index+1): 符号位置 \(codes)、scalar数 \(token.unicodeScalars.count)")
                    }
                }
                if prefix=="HZM2" {
                    if let stamp=MeasurementStamp.parse(candidate) {
                        let matches=strings.contains("HZC \(stamp.positions.count)") && (0..<4).allSatisfy {slot in strings.contains("HZS \(slot+1) \(slot<stamp.positions.count ? stamp.positions[slot] : 0)")}
                        lines.append("HZM2解析成功: seq \(stamp.sequence)、前 \(stamp.beforePositions)、後 \(stamp.positions)、同frame完全一致 \(matches)、初回seq1 \(stamp.sequence==1)")
                    } else {lines.append("HZM2解析失敗")}
                } else if numeric.allSatisfy({$0 != nil}), tokens.count==(prefix=="HZS" ? 3 : 2) {
                    lines.append("\(prefix)数値 \(numeric.compactMap {$0})")
                }
            }
        }
        let normalized=strings.map {normalizedMeasurementMarker($0) ?? $0}
        lines.append("既知数値補正の適用領域数 \(zip(strings,normalized).filter {$0 != $1}.count)")
        if let marker=normalized.first(where:{$0.hasPrefix("HZM2 ")}),let stamp=MeasurementStamp.parse(marker) {
            let matches=normalized.contains("HZC \(stamp.positions.count)") && (0..<4).allSatisfy {slot in normalized.contains("HZS \(slot+1) \(slot<stamp.positions.count ? stamp.positions[slot] : 0)")}
            lines.append("数値正規化後: seq \(stamp.sequence)、前 \(stamp.beforePositions)、後 \(stamp.positions)、同frame完全一致 \(matches)")
        }
        return lines.joined(separator:"\n")
    }
    func summary(expected:Int)->String {
        queue.sync {
            let complete=ledger.inputs.count==expected && ledger.upperMilliseconds.count==expected && unmatched==0 && ledger.rejected==0
            let result=complete && expected>=30 ? (ledger.passed ? "合格" : "未達") : "未確認（欠測・照合不成立または30操作未満）"
            let details=ledger.upperMilliseconds.keys.sorted().compactMap {seq -> String? in
                guard let upper=ledger.upperMilliseconds[seq],let timing=timingDetails[seq] else {return nil}
                return String(format:"seq %llu upperMs %.3f deltaMs %.3f intervalMs %.3f",seq,upper,timing.delta,timing.interval)
            }
            return (["操作数 \(ledger.inputs.count)、対応 \(ledger.upperMilliseconds.count)、不成立 \(unmatched+ledger.rejected)、200ms以内 \(ledger.upperMilliseconds.values.filter {$0<=200}.count)、結果 \(result)"]+details).joined(separator:"\n")
        }
    }
}
@main struct MeasureNative {
    @MainActor static func main() async throws {
        if CommandLine.arguments.contains("--self-test") {try normalizationSelfTest(); return}
        let (calibrated,info)=timebaseCalibration()
        print("時刻系校正: \(calibrated ? "一致" : "未確認")、numer \(info.numer)、denom \(info.denom)")
        let preflightOnly=CommandLine.arguments.contains("--preflight-only")
        let diagnose=CommandLine.arguments.contains("--diagnose")
        guard preflightOnly || diagnose || CommandLine.arguments.contains("--capture") else {return}
        let permitted=screenCapturePreflight()
        if preflightOnly {
            print("画面収録許可: \(permitted ? "確認済み" : "未確認")。画面列挙・フレーム取得は未実行。")
            return
        }
        guard calibrated,permitted else {print("未確認：画面収録許可または時刻系校正がありません。本人がシステム設定で確認してください。"); return}
        let expected=CommandLine.arguments.firstIndex(of:"--expected").flatMap {index in index+1<CommandLine.arguments.count ? Int(CommandLine.arguments[index+1]) : nil} ?? 30
        let content=try await SCShareableContent.excludingDesktopWindows(false,onScreenWindowsOnly:true)
        guard let window=content.windows.first(where:{$0.owningApplication?.bundleIdentifier=="com.yokochie.Hitotsuzuri" && $0.title=="ひとつづり"}) else {print("未確認：測定用ウィンドウがありません。"); return}
        let filter=SCContentFilter(desktopIndependentWindow:window),configuration=SCStreamConfiguration()
        configuration.width=Int(window.frame.width*2); configuration.height=Int(window.frame.height*2)
        configuration.minimumFrameInterval=CMTime(value:1,timescale:60); configuration.queueDepth=3; configuration.showsCursor=false; configuration.capturesAudio=false
        let receiver=FrameReceiver(calibrated:calibrated,info:info,diagnose:diagnose),stream=SCStream(filter:filter,configuration:configuration,delegate:nil)
        try stream.addStreamOutput(receiver,type:.screen,sampleHandlerQueue:receiver.queue)
        print(diagnose ? "単一フレーム診断を開始します。画像とOCR全文は保存しません。" : "測定を開始します。60秒内に指定回数の選択/解除を行い、最後の操作後は待機してください。")
        try await stream.startCapture()
        if diagnose {
            for _ in 0..<100 {
                if receiver.diagnosticResult != nil {break}
                try await Task.sleep(for:.milliseconds(100))
            }
        } else {try await Task.sleep(for:.seconds(60))}
        try await stream.stopCapture()
        if diagnose {print(receiver.diagnosticResult ?? "未確認：10秒内に完全フレームのOCRが完了しませんでした。"); return}
        print(receiver.summary(expected:expected))
    }
    @MainActor private static func screenCapturePreflight()->Bool {
        // AppKit/WindowServer接続を、権限照会とScreenCaptureKit利用より先に準備する。
        // preflight-onlyとcaptureが同じ初期化順を通り、許可要求は行わない。
        _=NSApplication.shared
        print("GUI初期化: 完了、main thread \(Thread.isMainThread)")
        return CGPreflightScreenCaptureAccess()
    }
}
