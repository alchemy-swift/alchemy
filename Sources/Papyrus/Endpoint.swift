public struct Endpoint<Req: EndpointRequest, Res: Codable> {
    public let method: EndpointMethod
    public var path: String
    public var baseURL: String = ""
    
    public func with(baseURL: String) -> Self {
        var copy = self
        copy.baseURL = baseURL
        return copy
    }
}

/// The request type of a Papyrus `Endpoint`.
public protocol EndpointRequest: Codable {
    init(from request: DecodableRequest, keyMapping: @escaping (String) -> String) throws
}

extension EndpointRequest {
    public init(
        from request: DecodableRequest,
        keyMapping: @escaping (String) -> String = { $0 }
    ) throws {
        try self.init(from: HTTPRequestDecoder(request: request, keyMappingStrategy: keyMapping))
    }
}

extension DecodableRequest {
    public func decodeRequest<E: EndpointRequest>(_ requestType: E.Type = E.self) throws -> E {
        try E(from: self)
    }
}

open class EndpointGroup {
    public let baseURL: String
    
    public init(baseURL: String) {
        self.baseURL = baseURL
    }
}
