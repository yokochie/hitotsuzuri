import XCTest
@testable import HitotsuzuriCore

final class ArticleProjectionTests: XCTestCase {
    @MainActor func testChoosingEditorInvalidatesLateProjectionSuccessAndFailure() async throws {
        for failure in [nil,ArticleFailure.ioFailure] {
            let gate=DraftProjectionGate(), h=DraftHarness.make(projector:{context,source,content in
                let result=try await gate.project(context,source:source,content:content)
                if let failure {throw failure}; return result
            })
            _=try await h.savedSession(); let task=Task {await h.presentation.showPreview()}
            guard await draftWaitUntil({gate.waiting}) else {await task.value; return XCTFail("投影を開始")}
            h.presentation.showEditor(); gate.release(); await task.value
            XCTAssertEqual(h.presentation.mode,.editing); XCTAssertNil(h.presentation.rendered)
            XCTAssertNil(h.presentation.failure); XCTAssertFalse(h.presentation.isProjecting)
        }
    }
    @MainActor func testOldProjectionCannotUnlockAnotherPhysicalProjection() async throws {
        let gate=DraftProjectionGate(), h=DraftHarness.make(projector:{context,source,content in try await gate.project(context,source:source,content:content)})
        _=try await h.savedSession(); let old=Task {await h.presentation.showPreview()}
        guard await draftWaitUntil({gate.waiting}) else {await old.value; return XCTFail("投影を開始")}
        h.presentation.showEditor(); await h.presentation.showPreview()
        XCTAssertEqual(gate.invocations,1); XCTAssertTrue(h.presentation.isProjecting)
        gate.release(); await old.value
        let next=Task {await h.presentation.showPreview()}
        guard await draftWaitUntil({gate.waiting}) else {await next.value; return XCTFail("再投影を開始")}
        XCTAssertTrue(h.presentation.isProjecting); XCTAssertEqual(gate.invocations,2)
        gate.release(); await next.value
        XCTAssertFalse(h.presentation.isProjecting); XCTAssertEqual(h.presentation.mode,.preview)
    }
    @MainActor func testCanonicallyEquivalentByteChangeRejectsOldProjection() async throws {
        let gate=DraftProjectionGate(), h=DraftHarness.make(projector:{context,source,content in try await gate.project(context,source:source,content:content)})
        let session=try await h.savedSession(); session.content.title="e\u{301}"
        let task=Task {await h.presentation.showPreview()}
        guard await draftWaitUntil({gate.waiting}) else {await task.value; return XCTFail("投影を開始")}
        session.content.title="\u{e9}"; gate.release(); await task.value
        XCTAssertEqual(h.presentation.mode,.editing); XCTAssertNil(h.presentation.rendered)
        XCTAssertEqual(Array(session.content.title.utf8),[0xc3,0xa9])
    }
    @MainActor func testPreviewUsesCurrentInputWithoutSaving() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession(), saved=session.saved
        session.content.title="現在入力"
        await h.presentation.showPreview()
        XCTAssertEqual(h.presentation.mode,.preview)
        XCTAssertTrue(h.presentation.rendered?.plainText.contains("現在入力") == true)
        XCTAssertEqual(session.saved,saved); XCTAssertTrue(session.isDirty)
    }
    @MainActor func testStaleProjectionClearsLoadingAndCanBeRequestedAgain() async throws {
        let gate=DraftProjectionGate()
        let h=DraftHarness.make(projector:{ context,source,content in try await gate.project(context,source:source,content:content) })
        let session=try await h.savedSession()
        let task=Task { await h.presentation.showPreview() }
        guard await draftWaitUntil({ gate.waiting }) else { await task.value; return XCTFail("投影を開始") }
        session.content.title="後続入力"; gate.release(); await task.value
        XCTAssertFalse(h.presentation.isProjecting); XCTAssertEqual(h.presentation.mode,.editing)
        XCTAssertNil(h.presentation.rendered); XCTAssertTrue(h.presentation.message?.contains("内容が変わった") == true)
        let retry=Task { await h.presentation.showPreview() }
        guard await draftWaitUntil({ gate.waiting }) else { await retry.value; return XCTFail("再要求可能") }
        gate.release(); await retry.value
        XCTAssertEqual(h.presentation.mode,.preview); XCTAssertTrue(h.presentation.rendered?.plainText.contains("後続入力") == true)
    }
    private func render(_ modify: (inout ArticleContent) -> Void = { _ in }) throws -> RenderedArticle {
        let source = try DraftFixtures.source(); var value = ArticleContent(source: source); modify(&value)
        return try ArticleProjectionContext(projectID: UUID()).renderArticle(source: source, content: value)
    }
    func testFixedFourReferencesAndNumberOrder() throws {
        let result = try render { $0.photoTexts = $0.photoTexts.enumerated().map { ArticlePhotoText(assetID: $0.element.assetID, text: "本文\($0.offset+1)") } }
        XCTAssertEqual(result.imagePaths, ["images/01.jpg","images/02.jpg","images/03.jpg","images/04.jpg"])
        for index in 1...4 {
            XCTAssertTrue(result.plainText.contains("写真\(index)\n【ダミー】写真\(index)の文章です。"))
        }
        XCTAssertFalse(result.plainText.contains("images/"))
    }
    func testLegacyAndEmptyDraftsProduceIdenticalPlaceholderText() throws {
        let fresh = try render { $0.title = "題" }
        let legacy = try render {
            $0.title = "題"
            $0.introduction = "旧導入"
            $0.closing = "旧締め"
            for index in $0.photoTexts.indices { $0.photoTexts[index].text = "旧写真文\(index)" }
            $0.location = "旧場所"; $0.equipment = "旧機材"; $0.film = "旧フィルム"; $0.people = "旧人物"
        }
        XCTAssertEqual(legacy.plainText, fresh.plainText)
        XCTAssertEqual(legacy.markdown, fresh.markdown)
        let expected = ["題", "【ダミー】導入文です。"] +
            (1...4).map { "写真\($0)\n【ダミー】写真\($0)の文章です。" } +
            ["【ダミー】締めの文章です。"]
        XCTAssertEqual(fresh.plainText, expected.joined(separator: "\n\n"))
        let expectedMarkdown = ["# 題", "【ダミー】導入文です。"] +
            (1...4).map { "![写真\($0)](images/0\($0).jpg)\n\n【ダミー】写真\($0)の文章です。" } +
            ["【ダミー】締めの文章です。"]
        XCTAssertEqual(fresh.markdown, expectedMarkdown.joined(separator: "\n\n"))
    }
    func testEmptyTitleAndDateDoNotAddMemoOrFallbackTitle() throws {
        let result = try render { $0.title=""; $0.introduction=" \n"; $0.location="\u{3000}\n\t"; $0.equipment="" }
        XCTAssertTrue(result.plainText.hasPrefix("【ダミー】導入文です。"))
        XCTAssertFalse(result.plainText.contains("撮影情報"))
        XCTAssertFalse(result.plainText.contains("無題の記事"))
    }
    func testCandidateDateIsNeverPromoted() throws {
        let result = try render { $0.shootingDate=ArticleCalendarDay(year: 1,month: 2,day: 3); $0.dateCandidateState = .candidate }
        XCTAssertTrue(result.plainText.contains("撮影日（未確認）：0001-02-03"))
    }
    func testConfirmedDateAppearsWithoutLegacyMetadata() throws {
        let result = try render { $0.shootingDate=ArticleCalendarDay(year: 2024,month: 2,day: 29); $0.dateCandidateState = .confirmed; $0.location=" 場所\n"; $0.equipment="機材"; $0.film="フィルム"; $0.people="人物" }
        XCTAssertTrue(result.plainText.hasSuffix("撮影情報\n撮影日：2024-02-29"))
        XCTAssertFalse(result.markdown.contains("人物名"))
    }
    func testMarkdownHTMLAndImageInjectionAreData() throws {
        let result = try render { $0.title="<script>&![偽](file:///private) *強調*\n# 見出し\\e\u{301}👩‍👧" }
        XCTAssertFalse(result.markdown.contains("<script>")); XCTAssertFalse(result.markdown.contains("![偽]"))
        XCTAssertTrue(result.markdown.contains("&lt;script&gt;&amp;"))
        XCTAssertTrue(result.markdown.contains("\\*強調\\*  \n\\# 見出し\\\\e\u{301}👩‍👧"))
        XCTAssertEqual(result.markdown.components(separatedBy: "![写真").count - 1, 4)
        XCTAssertTrue(result.plainText.contains("<script>&![偽](file:///private)"))
    }
    func testProjectIdentityIsSeparateFromSharedFingerprint() throws {
        let source=try DraftFixtures.source(), value=ArticleContent(source:source)
        let first=try ArticleProjectionContext(projectID:UUID()), second=try ArticleProjectionContext(projectID:UUID())
        let a=try first.renderArticle(source:source,content:value), b=try second.renderArticle(source:source,content:value)
        XCTAssertNotEqual(a.projectID,b.projectID); XCTAssertEqual(a.sourceFingerprint,b.sourceFingerprint)
        XCTAssertEqual(a.sourceFingerprint,ArticleFingerprint.content(source:source,content:value))
        XCTAssertEqual(try first.renderArticle(source:source,content:value),a)
    }
    func testUnknownIdentityAndMismatchedPhotoOrderAreRejected() throws {
        XCTAssertThrowsError(try ArticleProjectionContext(projectID: UUID(uuid:(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))))
        let source=try DraftFixtures.source(); var content=ArticleContent(source:source); content.photoTexts.reverse()
        XCTAssertThrowsError(try ArticleProjectionContext(projectID:UUID()).renderArticle(source:source,content:content))
    }
}
