/// Represents a file with a name and binary contents.
public struct File {
    // The name of the file, including the extension.
    public let name: String
    // The size of the file, in bytes.
    public let size: Int
    // The binary contents of the file.
    public let content: ByteContent
}

extension File {
    public var `extension`: String {
        URL(string: name)?.pathExtension ?? ""
    }
    
    public var contentType: ContentType? {
        ContentType(fileExtension: `extension`)
    }
    
    /// Convert this file to a Response.
    public var response: Response {
        let response = Response(status: .ok).withBody(content, type: contentType)
        response.headers.contentLength = size
        return response
    }
    
    public func store(in directory: String? = nil, in storage: Storage = .default) async throws {
        try await storage.put(self, in: directory)
    }
}
