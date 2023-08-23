import AsyncHTTPClient

extension Client.Response {
    
    // MARK: Status Information

    public var isOk: Bool { status == .ok }
    public var isSuccessful: Bool { (200...299).contains(status.code) }
    public var isFailed: Bool { isClientError || isServerError }
    public var isClientError: Bool { (400...499).contains(status.code) }
    public var isServerError: Bool { (500...599).contains(status.code) }
    
    public func validateSuccessful() throws -> Self {
        guard isSuccessful else {
            throw ClientError(message: "The response code was not successful", request: request, response: self)
        }
        
        return self
    }
    
    // MARK: Headers
    
    public func header(_ name: String) -> String? { headers.first(name: name) }
    
    // MARK: Body
    
    public var data: Data? { body?.data() }
    public var string: String? { body?.string() }
    
    public func decode<D: Decodable>(_ type: D.Type = D.self, using decoder: ContentDecoder = ByteContent.defaultDecoder) throws -> D {
        guard let buffer = body?.buffer else {
            throw ClientError(message: "The response had no body to decode from.", request: request, response: self)
        }

        do {
            return try decoder.decodeContent(D.self, from: buffer, contentType: headers.contentType)
        } catch {
            throw ClientError(message: "Error decoding `\(D.self)`. \(error)", request: request, response: self)
        }
    }
}

/// An error encountered when making a `Client` request.
public struct ClientError: Error, CustomStringConvertible {
    /// What went wrong.
    public let message: String
    /// The associated `HTTPClient.Request`.
    public let request: Client.Request
    /// The associated `HTTPClient.Response`.
    public let response: Client.Response
    
    // MARK: - CustomStringConvertible
    
    public var description: String {
        return """
            *** HTTP Client Error ***
            \(message)
            
            *** Request ***
            URL: \(request.method.rawValue) \(request.url.absoluteString)
            Headers: [
                \(debugString(for: request.headers))
            ]
            Body: \(debugString(for: request.body))

            *** Response ***
            Status: \(response.status.code) \(response.status.reasonPhrase)
            Headers: [
                \(debugString(for: response.headers))
            ]
            Body: \(debugString(for: response.body))
            """
    }

    private func debugString(for headers: HTTPHeaders) -> String {
        if Env.LOG_FULL_CLIENT_ERRORS == true || Env.isDebug {
            return headers.map { "\($0): \($1)" }.joined(separator: "\n    ")
        } else {
            return headers.map { "\($0.name)" }.joined(separator: "\n    ")
        }
    }

    private func debugString(for content: ByteContent?) -> String {
        guard let content else {
            return "<empty>"
        }

        if Env.LOG_FULL_CLIENT_ERRORS == true || Env.isDebug {
            switch content {
            case .buffer(let buffer):
                return buffer.string
            case .stream:
                return "<stream>"
            }
        } else {
            switch content {
            case .buffer(let buffer):
                return "<\(buffer.readableBytes) bytes>"
            case .stream:
                return "<stream>"
            }
        }
    }
}
