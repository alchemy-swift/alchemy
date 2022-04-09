import NIOCore

extension Filesystem {
    /// Create a filesystem backed by the local filesystem at the given root
    /// directory.
    public static func local(root: String = "Public/") -> Filesystem {
        Filesystem(provider: LocalFilesystem(root: root))
    }
    
    /// Create a filesystem backed by the local filesystem in the "Public/"
    /// directory.
    public static var local: Filesystem {
        .local()
    }
}

struct LocalFilesystem: FilesystemProvider {
    /// The file IO helper for streaming files.
    private let fileIO = NonBlockingFileIO(threadPool: Thread.pool)
    /// Used for allocating buffers when pulling out file data.
    private let bufferAllocator = ByteBufferAllocator()
    
    var root: String
    
    // MARK: - FilesystemProvider
    
    init(root: String) {
        self.root = root
    }
    
    func get(_ filepath: String) async throws -> File {
        guard try await exists(filepath) else {
            throw FileError.fileDoesntExist
        }
        
        let url = try url(for: filepath)
        let fileInfo = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let fileSizeBytes = (fileInfo[.size] as? NSNumber)?.intValue else {
            Log.error("[Storage] attempted to access file at `\(url.path)` but it didn't have a size.")
            throw HTTPError(.internalServerError)
        }
        
        return File(
            name: url.lastPathComponent,
            content: .stream { writer in
                // Load the file in chunks, streaming it.
                let fileHandle = try NIOFileHandle(path: url.path)
                defer { try? fileHandle.close() }
                try await fileIO.readChunked(
                    fileHandle: fileHandle,
                    byteCount: fileSizeBytes,
                    chunkSize: NonBlockingFileIO.defaultChunkSize,
                    allocator: bufferAllocator,
                    eventLoop: Loop.current,
                    chunkHandler: { chunk in
                        Loop.current.asyncSubmit { try await writer.write(chunk) }
                    }
                ).get()
            },
            size: fileSizeBytes)
    }
    
    func create(_ filepath: String, content: ByteContent) async throws -> File {
        let url = try url(for: filepath)
        guard try await !exists(filepath) else {
            throw FileError.filenameAlreadyExists
        }
        
        let fileHandle = try NIOFileHandle(path: url.path, mode: .write, flags: .allowFileCreation())
        defer { try? fileHandle.close() }

        // Stream and write
        var offset: Int64 = 0
        try await content.stream.readAll { buffer in
            try await fileIO.write(fileHandle: fileHandle, toOffset: offset, buffer: buffer, eventLoop: Loop.current).get()
            offset += Int64(buffer.writerIndex)
        }
        
        return File(name: url.path, filesystemPath: url.relativeString)
    }
    
    func exists(_ filepath: String) async throws -> Bool {
        let url = try url(for: filepath, createDirectories: false)
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && !isDirectory.boolValue
    }
    
    func delete(_ filepath: String) async throws {
        guard try await exists(filepath) else {
            throw FileError.fileDoesntExist
        }
        
        try FileManager.default.removeItem(atPath: url(for: filepath).path)
    }
    
    private func url(for filepath: String, createDirectories: Bool = true) throws -> URL {
        guard let rootUrl = URL(string: root) else {
            throw FileError.invalidFileUrl
        }
        
        let url = rootUrl.appendingPathComponent(filepath.trimmingForwardSlash)
        
        // Ensure directory exists.
        let directory = url.deletingLastPathComponent().path
        if createDirectories && !FileManager.default.fileExists(atPath: directory) {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }
        
        return url
    }
    
    func signedUrl() async throws -> URL {
        throw FileError.signedUrlNotAvailable
    }
}
