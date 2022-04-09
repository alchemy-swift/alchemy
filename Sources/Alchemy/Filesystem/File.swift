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
 File
 - came from storage
 - came from request / response
 - came from url?
 
 Contents
 - loaded
 - not loaded
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
public struct File: Codable, ResponseConvertible {
    public enum FileType {
        // Ref to Filesystem
        case filesystem(String)
        // Raw bytes, likely from an HTTP request or response
        case bytes
    }
    
    /// The name of this file, including the extension
    public let name: String
    /// The content of this file, either raw bytes or a path in a `Filesystem`.
    public let type: FileType
    public let content: ByteContent?
    public let size: Int?
    public let clientContentType: ContentType?
    
    public var contentType: ContentType {
        name.components(separatedBy: ".").last.map { ContentType(fileExtension: $0) ?? .octetStream }  ?? .octetStream
    }
    
    public init(name: String, filesystemPath: String, content: ByteContent? = nil, size: Int? = nil) {
        self.name = name
        self.type = .filesystem(filesystemPath)
        self.content = content
        self.size = size
    }
    
    public init(name: String, content: ByteContent, size: Int? = nil, clientContentType: ContentType? = nil) {
        self.name = name
        self.type = .bytes
        self.content = content
        self.size = size
        self.clientContentType = clientContentType
    }
    
    // MARK: - Accessing Contents
    
    /// get a url for this resource
    public func url() throws -> String {
        switch content {
        case .bytes:
            throw FileError.invalidFileUrl
        case .filesystem(let path):
            return path
        }
    }
    
    /// get temporary url for this resource
    public func temporaryUrl() async throws -> String {
        switch content {
        case .filesystem(let path):
            // Generate temp url with filesystem
            return path
        default:
            throw FileError.invalidFileUrl
        }
    }
    
    public func getContent() async throws -> ByteContent {
        guard let content = content else {
            switch type {
            case .bytes:
                throw FileError.contentNotAvailable
            case .filesystem(let path):
                Storage.get(path).getContent()
            }
        }
        
        return content

        switch content {
        case .bytes(let content):
            return content
        case .filesystem(let path):
            return try await Storage.get(path)
        }
    }
    
    // MARK: ModelProperty
    
//    init(key: String, on row: SQLRowReader) throws {
//        // Assume stored as storage
//
//    }
//
//    func store(key: String, on row: inout SQLRowWriter) throws {
//        guard case let .storage(ref) = content else {
//            throw FileError.invalidFileUrl
//        }
//
//        // Only store stuff in storage
//        row.put(.string(ref), at: key)
//    }
    
    // MARK: - ResponseConvertible
    
    public func response() async throws -> Response {
        let bytes = try await getBytes()
        return Response(status: .ok, headers: ["Content-Disposition":"inline; filename=\"\(name)\""])
            .withBody(bytes, type: contentType, length: size)
    }
    
    public func download() async throws -> Response {
        let bytes = try await getBytes()
        return Response(status: .ok, headers: ["Content-Disposition":"attachment; filename=\"\(name)\""])
            .withBody(bytes, type: contentType, length: size)
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case name, size, content
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.size = try container.decode(Int.self, forKey: .size)
        self.content = .bytes(.data(try container.decode(Data.self, forKey: .content)))
        let _extension = name.components(separatedBy: ".").last ?? ""
        self.clientContentType = ContentType(fileExtension: _extension) ?? .octetStream
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(size, forKey: .size)
        switch content {
        case .bytes(let byteContent):
            try container.encode(byteContent.data(), forKey: .content)
        case .filesystem:
            throw FileError.invalidFileUrl
        }
    }
}

/// Represents a file with a name and binary contents.
public struct File2 {
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
    public func named(_ name: String) -> File2 {
        var copy = self
        copy.name = name
        return copy
    }
}

// As of now, streamed files aren't possible over request multipart.
extension File: MultipartPartConvertible {
    public var multipart: MultipartPart? {
        var headers: HTTPHeaders = [:]
        headers.contentType = contentType
        headers.contentDisposition = HTTPHeaders.ContentDisposition(value: "form-data", name: nil, filename: name)
        headers.contentLength = size
        guard let content = self.content else {
            Log.warning("Unable to convert a filesystem reference to a `MultipartPart`. Please load the contents of the file first.")
            return nil
        }
        
        return MultipartPart(headers: headers, body: content.data())
    }
    
    public init?(multipart: MultipartPart) {
        let fileExtension = multipart.headers.contentType?.fileExtension.map { ".\($0)" } ?? ""
        let fileName = multipart.headers.contentDisposition?.filename ?? multipart.headers.contentDisposition?.name
        let fileSize = multipart.headers.contentLength ?? multipart.body.writerIndex
        
        if multipart.headers.contentDisposition?.filename == nil {
            Log.warning("A multipart part had no name or filename in the Content-Disposition header, using a random UUID for the file name.")
        }

        // If there is no filename in the content disposition included (technically not required via RFC 7578) set to a random UUID.
        self.init(name: (fileName ?? UUID().uuidString) + fileExtension, content: .buffer(multipart.body), size: fileSize, clientContentType: multipart.headers.contentType)
    }
}
