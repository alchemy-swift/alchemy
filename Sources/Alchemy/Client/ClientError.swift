import AsyncHTTPClient

/// An error encountered when making a `Client` request.
public struct ClientError: Error {
    /// What went wrong.
    public let message: String
    /// The `HTTPClient.Request` that initiated the failed response.
    public let request: Client.Request
    /// The `HTTPClient.Response` of the failed response.
    public let response: Client.Response
}

extension ClientError {
    /// Logs in a separate task since the only way to load the request body is
    /// asynchronously.
    func logDebug() {
        Task {
            do { Log.notice(try await debugString()) }
            catch { Log.warning("Error printing debug description for `ClientError` \(error).") }
        }
    }
    
    func debugString() async throws -> String {
        return """
            *** HTTP Client Error ***
            \(message)
            
            *** Request ***
            URL: \(request.method.rawValue) \(request.url.absoluteString)
            Headers: [
                \(request.headers.map { "\($0): \($1)" }.joined(separator: "\n    "))
            ]
            Body: \(try await request.bodyString() ?? "nil")
            
            *** Response ***
            Status: \(response.status.code) \(response.status.reasonPhrase)
            Headers: [
                \(response.headers.map { "\($0): \($1)" }.joined(separator: "\n    "))
            ]
            Body: \(response.bodyString ?? "nil")
            """
    }
}

extension Client.Request {
    fileprivate func bodyString() async throws -> String? {
        try await body?.collect().string()
    }
}
