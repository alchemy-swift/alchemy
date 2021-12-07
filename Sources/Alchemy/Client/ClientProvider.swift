import Foundation
import HummingbirdFoundation
import MultipartKit
import NIOHTTP1

public protocol ClientProvider {
    associatedtype Res
    associatedtype Builder: RequestBuilder where Builder.Builder == Builder, Builder.Res == Res
    
    var builder: Builder { get }
}

public protocol RequestBuilder: ClientProvider  {
    var partialRequest: Client.Request { get set }
    func execute() async throws -> Res
}

extension ClientProvider {
    
    // MARK: Base Builder
    
    public func with(requestConfiguration: (inout Client.Request) -> Void) -> Builder {
        var builder = builder
        requestConfiguration(&builder.partialRequest)
        return builder
    }
    
    // MARK: Queries
    
    public func withQuery(_ name: String, value: String?) -> Builder {
        with { request in
            let newItem = URLQueryItem(name: name, value: value)
            if let existing = request.urlComponents.queryItems {
                request.urlComponents.queryItems = existing + [newItem]
            } else {
                request.urlComponents.queryItems = [newItem]
            }
        }
    }
    
    public func withQueries(_ dict: [String: String]) -> Builder {
        dict.reduce(builder) { $0.withQuery($1.key, value: $1.value) }
    }
    
    // MARK: - Headers
    
    public func withHeader(_ name: String, value: String) -> Builder {
        with { $0.headers.add(name: name, value: value) }
    }
    
    public func withHeaders(_ dict: [String: String]) -> Builder {
        dict.reduce(builder) { $0.withHeader($1.key, value: $1.value) }
    }
    
    public func withBasicAuth(username: String, password: String) -> Builder {
        let basicAuthString = Data("\(username):\(password)".utf8).base64EncodedString()
        return withHeader("Authorization", value: "Basic \(basicAuthString)")
    }
    
    public func withBearerAuth(_ token: String) -> Builder {
        withHeader("Authorization", value: "Bearer \(token)")
    }
    
    public func withContentType(_ contentType: ContentType) -> Builder {
        withHeader("Content-Type", value: contentType.string)
    }
    
    // MARK: - Body
    
    public func withBody(_ content: ByteContent, type: ContentType? = nil, length: Int? = nil) -> Builder {
        guard builder.partialRequest.body == nil else {
            preconditionFailure("A request body should only be set once.")
        }
        
        return with {
            $0.body = content
            $0.headers.contentType = type
            $0.headers.contentLength = length ?? content.length
        }
    }
    
    public func withBody(_ data: Data) -> Builder {
        withBody(.data(data))
    }
    
    public func withBody<E: Encodable>(_ value: E, encoder: ContentEncoder = .json) throws -> Builder {
        let content = try encoder.encodeContent(value)
        return withBody(.buffer(content.buffer), type: content.type)
    }
    
    public func withJSON(_ dict: [String: Any?]) throws -> Builder {
        withBody(try .jsonDict(dict), type: .json)
    }
    
    public func withJSON<E: Encodable>(_ json: E, encoder: JSONEncoder = JSONEncoder()) throws -> Builder {
        try withBody(json, encoder: encoder)
    }
    
    public func withForm(_ dict: [String: Any?]) throws -> Builder {
        withBody(try .jsonDict(dict), type: .urlForm)
    }
    
    public func withForm<E: Encodable>(_ form: E, encoder: URLEncodedFormEncoder = URLEncodedFormEncoder()) throws -> Builder {
        try withBody(form, encoder: encoder)
    }
    
    public func withAttachment(_ name: String, file: File, encoder: FormDataEncoder = FormDataEncoder()) async throws -> Builder {
        var copy = file
        return try withBody([name: await copy.collect()], encoder: encoder)
    }
    
    public func withAttachments(_ files: [String: File], encoder: FormDataEncoder = FormDataEncoder()) async throws -> Builder {
        var collectedFiles: [String: File] = [:]
        for (name, var file) in files {
            collectedFiles[name] = try await file.collect()
        }
        
        return try withBody(files, encoder: encoder)
    }
    
    // MARK: Methods
    
    public func withBaseUrl(_ url: String) -> Builder {
        with {
            var newComponents = URLComponents(string: url)
            if let oldQueryItems = $0.urlComponents.queryItems {
                let newQueryItems = newComponents?.queryItems ?? []
                newComponents?.queryItems = newQueryItems + oldQueryItems
            }
            
            $0.urlComponents = newComponents ?? URLComponents()
        }
    }
    
    public func withMethod(_ method: HTTPMethod) -> Builder {
        with { $0.method = method }
    }
    
    public func execute() async throws -> Res {
        try await builder.execute()
    }
    
    public func request(_ method: HTTPMethod, uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(method).execute()
    }
    
    public func get(_ uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(.GET).execute()
    }
    
    public func post(_ uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(.POST).execute()
    }
    
    public func put(_ uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(.PUT).execute()
    }
    
    public func patch(_ uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(.PATCH).execute()
    }
    
    public func delete(_ uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(.DELETE).execute()
    }
    
    public func options(_ uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(.OPTIONS).execute()
    }
    
    public func head(_ uri: String) async throws -> Res {
        try await withBaseUrl(uri).withMethod(.HEAD).execute()
    }
}
