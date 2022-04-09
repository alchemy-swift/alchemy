import NIOHTTP1
import HummingbirdFoundation
import MultipartKit

public protocol ContentBuilder: Buildable {
    var headers: HTTPHeaders { get set }
    var body: ByteContent? { get set }
}

extension ContentBuilder {
    // MARK: - Headers
    
    public func withHeader(_ name: String, value: String) -> Self {
        with { $0.headers.add(name: name, value: value) }
    }
    
    public func withHeaders(_ dict: [String: String]) -> Self {
        dict.reduce(self) { $0.withHeader($1.key, value: $1.value) }
    }
    
    public func withBasicAuth(username: String, password: String) -> Self {
        let basicAuthString = Data("\(username):\(password)".utf8).base64EncodedString()
        return withHeader("Authorization", value: "Basic \(basicAuthString)")
    }
    
    public func withToken(_ token: String) -> Self {
        withHeader("Authorization", value: "Bearer \(token)")
    }
    
    public func withContentType(_ contentType: ContentType) -> Self {
        withHeader("Content-Type", value: contentType.string)
    }
    
    // MARK: - Body
    
    public func withBody(_ content: ByteContent, type: ContentType? = nil, length: Int? = nil) -> Self {
        guard body == nil else {
            preconditionFailure("A request body should only be set once.")
        }
        
        return with {
            $0.body = content
            $0.headers.contentType = type
            $0.headers.contentLength = length ?? content.length
        }
    }
    
    public func withBody(data: Data) -> Self {
        withBody(.data(data))
    }
    
    public func withBody(buffer: ByteBuffer) -> Self {
        withBody(.buffer(buffer))
    }
    
    public func withBody<E: Encodable>(_ value: E, encoder: ContentEncoder = .json) throws -> Self {
        let (buffer, type) = try encoder.encodeContent(value)
        return withBody(.buffer(buffer), type: type)
    }
    
    public func withJSON(_ dict: [String: Any?]) throws -> Self {
        withBody(try .json(dict), type: .json)
    }
    
    public func withJSON<E: Encodable>(_ json: E, encoder: JSONEncoder = JSONEncoder()) throws -> Self {
        try withBody(json, encoder: encoder)
    }
    
    public func withForm(_ dict: [String: Any?]) throws -> Self {
        withBody(try .json(dict), type: .urlForm)
    }
    
    public func withForm<E: Encodable>(_ form: E, encoder: URLEncodedFormEncoder = URLEncodedFormEncoder()) throws -> Self {
        try withBody(form, encoder: encoder)
    }
    
    public func attach(_ name: String, contents: ByteBuffer, filename: String? = nil, encoder: FormDataEncoder = FormDataEncoder()) async throws -> Self {
        let file = File(name: filename ?? name, content: .buffer(contents), size: contents.writerIndex)
        return try withBody([name: file], encoder: encoder)
    }
    
    public func attach(_ name: String, file: File, encoder: FormDataEncoder = FormDataEncoder()) async throws -> Self {
        var copy = file
        return try withBody([name: await copy.collect()], encoder: encoder)
    }
    
    public func attach(_ files: [String: File], encoder: FormDataEncoder = FormDataEncoder()) async throws -> Self {
        var collectedFiles: [String: File] = [:]
        for (name, var file) in files {
            collectedFiles[name] = try await file.collect()
        }
        
        return try withBody(files, encoder: encoder)
    }
}
