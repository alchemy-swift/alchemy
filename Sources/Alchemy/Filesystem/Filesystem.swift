import NIOConcurrencyHelpers

/// An abstraction around local or remote file storage.
public final class Filesystem: Service {
    public typealias Identifier = ServiceIdentifier<Filesystem>

    private var provider: FilesystemProvider

    /// The root directory for storing and fetching files.
    public var root: String { provider.root }

    public init(provider: FilesystemProvider) {
        self.provider = provider
    }
    
    /// Create a file in this filesystem.
    ///
    /// - Parameters:
    ///  - filename: The name of the file, including extension, to create.
    ///  - content: the binary contents of the file.
    /// - Returns: The newly created file.
    @discardableResult
    public func create(_ filepath: String, content: Bytes) async throws -> File {
        try await provider.create(filepath, content: content).in(self)
    }
    
    /// Returns whether a file with the given path exists.
    public func exists(_ filepath: String) async throws -> Bool {
        try await provider.exists(filepath)
    }
    
    /// Gets the contents of the file at the given path.
    public func get(_ filepath: String) async throws -> File {
        try await provider.get(filepath).in(self)
    }
    
    /// Delete a file at the given path.
    public func delete(_ filepath: String) async throws {
        try await provider.delete(filepath)
    }
    
    @discardableResult
    public func put(_ file: File, in directory: String? = nil, as name: String? = nil) async throws -> File {
        let content = try await file.getContent()
        let name = name ?? (UUID().uuidString + file.extension)
        guard let directory = directory, let directoryUrl = URL(string: directory) else {
            return try await create(name, content: content)
        }
        
        return try await create(directoryUrl.appendingPathComponent(name).path, content: content)
    }
    
    public func temporaryURL(_ filepath: String, expires: TimeAmount, headers: HTTPHeaders = [:]) async throws -> URL {
        try await provider.temporaryURL(filepath, expires: expires, headers: headers)
    }
    
    public func url(_ filepath: String) throws -> URL {
        try provider.url(filepath)
    }
    
    public func directory(_ path: String) -> Filesystem {
        let provider = self.provider.directory(path)
        return Filesystem(provider: provider)
    }
}

extension File {
    @discardableResult
    public func store(on filesystem: Filesystem = Storage, in directory: String? = nil, as name: String? = nil) async throws -> File {
        let name = name ?? ("\(UUID().uuidString).\(`extension`)")
        return try await filesystem.put(self, in: directory, as: name)
    }
}
