import SwiftUI
import HitotsuzuriCore

@main
struct HitotsuzuriApp: App {
    @State private var workflow: SelectionWorkflow
    @State private var articles: ArticleAppCoordinator
    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--article-test-fixture") {
            let fixture = DebugFixture.makeArticles()
            _workflow = State(initialValue: fixture.0); _articles = State(initialValue: fixture.1); return
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-test-fixture") {
            let fixture = DebugFixture.makePickerWithArticles()
            _workflow=State(initialValue:fixture.0); _articles=State(initialValue:fixture.1); return
        }
        #endif
        let directory=(try? SelectionPersistence.applicationDirectory()) ?? URL(fileURLWithPath:NSHomeDirectory()).appendingPathComponent("Library/Application Support/Hitotsuzuri")
        let store = SelectionPersistence(directory:directory)
        _workflow=State(initialValue:SelectionWorkflow(library:PhotoLibraryAccess(),images:LocalImageAccess(),store:store))
        _articles=State(initialValue:ArticleAppCoordinator(selections:store,directory:directory))
    }
    var body: some Scene { Window("ひとつづり",id:"picker") { PickerView(workflow:workflow,articles:articles) }.defaultSize(width:1280,height:800).windowResizability(.contentMinSize).commands {
        CommandMenu("記事") {
            Button("選択した写真の記事を開く") {Task {await articles.openArticle()}}.keyboardShortcut("n")
            Button("保存した下書きを開く") {Task {await articles.openSavedArticle()}}
        }
    } }
}

