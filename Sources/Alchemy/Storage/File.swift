/// Represents a file with a name and binary contents.
public struct File: Equatable {
    // The name of the file, including the extension.
    public let name: String
    // The binary contents of the file.
    public let contents: ByteBuffer
}

extension File {
    public var `extension`: String {
        URL(string: name)?.pathExtension ?? ""
    }
    
    public var contentLength: Int {
        contents.writerIndex
    }
    
    public var contentType: ContentType? {
        ContentType(fileExtension: `extension`)
    }
    
    /// Convert this file to a Response.
    public var response: Response {
        var headers: HTTPHeaders = ["content-length": "\(contentLength)"]
        if let contentType = contentType {
            headers.replaceOrAdd(name: "content-type", value: contentType.string)
        }

        return Response(status: .ok, headers: headers, body: Content(buffer: contents, type: contentType))
    }
    
    public func store(in directory: String? = nil, in storage: Storage = .default) async throws {
        try await storage.put(self, in: directory)
    }
}
