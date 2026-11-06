import XCTest
import Darwin
@testable import HitotsuzuriCore

/// 実写真や通常保存先を使わず、検索・読取・書込の権限境界を実I/Oで確かめる。
final class ArticleDirectoryAccessTests: XCTestCase {
    func testExistingArticleUnderSearchOnlyAncestorCanOpenSaveAndReopen() async throws {
        let fixture = try makeFixture()
        let store = ArticlePersistence(directory: fixture.articles)
        let original = try await makeArticle(store)
        defer { fixture.restore(fixture.ancestor) }
        try fixture.setMode(0o111, at: fixture.ancestor)
        try fixture.verifySearchOnlyAncestor()

        let listed = try await store.list()
        XCTAssertEqual(listed.articles, [original])
        XCTAssertTrue(listed.failures.isEmpty)
        let opened = try await store.open(original.projectID)
        XCTAssertEqual(opened, original)
        var content = opened.content
        content.introduction = "検索のみの祖先でも保存する本文\ne\u{301}"
        let saved = try await store.save(projectID: opened.projectID, operationID: UUID(), expected: opened, content: content)
        let reopened = try await ArticlePersistence(directory: fixture.articles).open(original.projectID)
        XCTAssertEqual(reopened, saved)
        XCTAssertEqual(reopened.projectID, original.projectID)
        XCTAssertEqual(reopened.source, original.source)
        XCTAssertEqual(reopened.source.orderedAssetIDs, ["four", "two", "one", "three"])
        XCTAssertEqual(reopened.content, content)
        XCTAssertEqual(reopened.savedRevision, 2)
    }

    func testMissingArticleDirectoriesUnderSearchOnlyAncestorCanBeCreatedAndListed() async throws {
        let fixture = try makeFixture()
        let missing = fixture.allowed.appendingPathComponent("missing/Articles", isDirectory: true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: missing.path))
        defer { fixture.restore(fixture.ancestor) }
        try fixture.setMode(0o111, at: fixture.ancestor)
        try fixture.verifySearchOnlyAncestor()

        let store = ArticlePersistence(directory: missing)
        let article = try await makeArticle(store)
        let list = try await store.list()
        XCTAssertEqual(list.articles, [article])
        XCTAssertTrue(list.failures.isEmpty)
        let reopened = try await ArticlePersistence(directory: missing).open(article.projectID)
        XCTAssertEqual(reopened, article)
    }

    func testReadDeniedIsNotAnEmptyDraftList() async throws {
        let fixture = try makeFixture()
        let store = ArticlePersistence(directory: fixture.articles)
        let article = try await makeArticle(store)
        let current = fixture.current(article.projectID)
        let originalBytes = try Data(contentsOf: current)
        defer { fixture.restore(fixture.articles) }
        try fixture.setMode(0o000, at: fixture.articles)
        try fixture.verifyReadDenied(at: fixture.articles)

        do {
            _ = try await store.list()
            XCTFail("実際の読取拒否を空一覧や成功として返さない")
        } catch {
            XCTAssertEqual(error as? ArticleFailure, .permissionDenied)
        }
        try fixture.setMode(0o700, at: fixture.articles)
        let restored = try await store.list()
        XCTAssertEqual(restored.articles, [article])
        XCTAssertTrue(restored.failures.isEmpty)
        XCTAssertEqual(try Data(contentsOf: current), originalBytes)
    }

    func testWriteDenialPreservesArticleAndRetrySucceedsAfterRestoration() async throws {
        let fixture = try makeFixture()
        let store = ArticlePersistence(directory: fixture.articles)
        let original = try await makeArticle(store)
        let project = fixture.articles.appendingPathComponent(original.projectID.uuidString, isDirectory: true)
        let current = fixture.current(original.projectID)
        let originalBytes = try Data(contentsOf: current)
        var content = original.content
        content.title = "権限回復後に同じ操作で保存"
        let operationID = UUID()
        defer { fixture.restore(project) }
        try fixture.setMode(0o500, at: project)
        try fixture.verifyWriteDenied(at: project)

        do {
            _ = try await store.save(projectID: original.projectID, operationID: operationID, expected: original, content: content)
            XCTFail("実際の書込拒否を成功として返さない")
        } catch {
            XCTAssertEqual(error as? ArticleFailure, .permissionDenied)
        }
        XCTAssertEqual(try Data(contentsOf: current), originalBytes)
        let unchanged = try await store.open(original.projectID)
        XCTAssertEqual(unchanged, original)
        try fixture.setMode(0o700, at: project)
        let saved = try await store.save(projectID: original.projectID, operationID: operationID, expected: original, content: content)
        let repeated = try await store.save(projectID: original.projectID, operationID: operationID, expected: original, content: content)
        XCTAssertEqual(repeated, saved)
        XCTAssertEqual(saved.content, content)
        XCTAssertEqual(saved.savedRevision, 2)
        let reopened = try await ArticlePersistence(directory: fixture.articles).open(original.projectID)
        XCTAssertEqual(reopened, saved)
        let list = try await store.list()
        XCTAssertEqual(list.articles, [saved])
        XCTAssertTrue(list.failures.isEmpty)
        let operations = try FileManager.default.contentsOfDirectory(at: project.appendingPathComponent("operations"), includingPropertiesForKeys: nil)
        XCTAssertEqual(operations.count, 2, "作成と一回の保存だけを保持し、同操作再試行で複製しない")
    }

    func testIntermediateSymlinkIsRejectedWithoutChangingTarget() async throws {
        let fixture = try makeFixture()
        let store = ArticlePersistence(directory: fixture.articles)
        let article = try await makeArticle(store)
        let current = fixture.current(article.projectID)
        let originalBytes = try Data(contentsOf: current)
        let sentinel = fixture.allowed.appendingPathComponent("sentinel")
        let sentinelBytes = Data("中間リンク先の所有外データを保護".utf8)
        try sentinelBytes.write(to: sentinel)
        let link = fixture.root.appendingPathComponent("intermediate-link", isDirectory: true)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: fixture.allowed)

        assertSymlinkRejected(link.appendingPathComponent("Articles", isDirectory: true))
        XCTAssertEqual(try Data(contentsOf: current), originalBytes)
        XCTAssertEqual(try Data(contentsOf: sentinel), sentinelBytes)
        let reopened = try await store.open(article.projectID)
        XCTAssertEqual(reopened, article)
        XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: link.path), fixture.allowed.path)
    }

    func testLeafSymlinkIsRejectedWithoutChangingTarget() async throws {
        let fixture = try makeFixture()
        let store = ArticlePersistence(directory: fixture.articles)
        let article = try await makeArticle(store)
        let current = fixture.current(article.projectID)
        let originalBytes = try Data(contentsOf: current)
        let sentinel = fixture.articles.appendingPathComponent("sentinel")
        let sentinelBytes = Data("末端リンク先の所有外データを保護".utf8)
        try sentinelBytes.write(to: sentinel)
        let originalNames = try FileManager.default.contentsOfDirectory(atPath: fixture.articles.path).sorted()
        let link = fixture.allowed.appendingPathComponent("leaf-link", isDirectory: true)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: fixture.articles)

        assertSymlinkRejected(link)
        XCTAssertEqual(try Data(contentsOf: current), originalBytes)
        XCTAssertEqual(try Data(contentsOf: sentinel), sentinelBytes)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: fixture.articles.path).sorted(), originalNames)
        let reopened = try await store.open(article.projectID)
        XCTAssertEqual(reopened, article)
        XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: link.path), fixture.articles.path)
    }

    private func makeArticle(_ store: ArticlePersistence) async throws -> SavedArticle {
        let selection = CommittedSelection(albumID: "synthetic-album", albumTitle: "合成記事", orderedAssetIDs: ["four", "two", "one", "three"])
        let source = try ArticleSource(selection: selection)
        return try await store.create(projectID: UUID(), operationID: UUID(), source: source, content: ArticleContent(source: source))
    }

    private func makeFixture() throws -> ArticleAccessFixture {
        guard geteuid() != 0 else { throw ArticleAccessFixtureFailure("root実行ではPOSIX拒否を検証できません。skipせず試験を止めます。") }
        let fixture = ArticleAccessFixture()
        // 作成途中の失敗でも、この試験が発行したUUID領域だけを回収する。
        addTeardownBlock { try fixture.cleanup() }
        try FileManager.default.createDirectory(at: fixture.allowed, withIntermediateDirectories: true)
        try fixture.setMode(0o700, at: fixture.root)
        try fixture.setMode(0o700, at: fixture.ancestor)
        try fixture.setMode(0o700, at: fixture.allowed)
        return fixture
    }

    private func assertSymlinkRejected(_ url: URL, file: StaticString = #filePath, line: UInt = #line) {
        for create in [false, true] {
            XCTAssertThrowsError(try ArticleDirectory.open(url, create: create), "中間/末端symlinkをcreate指定にかかわらず拒否", file: file, line: line) {
                XCTAssertEqual($0 as? ArticleFailure, .invalidReference, file: file, line: line)
            }
        }
    }
}

private struct ArticleAccessFixtureFailure: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

private struct ArticleAccessFixture: Sendable {
    private let base: URL
    let root: URL
    let ancestor: URL
    let allowed: URL
    var articles: URL { allowed.appendingPathComponent("Articles", isDirectory: true) }

    init() {
        base = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent(".build/article-tests", isDirectory: true).resolvingSymlinksInPath()
        root = base.appendingPathComponent(UUID().uuidString, isDirectory: true)
        ancestor = root.appendingPathComponent("search-only", isDirectory: true)
        allowed = ancestor.appendingPathComponent("allowed", isDirectory: true)
    }

    func current(_ projectID: UUID) -> URL {
        articles.appendingPathComponent(projectID.uuidString).appendingPathComponent("current")
    }

    func setMode(_ mode: mode_t, at url: URL) throws {
        guard owns(url), chmod(url.path, mode) == 0 else {
            throw ArticleAccessFixtureFailure("合成fixtureのchmod失敗: errno=\(errno)")
        }
        var info = stat()
        guard lstat(url.path, &info) == 0, info.st_mode & S_IFMT == S_IFDIR,
              info.st_mode & 0o777 == mode else {
            throw ArticleAccessFixtureFailure("合成fixtureのdirectory modeを確認できません。")
        }
    }

    func restore(_ url: URL, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(owns(url), "UUID領域外の権限を変更しない", file: file, line: line)
        guard owns(url) else { return }
        XCTAssertEqual(chmod(url.path, 0o700), 0, "合成fixtureの権限を復元する", file: file, line: line)
    }

    func verifySearchOnlyAncestor() throws {
        try verifyReadDenied(at: ancestor)
        // 製品helperと独立したOS呼出しで、末端自体は読取可能と立証する。
        let descriptor = Darwin.open(allowed.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW)
        guard descriptor >= 0 else {
            throw ArticleAccessFixtureFailure("検索のみ祖先fixtureで許可済み末端へ到達できません: errno=\(errno)")
        }
        Darwin.close(descriptor)
    }

    func verifyReadDenied(at url: URL) throws {
        let descriptor = Darwin.open(url.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW)
        let code = errno
        if descriptor >= 0 {
            Darwin.close(descriptor)
            throw ArticleAccessFixtureFailure("合成fixtureで読取拒否が成立しません。成功/skipへ置換しません。")
        }
        guard code == EACCES || code == EPERM else {
            throw ArticleAccessFixtureFailure("合成fixtureのopen失敗は権限拒否ではありません: errno=\(code)")
        }
    }

    func verifyWriteDenied(at url: URL) throws {
        let probe = url.appendingPathComponent("permission-probe-" + UUID().uuidString)
        let descriptor = Darwin.open(probe.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
        let code = errno
        if descriptor >= 0 {
            Darwin.close(descriptor)
            _ = unlink(probe.path)
            throw ArticleAccessFixtureFailure("合成fixtureで書込拒否が成立しません。成功/skipへ置換しません。")
        }
        guard code == EACCES || code == EPERM else {
            throw ArticleAccessFixtureFailure("合成fixtureのwrite probe失敗は権限拒否ではありません: errno=\(code)")
        }
    }

    func cleanup() throws {
        guard root.deletingLastPathComponent().path == base.path, UUID(uuidString: root.lastPathComponent) != nil,
              root.resolvingSymlinksInPath().path == root.path else {
            throw ArticleAccessFixtureFailure("合成fixtureの所有確認に失敗し、掃除を拒否しました。")
        }
        var rootInfo = stat()
        guard lstat(root.path, &rootInfo) == 0 else {
            if errno == ENOENT { return }
            throw ArticleAccessFixtureFailure("合成fixtureの掃除前検査に失敗しました。")
        }
        guard rootInfo.st_mode & S_IFMT == S_IFDIR else {
            throw ArticleAccessFixtureFailure("合成fixtureのrootが差し替わっているため掃除しません。")
        }
        // 親から順に復元し、読取/検索不可の子が残っても所有rootを回収できるようにする。
        for directory in [root, ancestor, allowed, articles] {
            var info = stat()
            if lstat(directory.path, &info) == 0 {
                guard info.st_mode & S_IFMT == S_IFDIR, chmod(directory.path, 0o700) == 0 else {
                    throw ArticleAccessFixtureFailure("合成fixtureの掃除前権限復元に失敗しました。")
                }
            } else if errno != ENOENT {
                throw ArticleAccessFixtureFailure("合成fixtureの掃除前directory検査に失敗しました。")
            }
        }
        try FileManager.default.removeItem(at: root)
        guard !FileManager.default.fileExists(atPath: root.path) else {
            throw ArticleAccessFixtureFailure("合成fixtureのUUID領域が残っています。")
        }
    }

    private func owns(_ url: URL) -> Bool {
        url.path == root.path || url.path.hasPrefix(root.path + "/")
    }
}
