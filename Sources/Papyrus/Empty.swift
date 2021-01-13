/// Represents an Empty request or response on an `Endpoint`.
///
/// A workaround for not being able to conform `Void` to `Codable`.
public struct Empty: EndpointRequest {
    /// Static `Empty` instance used for all `Empty` responses and
    /// requests.
    public static let value = Empty()
}
