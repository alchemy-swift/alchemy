import MultipartKit
import Papyrus

/// Represents a file with a name and binary contents.
public struct File: Codable, ResponseConvertible {
    // The name of the file, including the extension.
    public var name: String
    // The size of the file, in bytes.
    public let size: Int
    // The binary contents of the file.
    public let content: ByteContent
    /// The path extension of this file.
    public var `extension`: String { name.components(separatedBy: ".")[safe: 1] ?? "" }
    /// The content type of this file, based on it's extension.
    public var contentType: ContentType? { ContentType(fileExtension: `extension`) }
    
    public init(name: String, size: Int, content: ByteContent) {
        self.name = name
        self.size = size
        self.content = content
    }
    
    /// Returns a copy of this file with a new name.
    public func named(_ name: String) -> File {
        var copy = self
        copy.name = name
        return copy
    }
    
    // MARK: - ResponseConvertible
    
    public func response() async throws -> Response {
        Response(status: .ok, headers: ["content-disposition":"inline; filename=\"\(name)\""])
            .withBody(content, type: contentType, length: size)
    }
    
    public func download() async throws -> Response {
        Response(status: .ok, headers: ["content-disposition":"attachment; filename=\"\(name)\""])
            .withBody(content, type: contentType, length: size)
    }
    
    // MARK: - Decodable
    
    enum CodingKeys: String, CodingKey {
        case name, size, content
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.size = try container.decode(Int.self, forKey: .size)
        self.content = .data(try container.decode(Data.self, forKey: .content))
    }
    
    // MARK: - Encodable
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(size, forKey: .size)
        try container.encode(content.data(), forKey: .content)
    }
}

// As of now, streamed files aren't possible over request multipart.
extension File: MultipartPartConvertible {
    public var multipart: MultipartPart? {
        var headers: HTTPHeaders = [:]
        headers.contentType = ContentType(fileExtension: `extension`)
        headers.contentDisposition = HTTPHeaders.ContentDisposition(value: "form-data", name: nil, filename: name)
        headers.contentLength = size
        return MultipartPart(headers: headers, body: content.buffer)
    }
    
    public init?(multipart: MultipartPart) {
        let fileExtension = multipart.headers.contentType?.fileExtension.map { ".\($0)" } ?? ""
        let fileName = multipart.headers.contentDisposition?.filename ?? multipart.headers.contentDisposition?.name
        let fileSize = multipart.headers.contentLength ?? multipart.body.writerIndex
        
        if multipart.headers.contentDisposition?.filename == nil {
            Log.warning("A multipart part had no name or filename in the Content-Disposition header, using a random UUID for the file name.")
        }

        // If there is no filename in the content disposition included (technically not required via RFC 7578) set to a random UUID.
        self.init(name: (fileName ?? UUID().uuidString) + fileExtension, size: fileSize, content: .buffer(multipart.body))
    }
}
