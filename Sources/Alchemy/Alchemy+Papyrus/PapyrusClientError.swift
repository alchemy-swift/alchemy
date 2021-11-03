import AsyncHTTPClient

/// An error that occurred when requesting a `Papyrus.Endpoint`.
public struct PapyrusClientError: Error {
    /// What went wrong.
    public let message: String
    /// The `HTTPClient.Request` that initiated the failed response.
    public let request: HTTPClient.Request
    /// The `HTTPClient.Response` of the failed response.
    public let response: HTTPClient.Response
}

extension PapyrusClientError: CustomStringConvertible {
    public var description: String {
        """
        \(message)
        
        *** Request ***
        URL: \(request.method.rawValue) \(request.url.absoluteString)
        Headers: [
            \(request.headers.map { "\($0) \($1)" }.joined(separator: "\n    "))
        ]
        Body Exists: \(request.body != nil)
        
        *** Response ***
        Status: \(response.status.code) \(response.status.reasonPhrase)
        Headers: [
            \(response.headers.map { "\($0) \($1)" }.joined(separator: "\n    "))
        ]
        Body: \(response.body?.jsonString ?? "N/A")
        """
    }
}

extension ByteBuffer {
    fileprivate var jsonString: String? {
        var copy = self
        if
            let data = copy.readData(length: copy.writerIndex),
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
