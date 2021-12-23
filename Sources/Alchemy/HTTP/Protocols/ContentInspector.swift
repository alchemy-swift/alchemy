import Hummingbird
import MultipartKit

public protocol ContentInspector {
    var headers: HTTPHeaders { get }
    var body: ByteContent? { get }
    var extensions: HBExtensions<Self> { get set }
}

// The content of an HTTP message.
@dynamicMemberLookup
public struct Content2: Decodable, Buildable {
    enum PathItem {
        case field(String)
        case index(Int)
    }
    
    struct GenericCodingKey: CodingKey {
        let stringValue: String
        let intValue: Int?
        
        init(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = Int(stringValue)
        }
        
        init(intValue: Int) {
            self.intValue = intValue
            self.stringValue = String(intValue)
        }
    }
    
    enum State {
        case decoder(Decoder)
        case error(Error)
    }
    
    enum DecodeState {
        case initial(Decoder)
        case keyed(KeyedDecodingContainer<GenericCodingKey>, key: String)
        case unkeyed(UnkeyedDecodingContainer, index: Int)
        
        func decode<D: Decodable>(_ type: D.Type = D.self, at path: [PathItem]) throws -> D {
            switch self {
            case .initial(let decoder):
                return try decodeInitial(decoder: decoder, at: path)
                
            case .keyed(let container, let key):
                return try decodeKeyed(container: container, key: key, at: path)
                
            case .unkeyed(let container, let index):
                return try decodeUnkeyed(container: container, index: index, at: path)
            }
        }
        
        private func decodeInitial<T: Decodable>(decoder: Decoder, at path: [PathItem]) throws -> T {
            guard let first = path.first else {
                return try decoder.singleValueContainer().decode(T.self)
            }
            
            switch first {
            case .index(let index):
                let container = try decoder.unkeyedContainer()
                return try DecodeState.unkeyed(container, index: index).decode(at: path.removingFirst())
            case .field(let field):
                let container = try decoder.container(keyedBy: GenericCodingKey.self)
                return try DecodeState.keyed(container, key: field).decode(at: path.removingFirst())
            }
        }
        
        private func decodeKeyed<T: Decodable>(container: KeyedDecodingContainer<GenericCodingKey>, key: String, at path: [PathItem]) throws -> T {
            guard let first = path.first else {
                return try container.decode(T.self, forKey: GenericCodingKey(stringValue: key))
            }
            
            switch first {
            case .index(let index):
                let container = try container.nestedUnkeyedContainer(forKey: GenericCodingKey(stringValue: key))
                return try DecodeState.unkeyed(container, index: index).decode(at: path.removingFirst())
            case .field(let field):
                let container = try container.nestedContainer(keyedBy: GenericCodingKey.self, forKey: GenericCodingKey(stringValue: key))
                return try DecodeState.keyed(container, key: field).decode(at: path.removingFirst())
            }
        }
        
        private func decodeUnkeyed<T: Decodable>(container: UnkeyedDecodingContainer, index: Int, at path: [PathItem]) throws -> T {
            guard index < container.count ?? 0 else {
                throw DecodingError.valueNotFound(T.self, .init(codingPath: [], debugDescription: "Index out of bounds. Array had \(container.count ?? 0) elements and index was \(index)."))
            }
            
            // Move to index.
            var containerCopy = container
            for _ in 0..<index { _ = try containerCopy.decode(Empty.self) }
            
            guard let first = path.first else {
                return try containerCopy.decode(T.self)
            }
            
            switch first {
            case .index(let index):
                let container = try containerCopy.nestedUnkeyedContainer()
                return try DecodeState.unkeyed(container, index: index).decode(at: path.removingFirst())
            case .field(let field):
                let container = try containerCopy.nestedContainer(keyedBy: GenericCodingKey.self)
                return try DecodeState.keyed(container, key: field).decode(at: path.removingFirst())
            }
        }
    }
    
    // MARK: Values
    
    public var string: String { get throws { try decode() } }
    public var int: Int { get throws { try decode() } }
    public var bool: Bool { get throws { try decode() } }
    public var double: Double { get throws { try decode() } }
    public var exists: Bool { (try? decode(Empty.self)) != nil }
    public var isNull: Bool { get throws { try self == nil } }
    
    // MARK: Array
    public var array: [Content2] {
        get throws {
            (try decode([Empty].self))
                .enumerated()
                .map { index, _ in with(.index(index)) }
        }
    }
    
    let state: State
    var path: [PathItem]
    
    init(state: State, path: [PathItem] = []) {
        self.state = state
        self.path = path
    }
    
    func decode<D: Decodable>(_ type: D.Type = D.self) throws -> D {
        switch state {
        case .decoder(let decoder):
            return try DecodeState.initial(decoder).decode(at: path)
        case .error(let error):
            throw error
        }
    }
    
    public init(from decoder: Decoder) throws {
        self.state = .decoder(decoder)
        self.path = []
    }
    
    public subscript(dynamicMember member: String) -> Content2 {
        if let int = Int(member) {
            return self[int]
        } else {
            return self[member]
        }
    }
    
    public subscript(operator: (Content, Content) -> Void) -> [Content2] {
        flatten()
    }
    
    public subscript(index: Int) -> Content2 {
        with(.index(index))
    }
    
    public subscript(field: String) -> Content2 {
        with(.field(field))
    }
    
    public func flatten() -> [Content2] {
        array
    }
    
    fileprivate func with(_ item: PathItem) -> Content2 {
        with { $0.path.append(item) }
    }
    
    /// Flatten operator.
    static func *(lhs: Content2, rhs: Content2) {}
    
    static var nilBodyError: DecodingError {
        DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Content had no body."))
    }
    
    static func unknownContentType(type: ContentType) -> DecodingError {
        DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "No decoders available for Content-Type: `\(type.value)`."))
    }
    
    static func ==(lhs: Content2, rhs: Void?) throws -> Bool {
        try lhs.decode(Optional<Empty>.self) == nil
    }
    
    static func ==<E: Decodable & Equatable>(lhs: Content2, rhs: E) throws -> Bool {
        try lhs.decode(E.self) == rhs
    }
}

extension ContentInspector {
    
    // MARK: Partial Content
    
    public subscript(dynamicMember member: String) -> Content2 {
        if let int = Int(member) {
            return self[int]
        } else {
            return self[member]
        }
    }
    
    public subscript(index: Int) -> Content2 {
        content().with(.index(index))
    }
    
    public subscript(field: String) -> Content2 {
        content().with(.field(field))
    }
    
    func content() -> Content2 {
        guard let body = body else {
            return Content2(state: .error(Content2.nilBodyError))
        }
        
        guard let decoder = preferredDecoder() else {
            return Content2(state: .error(Content2.unknownContentType(type: headers.contentType ?? ContentType("<missing>"))))
        }
        
        do {
            return try decoder.decodeContent(Content2.self, from: body.buffer, contentType: headers.contentType)
        } catch {
            return Content2(state: .error(error))
        }
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
    
    // MARK: Files
    
    private var _files: [String: File]? {
        get { extensions.get(\._files) }
        set { extensions.set(\._files, value: newValue) }
    }
    
    /// Get any attached file with the given name from this request.
    public mutating func file(_ name: String) async throws -> File? {
        try await files()[name]
    }
    
    /// Any files attached to this content, keyed by their multipart name
    /// (separate from filename). Only populated if this content is
    /// associated with a multipart request containing files.
    ///
    /// Async since the request may need to finish streaming before we get the
    /// files.
    public mutating func files() async throws -> [String: File] {
        guard let alreadyLoaded = _files else {
            return try await loadFiles()
        }
        
        return alreadyLoaded
    }
    
    /// Currently loads all files into memory. Should store files larger than
    /// some size into a temp directory.
    private mutating func loadFiles() async throws -> [String: File] {
        guard headers.contentType == .multipart else {
            return [:]
        }
        
        guard let boundary = headers.contentType?.parameters["boundary"] else {
            throw HTTPError(.notAcceptable)
        }
        
        guard let stream = body?.stream else {
            return [:]
        }
        
        let parser = MultipartParser(boundary: boundary)
        var parts: [MultipartPart] = []
        var headers: HTTPHeaders = .init()
        var body: ByteBuffer = ByteBuffer()

        parser.onHeader = { headers.replaceOrAdd(name: $0, value: $1) }
        parser.onBody = { body.writeBuffer(&$0) }
        parser.onPartComplete = {
            parts.append(MultipartPart(headers: headers, body: body))
            headers = [:]
            body = ByteBuffer()
        }

        for try await chunk in stream {
            try parser.execute(chunk)
        }
        
        var files: [String: File] = [:]
        for part in parts {
            guard
                let disposition = part.headers.contentDisposition,
                let name = disposition.name,
                let filename = disposition.filename
            else { continue }
            files[name] = File(name: filename, size: part.body.writerIndex, content: .buffer(part.body))
        }
        
        _files = files
        return files
    }
}

extension Array {
    func removingFirst() -> [Element] {
        Array(dropFirst())
    }
}
