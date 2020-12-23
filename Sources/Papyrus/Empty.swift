/// Represents an Empty request or response on an `Endpoint`.
///
/// A workaround for not being able to conform `Void` to `Codable`.
public struct Empty: EndpointRequest {
    /// Initialize the empty object.
    public init() {}
}
