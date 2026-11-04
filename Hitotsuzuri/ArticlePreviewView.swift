import SwiftUI
import HitotsuzuriCore

struct ArticlePreviewView:View {
    let content:ArticleContent
    let rendered:RenderedArticle
    let previews:ArticlePhotoPreviews?
    var body:some View {
        VStack(alignment:.leading,spacing:20) {
            Text("内容のプレビューです。note上の最終表示とは異なる場合があります。").font(.caption).foregroundStyle(.secondary)
            Text(content.title.isEmpty ? "無題の記事" : content.title).font(.title).accessibilityIdentifier("article-rendered-title")
            if !content.introduction.isEmpty {Text(content.introduction)}
            ForEach(Array(content.photoTexts.enumerated()),id:\.element.assetID) {index,photo in
                VStack(alignment:.leading,spacing:8) {
                    Text("写真 \(index+1)").font(.headline)
                    if case .ready(let buffer)=previews?.states[photo.assetID], let image=buffer.displayImage {Image(nsImage:image).resizable().scaledToFit().frame(maxHeight:480)}
                    else {Text(previews?.states[photo.assetID]?.message ?? "画像の取得待ち").foregroundStyle(.secondary)}
                    if !photo.text.isEmpty {Text(photo.text)}
                }
            }
            if !content.closing.isEmpty {Text(content.closing)}
            let memo=ArticleProjectionContext.shootingMemo(content)
            if !memo.isEmpty {Text("撮影メモ").font(.headline); ForEach(Array(memo.enumerated()),id:\.offset) {_,line in Text(line)}}
        }.frame(maxWidth:.infinity,alignment:.leading).textSelection(.enabled)
    }
}
