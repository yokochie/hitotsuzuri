import SwiftUI
import HitotsuzuriCore

struct ArticleView: View {
    @Bindable var session: ArticleEditSession
    @Bindable var coordinator: ArticleAppCoordinator
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("写真選択へ戻る") { Task { _ = await coordinator.leave() } }.accessibilityIdentifier("article-back")
                Text("記事の下書き").font(.title2); Spacer()
                Text(session.stateMessage).accessibilityIdentifier("article-save-state")
                Button("保存") { Task { _ = await session.save() } }.keyboardShortcut("s").disabled(session.isSaving || coordinator.working).accessibilityIdentifier("article-save")
            }.padding()
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("記事タイトル", text: $session.content.title).textFieldStyle(.roundedBorder).accessibilityIdentifier("article-title")
                    field("導入文", text: $session.content.introduction, id: "article-introduction")
                    ForEach(0..<session.content.photoTexts.count, id: \.self) { index in
                        field("写真 \(index + 1) の文章", text: $session.content.photoTexts[index].text, id: "article-photo-\(index + 1)")
                    }
                    field("締めの文章", text: $session.content.closing, id: "article-closing")
                    Text("写真を取得できない場合も文章を保存・再開できます。").foregroundStyle(.secondary)
                    HStack {
                        Button("画像1枚の検証出力") { coordinator.probe() }.disabled(coordinator.working || session.isSaving).accessibilityIdentifier("article-probe")
                        if coordinator.working { ProgressView().controlSize(.small); Button("取り消す") { coordinator.cancelProbe() } }
                    }
                    Text(coordinator.message).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                }.padding().frame(maxWidth: 900)
            }
        }.frame(minWidth: 640, minHeight: 560)
    }
    private func field(_ label: String, text: Binding<String>, id: String) -> some View {
        VStack(alignment: .leading) { Text(label).font(.headline); TextEditor(text: text).frame(minHeight: 110).border(.quaternary).accessibilityIdentifier(id) }
    }
}
