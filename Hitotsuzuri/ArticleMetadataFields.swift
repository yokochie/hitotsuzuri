import SwiftUI
import HitotsuzuriCore

struct ArticleMetadataFields:View {
    @Bindable var session:ArticleEditSession
    let focus:FocusState<String?>.Binding
    var body:some View {
        VStack(alignment:.leading,spacing:12) {
            Text("撮影情報").font(.title3)
            Text(stateText).accessibilityIdentifier("article-date-state")
            HStack(alignment:.top) {
                dateField("年",id:"article-year",value:session.metadataInput.year) {session.metadataInput.change(year:$0,month:session.metadataInput.month,day:session.metadataInput.day)}
                dateField("月",id:"article-month",value:session.metadataInput.month) {session.metadataInput.change(year:session.metadataInput.year,month:$0,day:session.metadataInput.day)}
                dateField("日",id:"article-day",value:session.metadataInput.day) {session.metadataInput.change(year:session.metadataInput.year,month:session.metadataInput.month,day:$0)}
            }
            if let error=session.metadataInput.validationMessage {Text(error).foregroundStyle(.red).fixedSize(horizontal:false,vertical:true).accessibilityIdentifier("article-date-error")}
            HStack {
                Button("日付を確認") {try? session.metadataInput.confirm()}.disabled(session.metadataInput.validationMessage != nil || session.metadataInput.year.isEmpty).focusable().focused(focus,equals:"article-date-confirm").accessibilityIdentifier("article-date-confirm").id("article-date-confirm")
                Button("日付を削除") {session.metadataInput.remove()}.focusable().focused(focus,equals:"article-date-remove").accessibilityIdentifier("article-date-remove").id("article-date-remove")
            }
            memo("場所",id:"article-location",value:$session.content.location)
            memo("機材",id:"article-equipment",value:$session.content.equipment)
            memo("フィルム",id:"article-film",value:$session.content.film)
            memo("人物名",id:"article-people",value:$session.content.people)
        }
    }
    private var stateText:String {
        switch session.metadataInput.candidateState {
        case .absent:"撮影日なし"
        case .candidate:"日付候補・未確認"
        case .confirmed:"確認済み"
        }
    }
    private func dateField(_ label:String,id:String,value:String,change:@escaping (String)->Void)->some View {
        VStack(alignment:.leading) {Text(label); TextField(label,text:Binding(get:{value},set:change)).textFieldStyle(.roundedBorder).accessibilityIdentifier(id).focused(focus,equals:id)}.id(id)
    }
    private func memo(_ label:String,id:String,value:Binding<String>)->some View {
        VStack(alignment:.leading) {Text(label); TextEditor(text:value).frame(height:80).border(.quaternary).accessibilityIdentifier(id).focused(focus,equals:id)}.id(id)
    }
}
