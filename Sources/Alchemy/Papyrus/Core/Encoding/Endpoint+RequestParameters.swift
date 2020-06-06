import Foundation
import NIOHTTP1

/// Conform your request objects to this.
public extension Endpoint {
    func parameters(dto: Req) throws -> RequestParameters {
        let helper = EncodingHelper(dto)
        return RequestParameters(
            method: self.method,
            headers: helper.getHeaders(),
            basePath: self.basePath,
            query: helper.queryString(),
            fullPath: try helper.getFullPath(self.basePath),
            body: try helper.getBody()
        )
    }
}

public struct RequestParameters {
    public let method: HTTPMethod
    public let headers: [String: String]
    public let basePath: String
    public let query: String
    public let fullPath: String
    public let body: (content: AnyEncodable, contentType: ContentType)?
    
    public static func just(url: String, method: HTTPMethod) -> RequestParameters {
        RequestParameters(method: method, headers: [:], basePath: url, query: "", fullPath: url, body: nil)
    }
    
    func urlParams() throws -> String? {
        guard let body = body, body.contentType == .urlEncoded else {
            return nil
        }
        
        let encoder = URLFormEncoder()
        return try ";" + encoder.encode(body.content)
    }
}

struct EncodingHelper {
    private var bodies: [String: AnyBody] = [:]
    private var headers: [String: AnyHeader] = [:]
    private var queries: [String: AnyQuery] = [:]
    private var paths: [String: AnyPath] = [:]

    fileprivate init<T>(_ value: T) {
        if let value = value as? BodyCodable {
            self.bodies["body"] = ErasedBody(content: value.toAny(), contentType: .json)
            return
        }
        Mirror(reflecting: value)
            .children
            .forEach { child in
                guard let label = child.label else {
                    return print("No label on a child")
                }

                let sanitizedLabel = String(label.dropFirst())
                if let query = child.value as? AnyQuery {
                    self.queries[sanitizedLabel] = query
                } else if let body = child.value as? AnyBody {
                    self.bodies[sanitizedLabel] = body
                } else if let header = child.value as? AnyHeader {
                    self.headers[header.keyOverride ?? sanitizedLabel] = header
                } else if let path = child.value as? AnyPath {
                    self.paths[sanitizedLabel] = path
                }
            }
    }

    func getFullPath(_ basePath: String) throws -> String {
        try self.replacedPath(basePath) + self.queryString()
    }

    private func replacedPath(_ basePath: String) throws -> String {
        try self.paths.reduce(into: basePath) { basePath, component in
            guard basePath.contains(":\(component.key)") else {
                throw PapyrusError("Tried to encode path component '\(component.key)' but didn't find any instance of ':\(component.key)' in the path.")
            }

            basePath = basePath.replacingOccurrences(of: ":\(component.key)", with: component.value.value)
        }
    }

    func queryString() -> String {
        self.queries.isEmpty ? "" :
            "?" + self.queries.sorted { $0.key < $1.key }
            .reduce(into: []) { list, query in
                list += self.queryComponents(fromKey: query.key, value: query.value.value)
            }
            .map { "\($0)" + ($1.isEmpty ? "" : "=\($1)") }
            .joined(separator: "&")
    }

    func getBody() throws -> (content: AnyEncodable, contentType: ContentType)? {
        guard self.bodies.count <= 1 else {
            throw PapyrusError("Only one `@Body` attribute is allowed per request.")
        }
        
        return self.bodies.first.map { ($0.value.content, $0.value.contentType) }
    }
    
    func getHeaders() -> [String: String] {
        self.headers.reduce(into: [String: String]()) { dict, val in
            dict[val.key] = val.value.value
        }
    }
}
