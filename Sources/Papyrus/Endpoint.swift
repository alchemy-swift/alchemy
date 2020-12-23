/// `Endpoint` is an abstraction around making REST requests. It includes a `Request` type,
/// representing the data needed to make the request, and a `Response` type, representing the
/// expected response from the server.
///
/// `Endpoint`s are defined via property wrapped (@GET, @POST, etc...) properties on an
/// `EndpointGroup`.
///
/// `Endpoint`s are intended to be used on either client or server for requesting external endpoints
/// or on server for providing and validating endpoints.
public struct Endpoint<Request: EndpointRequest, Response: Codable> {
    /// The method, or verb, of this endpoint.
    public let method: EndpointMethod
    
    /// The path of this endpoint, relative to `self.baseURL`
    public var path: String
    
    /// The `baseURL` of this endpoint.
    public var baseURL: String = ""
    
    /// Creates a copy of this `Endpoint` with the provided `baseURL`.
    ///
    /// - Parameter baseURL: the baseURL of the copy of this `Endpoint`.
    /// - Returns: a copy of this `Endpoint` with the provided `baseURL`.
    public func with(baseURL: String) -> Self {
        var copy = self
        copy.baseURL = baseURL
        return copy
    }
}

/// A type that can be the `Request` type of an `Endpoint`.
public protocol EndpointRequest: Codable {}

extension EndpointRequest {
    /// Initialize this request data from a `DecodableRequest`. Useful for loading expected request
    /// data from incoming requests on the provider of this `Endpoint`.
    ///
    /// - Parameters:
    ///   - request: the request to initialize this type from.
    /// - Throws: any error encountered while decoding this type from the request.
    public init(from request: DecodableRequest) throws {
        try self.init(from: RequestDecoder(request: request, keyMapping: { $0 }))
    }
}

extension DecodableRequest {
    public func decodeRequest<E: EndpointRequest>(_ requestType: E.Type = E.self) throws -> E {
        try E(from: self)
    }
}
