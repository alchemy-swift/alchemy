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
    
    func validateSuccessful() throws -> Self {
        try wrapDebug {
            guard isSuccessful else {
                throw ClientError(
                    message: "The response code was not successful",
                    request: request,
                    response: response
                )
            }
            
            return self
        }
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
    
    public func decodeJSON<D: Decodable>(_ type: D.Type = D.self, using jsonDecoder: JSONDecoder = JSONDecoder()) throws -> D {
        try wrapDebug {
            guard let bodyData = bodyData else {
                throw ClientError(
                    message: "The response had no body to decode JSON from.",
                    request: request,
                    response: response
                )
            }

            do {
                return try jsonDecoder.decode(D.self, from: bodyData)
            } catch {
                throw ClientError(
                    message: "Error decoding `\(D.self)` from a `ClientResponse`. \(error)",
                    request: request,
                    response: response
                )
            }
        }
    }
}

extension ClientResponse {
    func wrapDebug<T>(_ closure: () throws -> T) throws -> T {
        do {
            return try closure()
        } catch let clientError as ClientError {
            clientError.logDebug()
            throw clientError
        } catch {
            throw error
        }
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
