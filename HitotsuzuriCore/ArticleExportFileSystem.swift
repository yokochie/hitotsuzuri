import Foundation
import Darwin

enum ArticleExportFileSystem {
    static func entries(_ directory: ArticleDirectory) throws -> Set<String> {
        let fd = dup(directory.descriptor)
        guard fd >= 0, let stream = fdopendir(fd) else { if fd >= 0 { close(fd) }; throw ArticleFailure.ioFailure }
        defer { closedir(stream) }
        rewinddir(stream)
        var names = Set<String>()
        while let entry = readdir(stream) {
            let name = withUnsafePointer(to: &entry.pointee.d_name) { pointer in
                pointer.withMemoryRebound(to: CChar.self, capacity: 256) { String(cString: $0) }
            }
            if name != "." && name != ".." { names.insert(name) }
        }
        return names
    }
    static func identity(_ directory: ArticleDirectory) throws -> ArticleExportDirectoryIdentity {
        var info = stat()
        guard fstat(directory.descriptor, &info) == 0, info.st_mode & S_IFMT == S_IFDIR else { throw ArticleFailure.invalidReference }
        return ArticleExportDirectoryIdentity(device: UInt64(info.st_dev), inode: info.st_ino, createdSeconds: Int64(info.st_birthtimespec.tv_sec), createdNanoseconds: Int64(info.st_birthtimespec.tv_nsec))
    }
    static func identity(of url: URL) throws -> ArticleExportDirectoryIdentity {
        try identity(ArticleDirectory.open(url, create: false))
    }
}
