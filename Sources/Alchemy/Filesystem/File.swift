import MultipartKit
import Papyrus
import NIOCore

// File
public struct File: Codable, ResponseConvertible {
    public enum Source {
        // The file is stored in a `Filesystem`.
        case filesystem(path: String)
        // The file came with the given ContentType from an HTTP request.
        case http(clientContentType: ContentType?)
        
        static var raw: Source {
            .http(clientContentType: nil)
        }
    }
    
    /// The name of this file, including the extension
    public var name: String
    /// The source of this file, either from an HTTP request or from a Filesystem.
    public let source: Source
    public var content: ByteContent?
    public let size: Int?
    public let clientContentType: ContentType?
    /// The path extension of this file.
    public var `extension`: String {
        name.components(separatedBy: ".").last ?? ""
    }
    
    public var contentType: ContentType {
        name.components(separatedBy: ".").last.map { ContentType(fileExtension: $0) ?? .octetStream }  ?? .octetStream
    }
    
    public init(name: String, source: Source, content: ByteContent? = nil, size: Int? = nil) {
        self.name = name
        self.source = source
        self.content = content
        self.size = size
        self.clientContentType = nil
    }
    
    // MARK: - Accessing Contents
    
    /// get a url for this resource
    public func url() throws -> URL {
        switch source {
        case .filesystem(let path):
            return try Storage(.default).url(path)
        case .http:
            throw FileError.urlUnavailable
        }
    }
    
    /// get temporary url for this resource
    public func temporaryUrl(filesystem: Filesystem = Storage, expires: TimeAmount, headers: HTTPHeaders = [:]) async throws -> URL {
        switch source {
        case .filesystem(let path):
            return try await filesystem.temporaryURL(path, expires: expires, headers: headers)
        default:
            throw FileError.temporaryUrlNotAvailable
        }
    }
    
    public func getContent() async throws -> ByteContent {
        guard let content = content else {
            switch source {
            case .http:
                throw FileError.contentNotLoaded
            case .filesystem(let path):
                return try await Storage.get(path).getContent()
            }
        }
        
        return content
    }
    
    // MARK: ModelProperty
    
    init(key: String, on row: SQLRowReader) throws {
        let name = try row.require(key).string()
        self.init(name: name, source: .filesystem(path: name))
    }

    func store(key: String, on row: inout SQLRowWriter) throws {
        guard case let .filesystem(path) = source else {
            throw RuneError("currently, only files saved in a `Filesystem` can be stored on a `Model`")
        }

        // Only store stuff in storage
        row.put(.string(path), at: key)
    }
    
    // MARK: - ResponseConvertible
    
    public func response() async throws -> Response {
        let content = try await getContent()
        return Response(status: .ok, headers: ["Content-Disposition":"inline; filename=\"\(name)\""])
            .withBody(content, type: contentType, length: size)
    }
    
    public func download() async throws -> Response {
        let content = try await getContent()
        return Response(status: .ok, headers: ["Content-Disposition":"attachment; filename=\"\(name)\""])
            .withBody(content, type: contentType, length: size)
    }
    
    // MARK: - Codable
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        self.name = UUID().uuidString
        self.source = .raw
        self.content = .data(data)
        self.size = data.count
        self.clientContentType = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        guard let content = content else {
            throw FileError.contentNotLoaded
        }
        
        try container.encode(content.data())
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
        let name = (fileName ?? UUID().uuidString) + fileExtension
        let contentType = multipart.headers.contentType
        self.init(name: name, source: .http(clientContentType: contentType), content: .buffer(multipart.body), size: fileSize)
    }
}
