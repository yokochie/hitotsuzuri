import SwiftUI
import HitotsuzuriCore

@main
struct HitotsuzuriApp: App {
    @State private var workflow: SelectionWorkflow
    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-test-fixture") {
            _workflow=State(initialValue:DebugFixture.makeWorkflow()); return
        }
        #endif
        let directory=(try? SelectionPersistence.applicationDirectory()) ?? URL(fileURLWithPath:NSHomeDirectory()).appendingPathComponent("Library/Application Support/Hitotsuzuri")
        _workflow=State(initialValue:SelectionWorkflow(library:PhotoLibraryAccess(),images:LocalImageAccess(),store:SelectionPersistence(directory:directory)))
    }
    var body: some Scene { Window("ひとつづり",id:"picker") { PickerView(workflow:workflow) }.defaultSize(width:1280,height:800).windowResizability(.contentMinSize) }
}

