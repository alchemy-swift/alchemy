import NIOHTTP1

/// An abstraction around writing data to a remote peer. Conform to
/// this protocol and inject it into the `Response` for responding
/// to a remote peer at a later point in time.
///
/// Be sure to call `writeEnd` when you are finished writing data or
/// the client response will never complete.
public protocol ResponseWriter {
    /// Write the status and head of a response. Should only be called
    /// once.
    ///
    /// - Parameters:
    ///   - status: The status code of the response.
    ///   - headers: Any headers of this response.
    func writeHead(status: HTTPResponseStatus, _ headers: HTTPHeaders)
    
    /// Write some body data to the remote peer. May be called 0 or
    /// more times.
    ///
    /// - Parameter body: The buffer of data to write.
    func writeBody(_ body: ByteBuffer)
    
    /// Write the end of the response. Needs to be called once per
    /// response, when all data has been written.
    func writeEnd()
}
