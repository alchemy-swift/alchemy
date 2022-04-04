import MultipartKit
import Papyrus

/*
 Store on Model
 1. Came from request (raw data)
 -> throw error "please save to storage first"
 2. Came from storage
 -> {key}: {path_in_storage}
 3. Came from URL
 -> {key}: {url}
 */

/*
 Filesystem
 1. put() -> File no contents
 2. get() -> File with contents
 3. url() -> fileUrl
 4. tempUrl() -> tempUrl
 5. metadata() -> FileMetadata
 */

/*
 File
 1. url() -> String
 2. tempUrl() -> String
 3. download() -> Response
 4. metadata() -> Response
 */

// File
struct File2 {
    enum Content {
        // Ref to external URL
        case url(String)
        // Ref to Filesystem
        case filesystem(String)
        // Raw byte stream or content, possible uploaded
        case bytes(ByteContent)
    }
    
    /// The name of this file, including the extension
    let name: String
    let content: Content
    let contentType: ContentType
    
    // MARK: - Accessing Contents
    
    /// get a url for this resource
    func url() throws -> String {
        switch content {
        case .bytes:
            throw FileError.invalidFileUrl
        case .filesystem(let path):
            return path
        case .url(let url):
            return url
        }
    }
    
    /// get temporary url for this resource
    func temporaryUrl() async throws -> String {
        switch content {
        case .filesystem(let path):
            // Generate temp url with filesystem
            return path
        default:
            throw FileError.invalidFileUrl
        }
    }
    
    func contents() async throws -> ByteContent {
        switch content {
        case .bytes(let content):
            return content
        case .filesystem(let path):
            // Load contents from filesystem
            return .string("")
        case .url(let url):
            // Load contents from URL
            return .string("")
        }
    }
    
    // MARK: ModelProperty
    
    init(key: String, on row: SQLRowReader) throws {
        // Assume stored as storage
        
    }
    
    func store(key: String, on row: inout SQLRowWriter) throws {
        guard case let .storage(ref) = content else {
            throw FileError.invalidFileUrl
        }
        
        // Only store stuff in storage
        row.put(.string(ref), at: key)
    }
}

/// Represents a file with a name and binary contents.
public struct File: Codable, ResponseConvertible {
    // The name of the file, including the extension.
    public var name: String
    // The size of the file, in bytes.
    public let size: Int
    // The binary contents of the file.
    public var content: ByteContent
    /// The path extension of this file.
    public var `extension`: String { name.components(separatedBy: ".").last ?? "" }
    /// The content type of this file, based on it's extension.
    public let contentType: ContentType
    
    public init(name: String, contentType: ContentType? = nil, size: Int, content: ByteContent) {
        self.name = name
        self.size = size
        self.content = content
        let _extension = name.components(separatedBy: ".").last ?? ""
        self.contentType = contentType ?? ContentType(fileExtension: _extension) ?? .octetStream
    }
    
    /// Returns a copy of this file with a new name.
    public func named(_ name: String) -> File {
        var copy = self
        copy.name = name
        return copy
    }
    
    // MARK: - ResponseConvertible
    
    public func response() async throws -> Response {
        Response(status: .ok, headers: ["Content-Disposition":"inline; filename=\"\(name)\""])
            .withBody(content, type: contentType, length: size)
    }
    
    public func download() async throws -> Response {
        Response(status: .ok, headers: ["Content-Disposition":"attachment; filename=\"\(name)\""])
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
        let _extension = name.components(separatedBy: ".").last ?? ""
        self.contentType = ContentType(fileExtension: _extension) ?? .octetStream
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
        self.init(name: (fileName ?? UUID().uuidString) + fileExtension, contentType: multipart.headers.contentType, size: fileSize, content: .buffer(multipart.body))
    }
}
