public protocol FilesystemProvider {
    /// The root directory for storing and fetching files.
    var root: String { get }
    
    /// Create a file in this filesystem.
    @discardableResult
    func create(_ filepath: String, content: ByteContent) async throws -> File
    
    /// Returns whether a file with the given path exists.
    func exists(_ filepath: String) async throws -> Bool
    
    /// Gets a file with the given path.
    func get(_ filepath: String) async throws -> File
    
    /// Delete a file at the given path.
    func delete(_ filepath: String) async throws
    
    /// Create a temporary URL to a file at the given path.
    func temporaryURL(_ filepath: String, expires: TimeAmount, headers: HTTPHeaders) async throws -> URL
    
    /// Get a URL for the file at the given path.
    func url(_ filepath: String) throws -> URL
    
    /// Return a new FilesystemProvider with the given root directory.
    func directory(_ path: String) -> FilesystemProvider
}
