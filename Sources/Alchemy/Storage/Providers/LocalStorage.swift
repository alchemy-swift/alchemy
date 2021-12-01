import NIOCore

struct LocalStorage: StorageProvider {
    /// The file IO helper for streaming files.
    private let fileIO = NonBlockingFileIO(threadPool: .default)
    /// Used for allocating buffers when pulling out file data.
    private let bufferAllocator = ByteBufferAllocator()
    var root: String
    
    // MARK: - StorageProvider
    
    init(root: String) {
        self.root = root
    }
    
    func get(_ filepath: String) async throws -> File {
        guard try await exists(filepath) else {
            throw StorageError.fileDoesntExist
        }
        
        let url = try url(for: filepath)
        let fileHandle = try NIOFileHandle(path: url.path)
        
        let fileInfo = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let fileSizeBytes = (fileInfo[.size] as? NSNumber)?.intValue else {
            Log.error("[Storage] attempted to access file at `\(url.path)` but it didn't have a size.")
            throw HTTPError(.internalServerError)
        }
        
        // Set any relevant headers based off the file info.
        var headers: HTTPHeaders = ["content-length": "\(fileSizeBytes)"]
        if let mediaType = ContentType(fileExtension: url.pathExtension) {
            headers.add(name: "content-type", value: mediaType.value)
        }
        
        var buffer = ByteBuffer()
        
        // Load the file in chunks, streaming it.
        try await fileIO.readChunked(
            fileHandle: fileHandle,
            byteCount: fileSizeBytes,
            chunkSize: NonBlockingFileIO.defaultChunkSize,
            allocator: bufferAllocator,
            eventLoop: Loop.current,
            chunkHandler: {
                var chunk = $0
                return Loop.current.submit {
                    buffer.writeBuffer(&chunk)
                }
            }
        )
        .flatMapThrowing { _ -> Void in
            try fileHandle.close()
        }
        .flatMapAlways { result -> EventLoopFuture<Void> in
            return Loop.current.wrapAsync {
                if case .failure(let error) = result {
                    Log.error("[Storage] Encountered an error loading a file: \(error)")
                }
            }
        }
        .get()
        
        return File(name: url.lastPathComponent, contents: buffer)
    }
    
    func create(_ filepath: String, contents: ByteBuffer) async throws -> File {
        let url = try url(for: filepath)
        let fileHandle = try NIOFileHandle(path: url.path, mode: .write, flags: .allowFileCreation())
        do {
            try await fileIO.write(fileHandle: fileHandle, buffer: contents, eventLoop: Loop.current).get()
        } catch {
            try fileHandle.close()
            throw error
        }
        
        try fileHandle.close()
        return File(name: filepath, contents: contents)
    }
    
    func exists(_ filepath: String) async throws -> Bool {
        let url = try url(for: filepath, createDirectories: false)
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && !isDirectory.boolValue
    }
    
    func delete(_ filepath: String) async throws {
        guard try await exists(filepath) else {
            throw StorageError.fileDoesntExist
        }
        
        try FileManager.default.removeItem(atPath: url(for: filepath).path)
    }
    
    private func url(for filepath: String, createDirectories: Bool = true) throws -> URL {
        guard let rootUrl = URL(string: root) else {
            throw StorageError.invalidUrl
        }
        
        let url = rootUrl.appendingPathComponent(filepath.trimmingForwardSlash)
        
        // Ensure directory exists.
        let directory = url.deletingLastPathComponent().path
        if createDirectories && !FileManager.default.fileExists(atPath: directory) {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }
        
        return url
    }
}

extension Storage {
    /// Create a storage disk backed by the local filesystem at the given root
    /// directory.
    public static func local(root: String = "Public/") -> Storage {
        Storage(provider: LocalStorage(root: "Public/"))
    }
    
    /// Create a storage disk backed by the local filesystem in the "Public/"
    /// directory.
    public static var local: Storage {
        .local()
    }
}
