import SwiftUI
import HitotsuzuriCore

struct PickerView: View {
    let workflow: SelectionWorkflow
    var body: some View { PickerContent(workflow:workflow,measurement:NativeMeasurement(enabled:ProcessInfo.processInfo.arguments.contains("--measure-native"))).task { await workflow.start() } }
}

