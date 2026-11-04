import OSLog

public enum Diagnostics {
    private static let logger=Logger(subsystem:"com.yokochie.Hitotsuzuri",category:"failure")
    public static func failure(_ failure: PickerFailure) { logger.error("操作失敗: \(failure.rawValue, privacy: .public)") }
}
