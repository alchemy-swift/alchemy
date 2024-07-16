import Foundation
import MultipartKit

public protocol HTTPInspector {
    var headers: HTTPFields { get }
    var body: Bytes? { get }
    var container: Container { get }
}

extension HTTPInspector {

    // MARK: Headers

    public func header(_ name: HTTPField.Name) -> String? {
        headers[values: name].first
    }

    public func requireHeader(_ name: HTTPField.Name) throws -> String {
        guard let header = header(name) else {
            throw ValidationError("Missing header \(name).")
        }

        return header
    }

    // MARK: Body

    /// The Foundation.Data of the body
    public var data: Data? {
        body?.data
    }

    /// The `String` contents of the body
    public var string: String? {
        body?.string
    }

    /// Decodes the the given type from the body of the request based on it's
    /// content type or with the given content decoder.
    ///
    /// - Parameters:
    ///   - type: The Decodable type to which the body should be decoded.
    ///   - decoder: The decoder with which to decode.
    /// - Returns: The decoded object of type `type`.
    public func decode<D: Decodable>(_ type: D.Type = D.self, with decoder: HTTPDecoder? = nil) throws -> D {
        guard let buffer = body?.buffer else {
            throw ValidationError("expecting a request body")
        }
        
        guard let decoder = decoder else {
            guard let preferredDecoder = preferredDecoder() else {
                throw HTTPError(.notAcceptable)
            }
            
            return try preferredDecoder.decodeBody(type, from: buffer, contentType: headers.contentType)
        }
        
        do {
            return try decoder.decodeBody(type, from: buffer, contentType: headers.contentType)
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
    
    public func preferredDecoder() -> HTTPDecoder? {
        guard let contentType = headers.contentType else {
            return Bytes.defaultDecoder
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

    // MARK: Content

    /// A utility for accessing the data on a Request or Response without
    /// defining an entirely new type to decode from it.
    public var content: Content {
        get {
            guard let content = container.get(\HTTPInspector.content) else {
                let content: Content
                switch (body, preferredDecoder()) {
                case (.none, _):
                    content = Content(error: ContentError.emptyBody)
                case (_, .none):
                    content = Content(error: ContentError.unknownContentType(headers.contentType))
                case (.some(let body), .some(let decoder)):
                    content = decoder.content(from: body.buffer, contentType: headers.contentType)
                }

                container.set(\HTTPInspector.content, value: content)
                return content
            }

            return content
        }
        nonmutating set { container.set(\HTTPInspector.content, value: newValue) }
    }

    public subscript(dynamicMember member: String) -> Content {
        if let int = Int(member) {
            return self[int]
        } else {
            return self[member]
        }
    }

    public subscript(index: Int) -> Content {
        content[index]
    }

    public subscript(field: String) -> Content {
        content[field]
    }

    /// Get any attached file with the given name from this request.
    public func file(_ name: String) -> File? {
        files()[name]
    }

    /// Any files attached to this content, keyed by their multipart name
    /// (separate from filename). Only populated if this content is
    /// associated with a multipart request containing files.
    public func files() -> [String: File] {
        guard !content.allKeys.isEmpty else {
            return [:]
        }

        let files = Set(content.allKeys).compactMap { key -> (String, File)? in
            content[key].file.map { (key, $0) }
        }

        return Dictionary(uniqueKeysWithValues: files)
    }
}
