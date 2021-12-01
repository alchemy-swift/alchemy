import Foundation

public struct Storage: Service {
    let provider: StorageProvider
    
    /// The root directory for storing and fetching files.
    public var root: String { provider.root }
    
    /// Create a file in this storage.
    /// - Parameters:
    ///  - filename: The name of the file, including extension, to create.
    ///  - directory: The directory to put the file in. If nil, goes in root.
    ///  - contents: the binary contents of the file.
    /// - Returns: The newly created file.
    @discardableResult
    public func create(_ filepath: String, contents: ByteBuffer) async throws -> File {
        try await provider.create(filepath, contents: contents)
    }
    
    /// Returns whether a file with the given path exists.
    public func exists(_ filepath: String) async throws -> Bool {
        try await provider.exists(filepath)
    }
    
    /// Gets a file with the given path.
    public func get(_ filepath: String) async throws -> File {
        try await provider.get(filepath)
    }
    
    /// Delete a file at the given path.
    public func delete(_ filepath: String) async throws {
        try await provider.delete(filepath)
    }
    
    public func put(_ file: File, in directory: String? = nil) async throws {
        guard let directory = directory, let directoryUrl = URL(string: directory) else {
            try await create(file.name, contents: file.contents)
            return
        }
        
        try await create(directoryUrl.appendingPathComponent(file.name).path, contents: file.contents)
    }
}
