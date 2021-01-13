/// `Endpoint` is an abstraction around making REST requests. It
/// includes a `Request` type, representing the data needed to
/// make the request, and a `Response` type, representing the
/// expected response from the server.
///
/// `Endpoint`s are defined via property wrapped (@GET, @POST, etc...)
/// properties on an `EndpointGroup`.
///
/// `Endpoint`s are intended to be used on either client or server for
/// requesting external endpoints or on server for providing and
/// validating endpoints. There are partner libraries
/// (`PapyrusAlamofire` and `Alchemy`) for requesting or
/// validating endpoints on client or server platforms.
public struct Endpoint<Request: EndpointRequest, Response: Codable> {
    /// The method, or verb, of this endpoint.
    public let method: EndpointMethod
    
    /// The path of this endpoint, relative to `self.baseURL`
    public var path: String
    
    /// The `baseURL` of this endpoint.
    public var baseURL: String = ""
    
    /// Creates a copy of this `Endpoint` with the provided `baseURL`.
    ///
    /// - Parameter baseURL: The baseURL for the `Endpoint`.
    /// - Returns: A copy of this `Endpoint` with the `baseURL`.
    public func with(baseURL: String) -> Self {
        var copy = self
        copy.baseURL = baseURL
        return copy
    }
}

/// Indicates the type of a request's body. The content type affects
/// how and where the content is encoded.
public enum BodyEncoding {
    /// The content of this request is encoded to its body as JSON.
    case json
    /// The content of this request is encoded to its URL.
    case urlEncoded
}

/// A type that can be the `Request` type of an `Endpoint`.
public protocol EndpointRequest: Codable {
    /// The method of encoding for the request body. Defaults to
    /// `.json`.
    static var bodyEncoding: BodyEncoding { get }
}

extension EndpointRequest {
    public static var bodyEncoding: BodyEncoding { .json }
}

extension EndpointRequest {
    /// Initialize this request data from a `DecodableRequest`. Useful
    /// for loading expected request data from incoming requests on
    /// the provider of this `Endpoint`.
    ///
    /// - Parameter request: The request to initialize this type from.
    /// - Throws: Any error encountered while decoding this type from
    ///   the request.
    public init(from request: DecodableRequest) throws {
        try self.init(from: RequestDecoder(request: request))
    }
}

extension DecodableRequest {
    /// Decodes the given `EndpointRequest` type from this request.
    ///
    /// - Parameter requestType: The type to decode. Defaults to
    ///   `E.self`.
    /// - Throws: An error encountered while decoding the type.
    /// - Returns: An instance of `E` decoded from this request.
    public func decodeRequest<E: EndpointRequest>(_ requestType: E.Type = E.self) throws -> E {
        try E(from: self)
    }
}
