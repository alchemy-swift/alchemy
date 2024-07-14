import Hummingbird
import MultipartKit

public protocol HTTPBuilder: Buildable {
    var headers: HTTPFields { get set }
    var body: Bytes? { get set }
}

extension HTTPBuilder {
    
    // MARK: - Headers

    public func withHeader(_ name: HTTPField.Name, value: String) -> Self {
        with { $0.headers[name] = value }
    }
    
    public func withHeaders(_ dict: [HTTPField.Name: String]) -> Self {
        dict.reduce(self) { $0.withHeader($1.key, value: $1.value) }
    }
    
    public func withBasicAuth(username: String, password: String) -> Self {
        let basicAuthString = Data("\(username):\(password)".utf8).base64EncodedString()
        return withHeader(.authorization, value: "Basic \(basicAuthString)")
    }
    
    public func withToken(_ token: String) -> Self {
        withHeader(.authorization, value: "Bearer \(token)")
    }
    
    public func withContentType(_ contentType: ContentType) -> Self {
        withHeader(.contentType, value: contentType.string)
    }
    
    // MARK: - Body
    
    public func withBody(_ content: Bytes, type: ContentType? = nil, length: Int? = nil) -> Self {
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
    
    public func withBody<E: Encodable>(_ value: E, encoder: HTTPEncoder = .json) throws -> Self {
        let (buffer, type) = try encoder.encodeBody(value)
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
        let file = File(name: filename ?? name, source: .raw, content: .buffer(contents), size: contents.writerIndex)
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

extension Bytes {
    fileprivate static func json(_ dict: [String: Any?]) throws -> Bytes {
        guard JSONSerialization.isValidJSONObject(dict) else {
            let context = EncodingError.Context(codingPath: [], debugDescription: "Invalid JSON dict.")
            throw EncodingError.invalidValue(dict, context)
        }

        return .buffer(ByteBuffer(data: try JSONSerialization.data(withJSONObject: dict)))
    }
}
