import AsyncHTTPClient

public struct ClientResponse {
    public let request: HTTPClient.Request
    public let response: HTTPClient.Response
    
    // MARK: Status Information
    
    public var status: HTTPResponseStatus {
        response.status
    }
    
    public var isOk: Bool {
        status == .ok
    }
    
    public var isSuccessful: Bool {
        (200...299).contains(status.code)
    }
    
    public var isFailed: Bool {
        isClientError || isServerError
    }
    
    public var isClientError: Bool {
        (400...499).contains(status.code)
    }
    
    public var isServerError: Bool {
        (500...599).contains(status.code)
    }
    
    // MARK: Headers
    
    public var headers: [(String, String)] {
        response.headers.map { ($0, $1) }
    }
    
    public func header(_ name: String) -> String? {
        response.headers.first(name: name)
    }
    
    // MARK: Body
    
    public var bodyData: Data? {
        response.body?.data()
    }
    
    public var bodyString: String? {
        response.body?.string()
    }
    
    public func decode<D: Decodable>(_ type: D.Type = D.self, using jsonDecoder: JSONDecoder = JSONDecoder()) throws -> D {
        try jsonDecoder.decode(
            D.self,
            from: bodyData.unwrap(or: ClientError("The request had no body to decode JSON from.")))
    }
}

extension ByteBuffer {
    func data() -> Data? {
        var copy = self
        return copy.readData(length: writerIndex)
    }
    
    func string() -> String? {
        var copy = self
        return copy.readString(length: writerIndex)
    }
}
