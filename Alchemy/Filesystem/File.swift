import Foundation
import MultipartKit

/// Represents a file from either a filesystem (on disk, in AWS S3, etc) or from
/// an HTTP request (uploaded or downloaded).
public struct File: Codable, ResponseConvertible, ModelProperty {
    public enum Source {
        // The file is stored in a `Filesystem` with the given path.
        case filesystem(Filesystem? = nil, path: String)
        
        // The file came with the given ContentType from an HTTP request.
        case http(clientContentType: ContentType?)
        
        public static var raw: Source {
            .http(clientContentType: nil)
        }
    }
    
    /// The name of this file, including the extension
    public var name: String
    
    /// The source of this file, either from an HTTP request or from a Filesystem.
    public var source: Source

    /// The contents of this file
    public var content: Bytes?
    public let size: Int?
    public let clientContentType: ContentType?
    
    /// The path extension of this file.
    public var `extension`: String {
        name.components(separatedBy: ".").last ?? ""
    }
    
    public var contentType: ContentType {
        name.components(separatedBy: ".").last.map { ContentType(fileExtension: $0) ?? .octetStream }  ?? .octetStream
    }
    
    public init(name: String, source: Source, content: Bytes? = nil, size: Int? = nil) {
        self.name = name
        self.source = source
        self.content = content
        self.size = size
        self.clientContentType = nil
    }
    
    // MARK: - Accessing Contents
    
    /// Get a url for this resource.
    public func url() throws -> URL {
        switch source {
        case .filesystem(let filesystem, let path):
            return try (filesystem ?? Storage).url(path)
        case .http:
            throw FileError.urlUnavailable
        }
    }
    
    /// Get a temporary url for this resource.
    public func temporaryUrl(expires: TimeAmount, headers: HTTPFields = [:]) async throws -> URL {
        switch source {
        case .filesystem(let filesystem, let path):
            return try await (filesystem ?? Storage).temporaryURL(path, expires: expires, headers: headers)
        default:
            throw FileError.temporaryUrlNotAvailable
        }
    }
    
    public func getContent() async throws -> Bytes {
        guard let content = content else {
            switch source {
            case .http:
                throw FileError.contentNotLoaded
            case .filesystem(let filesystem, let path):
                return try await (filesystem ?? Storage).get(path).getContent()
            }
        }
        
        return content
    }

    @discardableResult
    public mutating func collect() async throws -> File {
        self.content = .buffer(try await getContent().collect())
        return self
    }

    func `in`(_ filesystem: Filesystem) -> File {
        var copy = self
        switch source {
        case .filesystem(_, let path):
            copy.source = .filesystem(filesystem, path: path)
        default:
            break
        }

        return copy
    }

    // MARK: ModelProperty
    
    public init(key: String, on row: SQLRowReader) throws {
        let name = try row.require(key).string(key)
        self.init(name: name, source: .filesystem(Storage, path: name))
    }

    public func store(key: String, on row: inout SQLRowWriter) throws {
        guard case .filesystem(_, let path) = source else {
            throw RuneError("currently, only files saved in a `Filesystem` can be stored on a `Model`")
        }

        row.put(sql: path, at: key)
    }
    
    // MARK: - ResponseConvertible
    
    public func response() async throws -> Response {
        try await _response(disposition: .inline(filename: name.inQuotes))
    }

    public func download() async throws -> Response {
        try await _response(disposition: .attachment(filename: name.inQuotes))
    }

    private func _response(disposition: HTTPFields.ContentDisposition? = nil) async throws -> Response {
        let content = try await getContent()
        let response = Response(status: .ok, body: content, contentType: contentType)
        response.headers.contentDisposition = disposition
        response.headers.contentLength = size
        return response
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
        
        try container.encode(content.data)
    }
}

// As of now, streamed files aren't possible over request multipart.
extension File: MultipartPartConvertible {
    public var multipart: MultipartPart? {
        var headers: HTTPFields = [:]
        headers.contentType = contentType
        headers.contentDisposition = HTTPFields.ContentDisposition(value: "form-data", name: nil, filename: name)
        headers.contentLength = size
        guard let content = self.content else {
            Log.warning("Unable to convert a filesystem reference to a `MultipartPart`. Please load the contents of the file first.")
            return nil
        }
        
        return MultipartPart(headers: headers.nioHeaders, body: content.data)
    }
    
    public init?(multipart: MultipartPart) {
        let fileExtension = multipart.fields.contentType?.fileExtension.map { ".\($0)" } ?? ""
        let fileName = multipart.fields.contentDisposition?.filename ?? multipart.fields.contentDisposition?.name
        let fileSize = multipart.fields.contentLength ?? multipart.body.writerIndex

        if multipart.fields.contentDisposition?.filename == nil {
            Log.warning("A multipart part had no name or filename in the Content-Disposition header, using a random UUID for the file name.")
        }

        // If there is no filename in the content disposition included (technically not required via RFC 7578) set to a random UUID.
        let name = (fileName ?? UUID().uuidString) + fileExtension
        let contentType = multipart.fields.contentType
        self.init(name: name, source: .http(clientContentType: contentType), content: .buffer(multipart.body), size: fileSize)
    }
}

extension MultipartPart {
    var fields: HTTPFields {
        HTTPFields(headers, splitCookie: false)
    }
}

extension HTTPFields {
    var nioHeaders: HTTPHeaders {
        .init(map { ($0.name.rawName, $0.value) })
    }
}
