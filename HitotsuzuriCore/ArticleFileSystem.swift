import Foundation
import Darwin

/// 開いた親ディレクトリを基準に操作し、検査後のパス差替えを避ける。
final class ArticleDirectory {
    static let maximumFileBytes=64*1024*1024
    let descriptor: Int32
    init(descriptor: Int32) { self.descriptor = descriptor }
    deinit { Darwin.close(descriptor) }

    static func open(_ url: URL, create: Bool) throws -> ArticleDirectory {
        guard url.isFileURL else { throw ArticleFailure.invalidReference }
        var directory = ArticleDirectory(descriptor: Darwin.open("/", O_RDONLY | O_DIRECTORY))
        guard directory.descriptor >= 0 else { throw ArticleFailure.ioFailure }
        for component in url.standardizedFileURL.pathComponents.dropFirst() {
            directory = try directory.child(component, create: create)
        }
        return directory
    }

    func child(_ name: String, create: Bool) throws -> ArticleDirectory {
        try validate(name)
        if create, mkdirat(descriptor, name, 0o700) != 0, errno != EEXIST { throw failure() }
        let fd = openat(descriptor, name, O_RDONLY | O_DIRECTORY | O_NOFOLLOW)
        guard fd >= 0 else { throw failure() }
        return ArticleDirectory(descriptor: fd)
    }
    func createChildExclusive(_ name:String) throws ->ArticleDirectory {
        try validate(name)
        guard mkdirat(descriptor,name,0o700) == 0 else {throw failure()}
        return try child(name,create:false)
    }

    func read(_ name: String) throws -> Data {
        try validate(name)
        let fd = openat(descriptor, name, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
        guard fd >= 0 else { throw failure() }
        defer { Darwin.close(fd) }
        var info = stat()
        guard fstat(fd, &info) == 0, info.st_mode & S_IFMT == S_IFREG else { throw ArticleFailure.invalidReference }
        guard info.st_size >= 0, info.st_size <= Self.maximumFileBytes else { throw ArticleFailure.capacity }
        var result = Data(), buffer = [UInt8](repeating: 0, count: 16384)
        while true {
            let count = Darwin.read(fd, &buffer, buffer.count)
            if count == 0 { break }
            if count < 0 { if errno == EINTR { continue }; throw failure() }
            guard result.count <= Self.maximumFileBytes - count else { throw ArticleFailure.capacity }
            result.append(contentsOf: buffer.prefix(count))
        }
        return result
    }

    func writeNew(_ name: String, data: Data) throws {
        try validate(name)
        guard data.count <= Self.maximumFileBytes else {throw ArticleFailure.capacity}
        let fd = openat(descriptor, name, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
        guard fd >= 0 else { throw failure() }
        defer { Darwin.close(fd) }
        do {
            try data.withUnsafeBytes { raw in
                var offset = 0
                while offset < raw.count {
                    let count = Darwin.write(fd, raw.baseAddress!.advanced(by: offset), raw.count - offset)
                    if count < 0 { if errno == EINTR { continue }; throw failure() }
                    guard count > 0 else { throw ArticleFailure.ioFailure }
                    offset += count
                }
            }
            guard fsync(fd) == 0 else { throw failure() }
            guard fcntl(fd,F_FULLFSYNC) == 0 else {throw failure()}
        } catch { _ = unlinkat(descriptor, name, 0); throw error }
    }

    func replace(_ name: String, data: Data, expected: Data?,afterRename:() throws ->Void = {}) throws {
        let temporary = "pending-" + UUID().uuidString
        try writeNew(temporary, data: data)
        defer { _ = unlinkat(descriptor, temporary, 0) }
        let current: Data?
        do { current = try read(name) } catch ArticleFailure.missing { current = nil }
        guard current == expected else { throw ArticleFailure.conflict }
        guard renameat(descriptor, temporary, descriptor, name) == 0 else { throw failure() }
        do {try afterRename()} catch {throw ArticleFailure.uncertainResult}
        guard fsync(descriptor) == 0 else { throw ArticleFailure.uncertainResult }
    }

    func withLock<T>(isolation: isolated (any Actor)? = #isolation, _ body: () throws -> T) throws -> T {
        let fd = openat(descriptor, ".lock", O_RDWR | O_CREAT | O_NOFOLLOW | O_NONBLOCK, 0o600)
        guard fd >= 0 else { throw failure() }
        defer { Darwin.close(fd) }
        var info = stat()
        guard fstat(fd, &info) == 0, info.st_mode & S_IFMT == S_IFREG else { throw ArticleFailure.invalidReference }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else { throw ArticleFailure.busy }
        defer { _ = flock(fd, LOCK_UN) }
        return try body()
    }

    func synchronize() throws { guard fsync(descriptor) == 0 else { throw failure() } }
    func moveExclusive(_ source: String, to destination: String,afterRename:() throws ->Void = {}) throws {
        try validate(source); try validate(destination)
        guard renameatx_np(descriptor, source, descriptor, destination, UInt32(RENAME_EXCL)) == 0 else { throw failure() }
        do {try afterRename()} catch {throw ArticleFailure.uncertainResult}
        do {try synchronize()} catch {throw ArticleFailure.uncertainResult}
    }
    func remove(_ name: String, directory: Bool = false) throws {
        try validate(name)
        guard unlinkat(descriptor, name, directory ? AT_REMOVEDIR : 0) == 0 else { throw failure() }
    }
    private func validate(_ name: String) throws {
        guard !name.isEmpty, name != ".", name != "..", !name.contains("/"), !name.contains("\0") else { throw ArticleFailure.invalidReference }
    }
    private func failure() -> ArticleFailure {
        switch errno {
        case ENOENT: .missing
        case ELOOP, ENOTDIR: .invalidReference
        case EACCES, EPERM: .permissionDenied
        case ENOSPC, EDQUOT: .capacity
        case EEXIST: .conflict
        default: .ioFailure
        }
    }
}
