import Hummingbird
import MultipartKit

public protocol ContentInspector: Extendable {
    var headers: HTTPHeaders { get }
    var body: ByteContent? { get }
}

extension ContentInspector {
    
    // MARK: Files
    
    /// Get any attached file with the given name from this request.
    public func file(_ name: String) async throws -> File? {
        files()[name]
    }
    
    /// Any files attached to this content, keyed by their multipart name
    /// (separate from filename). Only populated if this content is
    /// associated with a multipart request containing files.
    ///
    /// Async since the request may need to finish streaming before we get the
    /// files.
    public func files() -> [String: File] {
        guard !content().allKeys.isEmpty else {
            return [:]
        }
        
        let content = content()
        let files = Set(content.allKeys).compactMap { key -> (String, File)? in
            guard let file = content[key].value?.file else {
                return nil
            }
            
            return (key, file)
        }
        
        return Dictionary(uniqueKeysWithValues: files)
    }
    
    // MARK: Partial Content
    
    public subscript(dynamicMember member: String) -> Content {
        if let int = Int(member) {
            return self[int]
        } else {
            return self[member]
        }
    }
    
    public subscript(index: Int) -> Content {
        content()[index]
    }
    
    public subscript(field: String) -> Content {
        content()[field]
    }
    
    func content() -> Content {
        if let content = _content {
            return content
        } else {
            guard let body = body else {
                return Content(error: ContentError.emptyBody)
            }
            
            guard let decoder = preferredDecoder() else {
                return Content(error: ContentError.unknownContentType(headers.contentType))
            }
            
            let content = decoder.content(from: body.buffer, contentType: headers.contentType)
            _content = content
            return content
        }
    }
    
    private var _content: Content? {
        get { extensions.get(\._content) }
        nonmutating set { extensions.set(\._content, value: newValue) }
    }
    
    // MARK: Content
    
    /// Decodes the content as a decodable, based on it's content type or with
    /// the given content decoder.
    ///
    /// - Parameters:
    ///   - type: The Decodable type to which the body should be decoded.
    ///   - decoder: The decoder with which to decode. Defaults to
    ///     `Content.defaultDecoder`.
    /// - Throws: Any errors encountered during decoding.
    /// - Returns: The decoded object of type `type`.
    public func decode<D: Decodable>(as type: D.Type = D.self, with decoder: ContentDecoder? = nil) throws -> D {
        guard let buffer = body?.buffer else {
            throw ValidationError("expecting a request body")
        }
        
        guard let decoder = decoder else {
            guard let preferredDecoder = preferredDecoder() else {
                throw HTTPError(.notAcceptable)
            }
            
            return try preferredDecoder.decodeContent(type, from: buffer, contentType: headers.contentType)
        }
        
        return try decoder.decodeContent(type, from: buffer, contentType: headers.contentType)
    }
    
    public func preferredDecoder() -> ContentDecoder? {
        guard let contentType = headers.contentType else {
            return ByteContent.defaultDecoder
        }
        
        switch contentType {
        case .json:
            return .json
        case .urlForm:
            return .urlForm
        case .multipart(boundary: ""):
            return .multipart
        default:
            return nil
        }
    }
    
    /// A dictionary with the contents of this Request's body.
    /// - Throws: Any errors from decoding the body.
    /// - Returns: A [String: Any] with the contents of this Request's
    ///   body.
    public func decodeBodyDict() throws -> [String: Any]? {
        try body?.decodeJSONDictionary()
    }
    
    /// Decodes the request body to the given type using the given
    /// `JSONDecoder`.
    ///
    /// - Returns: The type, decoded as JSON from the request body.
    public func decodeBodyJSON<T: Decodable>(as type: T.Type = T.self, with decoder: JSONDecoder = JSONDecoder()) throws -> T {
        do {
            return try decode(as: type, with: decoder)
        } catch let DecodingError.keyNotFound(key, context) {
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            let pathWithKey = path.isEmpty ? key.stringValue : "\(path).\(key.stringValue)"
            throw ValidationError("Missing field `\(pathWithKey)` from request body.")
        } catch let DecodingError.typeMismatch(type, context) {
            let key = context.codingPath.last?.stringValue ?? "unknown"
            throw ValidationError("Request body field `\(key)` should be a `\(type)`.")
        } catch {
            throw ValidationError("Invalid request body.")
        }
    }
}

extension Array {
    func removingFirst() -> [Element] {
        Array(dropFirst())
    }
}
