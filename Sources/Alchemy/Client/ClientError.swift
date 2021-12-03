import AsyncHTTPClient

/// An error encountered when making a `Client` request.
public struct ClientError: Error {
    /// What went wrong.
    public let message: String
    /// The `HTTPClient.Request` that initiated the failed response.
    public let request: HTTPClient.Request
    /// The `HTTPClient.Response` of the failed response.
    public let response: HTTPClient.Response
}

extension ClientError {
    /// Logs in a separate task since the only way to load the request body is
    /// asynchronously.
    func logDebug() {
        Task {
            do { Log.info(try await debugString()) }
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

extension HTTPClient.Request {
    fileprivate func bodyString() async throws -> String? {
        // Only debug using the last buffer that's sent through for now.
        var bodyBuffer: ByteBuffer? = nil
        let writer = HTTPClient.Body.StreamWriter { ioData in
            switch ioData {
            case .byteBuffer(let buffer):
                bodyBuffer = buffer
                return Loop.current.future()
            case .fileRegion:
                return Loop.current.future()
            }
        }
        
        try await body?.stream(writer).get()
        return bodyBuffer?.jsonString
    }
}

extension HTTPClient.Response {
    fileprivate var bodyString: String? {
        body?.jsonString
    }
}

extension ByteBuffer {
    fileprivate var jsonString: String? {
        var copy = self
        if
            let data = copy.readData(length: copy.readableBytes),
            let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
            let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        {
            return String(decoding: jsonData, as: UTF8.self)
        } else {
            var otherCopy = self
            return otherCopy.readString(length: otherCopy.writerIndex)
        }
    }
}
