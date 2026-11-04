import Foundation

public enum ArticlePersistenceCheckpoint: Sendable { case beforeOperation, beforeCurrent, currentRenamed, afterCurrent }

private struct ArticleCurrent: Codable {
    var schemaVersion = 1
    let projectID: UUID
    let operationID: UUID
    let operationDigest: String
}
private struct ArticleOperation: Codable {
    var schemaVersion = 1
    let operationID: UUID
    let previous: UUID?
    let inputDigest: String
    let article: SavedArticle
}

public actor ArticlePersistence: ArticleStoring {
    private let directory: URL
    private let checkpoint: @Sendable (ArticlePersistenceCheckpoint) throws -> Void
    private let diagnostics:ArticleDiagnostics
    public init(directory: URL, checkpoint: @escaping @Sendable (ArticlePersistenceCheckpoint) throws -> Void = { _ in },diagnostics:ArticleDiagnostics = .live) {
        self.directory = directory; self.checkpoint = checkpoint; self.diagnostics=diagnostics
    }

    public func open(_ projectID: UUID) throws -> SavedArticle {
        let project = try projectDirectory(projectID, create: false)
        return try loadCurrent(project, projectID: projectID).operation.article
    }

    public func list() throws -> ArticleDraftList {
        do { _ = try ArticleDirectory.open(directory, create: false) }
        catch ArticleFailure.missing { return ArticleDraftList() }
        var result = ArticleDraftList()
        let urls: [URL]
        do { urls = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) }
        catch { throw ArticleFailure.ioFailure }
        for url in urls {
            guard let id = UUID(uuidString: url.lastPathComponent) else { continue }
            do { result.articles.append(try open(id)) }
            catch { result.failures[id] = error as? ArticleFailure ?? .ioFailure }
        }
        result.articles.sort { $0.updatedAt == $1.updatedAt ? $0.projectID.uuidString < $1.projectID.uuidString : $0.updatedAt > $1.updatedAt }
        return result
    }

    public func create(projectID: UUID, operationID: UUID, source: ArticleSource, content: ArticleContent) throws -> SavedArticle {
        try observeSave {try createRecord(projectID:projectID,operationID:operationID,source:source,content:content)}
    }
    private func createRecord(projectID:UUID,operationID:UUID,source:ArticleSource,content:ArticleContent) throws ->SavedArticle {
        try content.validate(source: source)
        let project = try projectDirectory(projectID, create: true)
        return try project.withLock {
            let input = ArticleFingerprint.operation(kind: "create", projectID: projectID, revision: nil, source: source, content: content)
            let loaded = try optionalCurrent(project, projectID: projectID)
            if let old = try reconcile(project, current: loaded?.operation, operationID: operationID, input: input) { return old }
            guard loaded == nil else { throw ArticleFailure.conflict }
            let article = try SavedArticle(projectID: projectID, source: source, content: content)
            return try commit(project, operationID: operationID, previous: nil, input: input, article: article, expected: nil)
        }
    }

    public func save(projectID: UUID, operationID: UUID, expected: SavedArticle, content: ArticleContent) throws -> SavedArticle {
        try observeSave {try saveRecord(projectID:projectID,operationID:operationID,expected:expected,content:content)}
    }
    private func saveRecord(projectID:UUID,operationID:UUID,expected:SavedArticle,content:ArticleContent) throws ->SavedArticle {
        try expected.validate(); try content.validate(source: expected.source)
        guard projectID == expected.projectID else { throw ArticleFailure.invalidInput }
        let project = try projectDirectory(projectID, create: false)
        return try project.withLock {
            let loaded = try loadCurrent(project, projectID: projectID)
            let input = ArticleFingerprint.operation(kind: "save", projectID: projectID, revision: expected.savedRevision, source: expected.source, content: content)
            if let old = try reconcile(project, current: loaded.operation, operationID: operationID, input: input) { return old }
            guard loaded.operation.article == expected else { throw ArticleFailure.conflict }
            var article = expected
            let fingerprint = ArticleFingerprint.content(source: expected.source, content: content)
            if fingerprint != expected.fingerprint {
                guard article.savedRevision < Int.max else { throw ArticleFailure.capacity }
                article.savedRevision += 1; article.content = content; article.fingerprint = fingerprint
                article.updatedAt = Date(timeIntervalSince1970: (Date().timeIntervalSince1970 * 1000).rounded() / 1000)
            }
            return try commit(project, operationID: operationID, previous: loaded.operation.operationID, input: input, article: article, expected: loaded.bytes)
        }
    }
    private func observeSave(_ operation:() throws ->SavedArticle) throws ->SavedArticle {
        diagnostics.record(.saveStarted)
        do {let result=try operation(); diagnostics.record(.saveSucceeded); return result}
        catch {diagnostics.record(.failed,failure:error as? ArticleFailure ?? .ioFailure); throw error}
    }

    private func commit(_ project: ArticleDirectory, operationID: UUID, previous: UUID?, input: String, article: SavedArticle, expected: Data?) throws -> SavedArticle {
        let operations = try project.child("operations", create: true)
        let candidate = ArticleOperation(operationID: operationID, previous: previous, inputDigest: input, article: article)
        var chosen = candidate
        var bytes = try encode(candidate)
        do {
            bytes = try operations.read(operationID.uuidString)
            chosen = try decode(ArticleOperation.self, bytes)
            guard chosen.inputDigest == input, chosen.previous == previous, chosen.article.projectID == article.projectID else { throw ArticleFailure.invalidInput }
            try chosen.article.validate()
        } catch ArticleFailure.missing {
            try checkpoint(.beforeOperation)
            try operations.writeNew(operationID.uuidString, data: bytes)
            try operations.synchronize()
        }
        let head = ArticleCurrent(projectID: article.projectID, operationID: operationID, operationDigest: ArticleFingerprint.digest(bytes))
        try checkpoint(.beforeCurrent)
        let checkpoint=checkpoint
        do {
            try project.replace("current", data: encode(head), expected: expected,afterRename:{try checkpoint(.currentRenamed)})
            try checkpoint(.afterCurrent)
        } catch {
            if error as? ArticleFailure == .uncertainResult {throw error}
            if let stored = try? loadCurrent(project, projectID: article.projectID), stored.operation.operationID == operationID { return stored.operation.article }
            throw error
        }
        return chosen.article
    }

    private func reconcile(_ project: ArticleDirectory, current: ArticleOperation?, operationID: UUID, input: String) throws -> SavedArticle? {
        var cursor = current, visited = Set<UUID>()
        let operations = try project.child("operations", create: true)
        // 操作ファイルは削除しない。不在なら確定鎖にも属さない。
        // 存在する ID は、期待版の競合判定より先に必ず鎖へ照合する。
        do { _ = try operations.read(operationID.uuidString) } catch ArticleFailure.missing { return nil }
        while let operation = cursor {
            guard visited.insert(operation.operationID).inserted else { throw ArticleFailure.corruptData }
            if operation.operationID == operationID {
                guard operation.inputDigest == input else { throw ArticleFailure.invalidInput }
                try project.synchronize()
                return operation.article
            }
            if let previous = operation.previous {
                let next = try decode(ArticleOperation.self, operations.read(previous.uuidString))
                guard next.operationID == previous, next.article.projectID == operation.article.projectID else { throw ArticleFailure.corruptData }
                try next.article.validate(); cursor = next
            } else { cursor = nil }
        }
        return nil
    }

    private func projectDirectory(_ id: UUID, create: Bool) throws -> ArticleDirectory {
        try ArticleDirectory.open(directory, create: create).child(id.uuidString, create: create)
    }
    private func optionalCurrent(_ project: ArticleDirectory, projectID: UUID) throws -> (operation: ArticleOperation, bytes: Data)? {
        do { return try loadCurrent(project, projectID: projectID) } catch ArticleFailure.missing { return nil }
    }
    private func loadCurrent(_ project: ArticleDirectory, projectID: UUID) throws -> (operation: ArticleOperation, bytes: Data) {
        let bytes = try project.read("current"), head = try decode(ArticleCurrent.self, bytes)
        guard head.projectID == projectID else { throw ArticleFailure.corruptData }
        let operationBytes = try project.child("operations", create: false).read(head.operationID.uuidString)
        guard ArticleFingerprint.digest(operationBytes) == head.operationDigest else { throw ArticleFailure.corruptData }
        let operation = try decode(ArticleOperation.self, operationBytes)
        guard operation.operationID == head.operationID, operation.article.projectID == projectID else { throw ArticleFailure.corruptData }
        try operation.article.validate()
        return (operation, bytes)
    }
    private func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]; encoder.dateEncodingStrategy = .millisecondsSince1970
        do { return try encoder.encode(value) } catch { throw ArticleFailure.invalidInput }
    }
    private func decode<T: Decodable>(_ type: T.Type, _ bytes: Data) throws -> T {
        guard let header = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any], let version = header["schemaVersion"] as? Int else { throw ArticleFailure.corruptData }
        try rejectDuplicateKeys(bytes)
        guard version == 1 else { throw ArticleFailure.unsupportedVersion }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .millisecondsSince1970
        do { return try decoder.decode(type, from: bytes) } catch { throw ArticleFailure.corruptData }
    }

    /// Foundation の JSON は重複キーを最後の値へ畳むため、型への変換前に拒否する。
    private func rejectDuplicateKeys(_ bytes: Data) throws {
        let tokens = Array(bytes)
        var stack: [Set<String>?] = [], index = 0
        while index < tokens.count {
            switch tokens[index] {
            case 123: stack.append(Set<String>()); index += 1
            case 91: stack.append(nil); index += 1
            case 125, 93: guard !stack.isEmpty else {throw ArticleFailure.corruptData}; stack.removeLast(); index += 1
            case 34:
                let start = index; index += 1
                var escaped = false
                while index < tokens.count {
                    let token = tokens[index]; index += 1
                    if escaped {escaped = false}
                    else if token == 92 {escaped = true}
                    else if token == 34 {break}
                }
                let end = index
                while index < tokens.count, [9,10,13,32].contains(tokens[index]) {index += 1}
                if index < tokens.count, tokens[index] == 58, let object = stack.indices.last, var keys = stack[object] {
                    guard let key = try? JSONDecoder().decode(String.self,from:Data(tokens[start..<end])), keys.insert(key).inserted else {throw ArticleFailure.corruptData}
                    stack[object] = keys
                }
            default: index += 1
            }
        }
    }
}
