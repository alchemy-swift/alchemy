import NIOHTTP1

/// A type representing the response from an HTTP endpoint. This response can be
/// a failure or success case depending on the status code in the `head`.
public struct Response {
    /// The default `JSONEncoder` with which to encode JSON responses.
    public static var defaultJSONEncoder = JSONEncoder()
    
    /// The success or failure status and HTTP headers.
    public let head: HTTPResponseHead
  
    /// The body which contains any data you want to send back to the client
    /// This can be HTML, an image or JSON among many other data types.
    public let body: HTTPBody?
  
    /// Creates a new response using a status code, headers and body
    /// If no headers are provided, an empty list will be assumed
    ///
    /// The body's content-length and mimeType will overwrite those that may be
    /// present in the header
    ///
    /// - Parameters:
    ///   - status: the status code of this response.
    ///   - headers: any headers to return in the response.
    ///   - body: the body of this response. See `HTTPBody` for initializing
    ///           with various data.
    public init(
        status: HTTPResponseStatus,
        headers: HTTPHeaders = HTTPHeaders(),
        body: HTTPBody?)
    {
        self.head = HTTPResponseHead(version: HTTPVersion(major: 1, minor: 1),
                                     status: status,
                                     headers: headers)
        self.body = body
    }
}
