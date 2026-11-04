import Foundation
import CryptoKit

public enum PersistenceCheckpoint: Sendable { case beforeBackup, afterBackup, beforeReplace }

public actor SelectionPersistence: SelectionStoring {
    private let directory: URL
    private let limit=1024*1024
    private let checkpoint: @Sendable (PersistenceCheckpoint,URL) throws -> Void
    public init(directory: URL, checkpoint: @escaping @Sendable (PersistenceCheckpoint,URL) throws ->Void = {_,_ in}) { self.directory=directory; self.checkpoint=checkpoint }
    public static func applicationDirectory() throws -> URL {
        try FileManager.default.url(for:.applicationSupportDirectory,in:.userDomainMask,appropriateFor:nil,create:true).appendingPathComponent("Hitotsuzuri",isDirectory:true)
    }
    public func loadSettings() -> StoredValue<TargetFolderSettings> {
        let value: StoredValue<TargetFolderSettings> = read("settings.json",as:TargetFolderSettings.self)
        if case .valid(let settings)=value, !settings.isValid { return .failure(.corruptData) }
        return value
    }
    public func saveSettings(_ settings: TargetFolderSettings) throws {
        guard settings.isValid else { throw PickerFailure.corruptData }
        if case .failure(let failure)=loadSettings() { throw failure }
        try write(settings,name:"settings.json")
    }
    public func loadSelection() -> StoredValue<CommittedSelection> {
        let value: StoredValue<CommittedSelection> = read("selection.json",as:CommittedSelection.self)
        if case .valid(let selection)=value, !selection.isValid { return .failure(.corruptData) }
        return value
    }
    public func saveSelection(_ selection: CommittedSelection) throws {
        guard selection.isValid else { throw PickerFailure.corruptData }
        if case .failure(let failure)=loadSelection() { throw failure }
        try write(selection,name:"selection.json")
    }
    // 通常保存と意図を分ける。起動・設定保存からは呼び出さない。
    public func confirmSelection(_ selection: CommittedSelection) async throws {
        guard selection.isValid else { throw PickerFailure.corruptData }
        switch loadSelection() {
        case .missing, .valid: try saveSelection(selection)
        case .failure(let failure):
            guard failure == .corruptData else { throw failure }
            do {
                try checkDirectory(directory,create:false)
                let original=directory.appendingPathComponent("selection.json")
                let bytes=try boundedBytes(original)
                // 読込と回復開始の間に版や内容が変化していても破損扱いしない。
                let current:StoredValue<CommittedSelection> = decode(bytes,as:CommittedSelection.self)
                switch current {
                case .valid(let value): guard !value.isValid else {throw PickerFailure.ioFailure}
                case .failure(.corruptData): break
                case .failure(let failure): throw failure
                case .missing: throw PickerFailure.ioFailure
                }
                let quarantine=directory.appendingPathComponent("quarantine",isDirectory:true)
                try checkDirectory(quarantine,create:true)
                let hash=SHA256.hash(data:bytes).map {String(format:"%02x",$0)}.joined()
                let backup=quarantine.appendingPathComponent("selection-"+hash+".json")
                try checkpoint(.beforeBackup,original)
                try checkDirectory(quarantine,create:false)
                if !exists(backup) {
                    // 排他作成。既存の退避を上書きしない。
                    try bytes.write(to:backup,options:.withoutOverwriting)
                }
                guard try boundedBytes(backup)==bytes else { throw PickerFailure.ioFailure }
                try checkpoint(.afterBackup,original)
                let replacement=try encoded(selection)
                try checkpoint(.beforeReplace,original)
                try checkDirectory(directory,create:false)
                try checkDirectory(quarantine,create:false)
                guard try boundedBytes(backup)==bytes else {throw PickerFailure.ioFailure}
                guard try boundedBytes(original)==bytes else { throw PickerFailure.ioFailure }
                try replacement.write(to:original,options:.atomic)
            } catch let failure as PickerFailure { throw failure }
            catch { throw PickerFailure.ioFailure }
        }
    }
    private func read<T: Decodable & Sendable>(_ name: String, as: T.Type) -> StoredValue<T> {
        let url=directory.appendingPathComponent(name)
        guard exists(url) else { return .missing }
        do {
            try checkDirectory(directory,create:false)
            let data=try boundedBytes(url)
            return decode(data,as:T.self)
        } catch let failure as PickerFailure { return .failure(failure) }
        catch is DecodingError { return .failure(.corruptData) }
        catch { return .failure(.ioFailure) }
    }
    private func decode<T:Decodable & Sendable>(_ data:Data,as:T.Type)->StoredValue<T> {
        guard let header=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any],let version=header["schemaVersion"] as? Int else {return .failure(.corruptData)}
        guard version==1 else {return .failure(.unsupportedVersion)}
        let decoder=JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        do {return .valid(try decoder.decode(T.self,from:data))} catch {return .failure(.corruptData)}
    }
    private func write<T: Encodable & Decodable & Sendable>(_ value: T, name: String) throws {
        switch read(name,as:T.self) { case .failure(let f): throw f; default: break }
        do {
            try checkDirectory(directory,create:true)
            let data=try encoded(value)
            try data.write(to:directory.appendingPathComponent(name),options:.atomic)
        } catch let f as PickerFailure { throw f }
        catch { throw PickerFailure.ioFailure }
    }
    private func encoded<T:Encodable>(_ value:T) throws ->Data {
        let encoder=JSONEncoder(); encoder.dateEncodingStrategy = .iso8601; encoder.outputFormatting=[.sortedKeys]
        let data=try encoder.encode(value)
        guard data.count<=limit else {throw PickerFailure.corruptData}; return data
    }
    private func exists(_ url:URL)->Bool {
        FileManager.default.fileExists(atPath:url.path) || (try? url.resourceValues(forKeys:[.isSymbolicLinkKey]).isSymbolicLink)==true
    }
    private func boundedBytes(_ url:URL)throws ->Data {
        try checkRegular(url)
        let size=try url.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? limit+1
        guard size<=limit else {throw PickerFailure.oversizedData}
        let data=try Data(contentsOf:url)
        guard data.count<=limit else {throw PickerFailure.oversizedData}; return data
    }
    private func checkDirectory(_ url:URL,create:Bool)throws {
        if !exists(url),create {try FileManager.default.createDirectory(at:url,withIntermediateDirectories:true)}
        let values=try url.resourceValues(forKeys:[.isDirectoryKey,.isSymbolicLinkKey])
        guard values.isDirectory==true,values.isSymbolicLink != true else {throw PickerFailure.ioFailure}
    }
    private func checkRegular(_ url: URL) throws {
        let values=try url.resourceValues(forKeys:[.isRegularFileKey,.isSymbolicLinkKey])
        guard values.isRegularFile==true, values.isSymbolicLink != true else { throw PickerFailure.ioFailure }
    }
}


