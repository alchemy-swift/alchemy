import NIOHTTP1

/// An HTTPResponse as you'll commonly see in web frameworks. This response can be a failure or success case depending on the status code in the `head`
public struct HTTPResponse {
    /// The success or failure status and HTTP headers
    public let head: HTTPResponseHead
  
    /// The body which contains any data you want to send back to the client
    /// This can be HTML, an image or JSON among many other data types
    public let body: HTTPBody?
  
    /// Creates a new response using a status code, headers and body
    /// If no headers are provided, an empty list will be assumed
    ///
    /// The body's content-length and mimeType will overwrite those that may be present in the header
    public init(status: HTTPResponseStatus,
                headers: HTTPHeaders = HTTPHeaders(),
                body: HTTPBody?) {
        self.head = HTTPResponseHead(version: HTTPVersion(major: 1, minor: 1),
                                     status: status,
                                     headers: headers)
        self.body = body
    }
}
