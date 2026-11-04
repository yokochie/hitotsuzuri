import XCTest
@testable import HitotsuzuriCore

@MainActor final class ArticleDraftIntegrationTests: XCTestCase {
    func testLongDraftPersistenceAndProjectionPerformance() async throws {
        let source=try DraftFixtures.source(String(repeating:"名称",count:100))
        var content=ArticleInitialContent(source:source).content
        content.title=String(repeating:"題",count:200)
        let text=String(String(repeating:"日本語e\u{301}👩‍👧\"<>\n",count:1500).prefix(10000))
        XCTAssertEqual(text.count,10000)
        content.introduction=text; content.closing=text
        for index in content.photoTexts.indices {content.photoTexts[index].text=text}
        let root=DraftFixtures.root(), store=ArticlePersistence(directory:root,diagnostics:ArticleDiagnostics {_ in})
        var target=try await store.create(projectID:UUID(),operationID:UUID(),source:source,content:content)
        for _ in 0..<99 {_=try await store.create(projectID:UUID(),operationID:UUID(),source:source,content:content)}
        for _ in 1..<1000 {target=try await store.save(projectID:target.id,operationID:UUID(),expected:target,content:content)}
        let listing=try await store.list(); XCTAssertEqual(listing.articles.count,100); XCTAssertTrue(listing.failures.isEmpty)
        let operations=try FileManager.default.contentsOfDirectory(at:root.appendingPathComponent(target.id.uuidString).appendingPathComponent("operations"),includingPropertiesForKeys:nil)
        XCTAssertEqual(operations.count,1000)
        let clock=ContinuousClock(); var saves:[Double]=[], reopen:[Double]=[], cold:[Double]=[], projections:[Double]=[]
        let workspace=ArticleWorkspace(selections:DraftSelections(),articles:store)
        let presentation=ArticlePresentation(workspace:workspace,store:store)
        for index in 0..<30 {
            content.title=String(repeating:"題",count:198)+String(format:"%02d",index)
            let start=clock.now
            target=try await store.save(projectID:target.id,operationID:UUID(),expected:target,content:content)
            saves.append(draftSeconds(start.duration(to:clock.now)))
            let openStart=clock.now
            let opened=await presentation.requestNavigation(.article(target.id)); XCTAssertTrue(opened)
            let session=try XCTUnwrap(presentation.session)
            XCTAssertFalse(presentation.isLoading); XCTAssertFalse(session.isSaving)
            XCTAssertEqual(try session.validatedContent(),content)
            reopen.append(draftSeconds(openStart.duration(to:clock.now)))
        }
        for _ in 0..<10 {
            let fresh=ArticlePersistence(directory:root,diagnostics:ArticleDiagnostics {_ in}), start=clock.now
            let saved=try await fresh.open(target.id)
            let session=ArticleEditSession(article:saved,store:fresh)
            _=try session.validatedContent()
            cold.append(draftSeconds(start.duration(to:clock.now)))
        }
        let context=try ArticleProjectionContext(projectID:target.id)
        for _ in 0..<100 {
            let start=clock.now, rendered=try context.renderArticle(source:source,content:content)
            projections.append(draftSeconds(start.duration(to:clock.now)))
            XCTAssertEqual(rendered.sourceFingerprint,target.fingerprint)
            XCTAssertTrue(rendered.plainText.contains(text)); XCTAssertEqual(rendered.imagePaths,["images/01.jpg","images/02.jpg","images/03.jpg","images/04.jpg"])
        }
        for (name,values,limit) in [("save",saves,2.0),("core-reopen-ready",reopen,2.0),("pure-projection",projections,0.1)] {
            print("Draft performance \(name) n=\(values.count) p95=\(draftP95(values)) max=\(values.max() ?? 0) seconds; articles=100 targetInitialOperations=1000 titleCharacters=200 bodyCharacters=10000x6")
            XCTAssertLessThanOrEqual(draftP95(values),limit,name)
        }
        print("Draft performance cold-store-session n=10 p95=\(draftP95(cold)) max=\(cold.max() ?? 0) seconds; OS disk cache was not flushed; not application cold launch")
    }
    func testPreparedExportRejectsCanonicalByteRewriting() throws {
        let source=try DraftFixtures.source(); var content=ArticleContent(source:source); content.title="e\u{301}"
        let article=try SavedArticle(projectID:UUID(),source:source,content:content)
        let rendered=try ArticleProjectionContext(projectID:article.id).renderArticle(source:source,content:content)
        let rewritten=RenderedArticle(projectID:rendered.projectID,sourceFingerprint:rendered.sourceFingerprint,plainText:rendered.plainText.precomposedStringWithCanonicalMapping,markdown:rendered.markdown,imagePaths:rendered.imagePaths)
        XCTAssertThrowsError(try PreparedArticleExport(savedInput:SavedExportInput(article:article),rendered:rewritten))
    }
    private func make(root: URL, selections: DraftSelections) -> (ArticlePersistence, ArticlePresentation) {
        let store=ArticlePersistence(directory:root,diagnostics:ArticleDiagnostics { _ in })
        return (store,ArticlePresentation(workspace:ArticleWorkspace(selections:selections,articles:store),store:store))
    }
    func testRealFileSaveRestartAndRawMetadataRestore() async throws {
        let root=DraftFixtures.root(), selections=DraftSelections(), (store,p)=make(root:root,selections:selections)
        await p.beginCurrentSelection(); let session=try XCTUnwrap(p.session)
        session.content.introduction="私的な本文\n👩‍👧"; session.metadataInput.change(year:"9999",month:"12",day:"31")
        let saved=await session.save(); XCTAssertTrue(saved)
        let (_,restarted)=make(root:root,selections:selections); await restarted.beginCurrentSelection()
        XCTAssertEqual(restarted.session?.projectID,session.projectID)
        XCTAssertEqual(restarted.session?.content.introduction,"私的な本文\n👩‍👧")
        XCTAssertEqual(restarted.session?.metadataInput.year,"9999")
        let disk=try await store.open(session.projectID); XCTAssertEqual(disk.content.shootingDate?.year,9999)
    }
    func testReconfirmedSelectionAssociatesWithoutChangingContentAndRestartsExact() async throws {
        let root=DraftFixtures.root(), selections=DraftSelections(), (_,p)=make(root:root,selections:selections)
        await p.beginCurrentSelection(); let session=try XCTUnwrap(p.session)
        session.content.title="本人が変更"; _=await session.save(); let original=try XCTUnwrap(session.saved)
        _=await p.requestNavigation(.back)
        await selections.set(CommittedSelection(albumID:"draft-album",albumTitle:"新名",orderedAssetIDs:["a","b","c","d"]))
        await p.beginCurrentSelection(); await p.chooseExisting(original.id)
        XCTAssertEqual(p.session?.projectID,original.id); XCTAssertEqual(p.session?.content,original.content)
        XCTAssertEqual(p.session?.source,original.source); XCTAssertEqual(p.session?.saved?.sourceSelectionIDs.count,2)
        let (_,restarted)=make(root:root,selections:selections); await restarted.beginCurrentSelection()
        XCTAssertEqual(restarted.session?.projectID,original.id)
    }
    func testInvalidDateNeverCommitsOrProjectsPriorDate() async throws {
        let root=DraftFixtures.root(), (store,p)=make(root:root,selections:DraftSelections())
        await p.beginCurrentSelection(); let session=try XCTUnwrap(p.session), original=session.saved
        session.metadataInput.change(year:"2026",month:"2",day:"31")
        let success=await session.save(); XCTAssertFalse(success); await p.showPreview()
        XCTAssertEqual(p.mode,.editing); XCTAssertNil(p.rendered)
        let disk=try await store.open(session.projectID); XCTAssertEqual(disk,original)
    }
    func testPreparedExportRejectsDifferentArticleWithSameFingerprint() async throws {
        let source=try DraftFixtures.source(), content=ArticleContent(source:source)
        let first=try SavedArticle(projectID:UUID(),source:source,content:content)
        let other=try SavedArticle(projectID:UUID(),source:source,content:content)
        let rendered=try ArticleProjectionContext(projectID:other.id).renderArticle(source:source,content:content)
        XCTAssertEqual(first.fingerprint,other.fingerprint)
        XCTAssertThrowsError(try PreparedArticleExport(savedInput:SavedExportInput(article:first),rendered:rendered))
    }
    func testFixedSavedPreparationMatchesPureProjectionAfterLaterEdit() async throws {
        let root=DraftFixtures.root(), (_,p)=make(root:root,selections:DraftSelections())
        await p.beginCurrentSelection(); let session=try XCTUnwrap(p.session)
        session.content.title="保存済み固定"; let preparation=try await p.prepareSavedExport(.save)
        let input=try XCTUnwrap(preparation)
        session.content.title="後続"
        let rendered=try ArticleProjectionContext(projectID:input.article.id).renderArticle(source:input.article.source,content:input.article.content)
        let prepared=try PreparedArticleExport(savedInput:input,rendered:rendered)
        XCTAssertEqual(prepared.rendered.projectID,session.projectID)
        XCTAssertEqual(prepared.rendered.sourceFingerprint,input.article.fingerprint)
        XCTAssertTrue(prepared.rendered.plainText.contains("保存済み固定")); XCTAssertTrue(session.isDirty)
    }
    func testLateProjectionCannotReplaceDifferentArticle() async throws {
        let gate=DraftProjectionGate(), h=DraftHarness.make(projector:{ context,source,content in try await gate.project(context,source:source,content:content) })
        let first=try await h.savedSession(), task=Task { await h.presentation.showPreview() }
        guard await draftWaitUntil({gate.waiting}) else { await task.value; return XCTFail("投影を開始") }
        let second=ArticleEditSession(source:first.source,store:h.store)
        h.presentation.adopt(second); gate.release(); await task.value
        XCTAssertTrue(h.presentation.session === second); XCTAssertNil(h.presentation.rendered); XCTAssertFalse(h.presentation.isProjecting)
    }
    func testDepartureBridgeAcceptsOneDecisionAndRepliesOnce() async throws {
        let bridge=ArticleDepartureBridge(); var decisions=0, replies:[Bool]=[]
        let first=bridge.request(.terminate,decision:{ decisions += 1; await Task.yield(); return true },completion:{replies.append($0)})
        let repeated=bridge.request(.closeWindow,decision:{ decisions += 1; return false },completion:{replies.append($0)})
        XCTAssertTrue(first); XCTAssertFalse(repeated)
        let replied=await draftWaitUntil({!replies.isEmpty}); XCTAssertTrue(replied)
        XCTAssertEqual(decisions,1); XCTAssertEqual(replies,[true]); XCTAssertNil(bridge.pending)
    }
    func testFailureDiagnosticsNeverContainPrivateCanary() async throws {
        let logs=DraftLogs(), source=try DraftFixtures.source("秘密CANARY-人物-場所"), root=DraftFixtures.root()
        let store=ArticlePersistence(directory:root,checkpoint:{ point in if case .beforeCurrent=point { throw ArticleFailure.permissionDenied } },diagnostics:ArticleDiagnostics {logs.append($0)})
        var content=ArticleContent(source:source); content.people="秘密CANARY-人物-場所"
        do { _=try await store.create(projectID:UUID(),operationID:UUID(),source:source,content:content); XCTFail("注入障害") }
        catch { XCTAssertEqual(error as? ArticleFailure,.permissionDenied) }
        XCTAssertTrue(logs.lines.contains("failed:permissionDenied")); XCTAssertFalse(logs.lines.joined().contains("CANARY"))
    }
    func testOldProjectionFailureDoesNotChangeNewArticleState() async throws {
        let gate=DraftProjectionGate(), h=DraftHarness.make(projector:{ context,source,content in
            _=try await gate.project(context,source:source,content:content)
            throw ArticleFailure.ioFailure
        })
        let first=try await h.savedSession(), task=Task { await h.presentation.showPreview() }
        guard await draftWaitUntil({gate.waiting}) else { await task.value; return XCTFail("投影を開始") }
        let second=ArticleEditSession(source:first.source,store:h.store)
        h.presentation.adopt(second); gate.release(); await task.value
        XCTAssertNil(h.presentation.failure); XCTAssertNil(h.presentation.message)
        XCTAssertTrue(h.presentation.session === second)
    }
    func testDiscardForCurrentSelectionCandidatesDoesNotAskTwice() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession()
        let saved=try XCTUnwrap(session.saved); session.content.title="離れる未保存"
        await h.selections.set(CommittedSelection(albumID:"draft-album",albumTitle:"再確定",orderedAssetIDs:["a","b","c","d"]))
        _=await h.presentation.requestNavigation(.currentSelection)
        _=await h.presentation.resolveNavigation(.discard)
        XCTAssertNotNil(h.presentation.candidates)
        await h.presentation.chooseExisting(saved.id)
        XCTAssertNil(h.presentation.pendingNavigation)
        XCTAssertEqual(h.presentation.session?.content.title,saved.content.title)
        XCTAssertEqual(h.presentation.session?.saved?.sourceSelectionIDs.count,2)
    }
    func testFailedNewTargetPreparationKeepsOriginalDirtySession() async throws {
        let h=DraftHarness.make(), session=try await h.savedSession()
        session.content.title="元の未保存入力"
        await h.selections.set(CommittedSelection(albumID:"different-album",albumTitle:"別記事",orderedAssetIDs:["w","x","y","z"]))
        await h.store.configure(save:[.capacity])
        _=await h.presentation.requestNavigation(.currentSelection)
        let left=await h.presentation.resolveNavigation(.discard)
        XCTAssertFalse(left); XCTAssertTrue(h.presentation.session === session)
        XCTAssertEqual(h.presentation.session?.content.title,"元の未保存入力")
        XCTAssertEqual(h.presentation.failure,.capacity)
    }
}
