import AsyncHTTPClient

extension Client.Response {
    // MARK: Status Information
    
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
                throw ClientError(message: "The response code was not successful", request: request, response: self)
            }
            
            return self
        }
    }
    
    // MARK: Headers
    
    public func header(_ name: String) -> String? {
        headers.first(name: name)
    }
    
    // MARK: Body
    
    public var bodyData: Data? {
        body?.data()
    }
    
    public var bodyString: String? {
        body?.string()
    }
    
    public func decodeJSON<D: Decodable>(_ type: D.Type = D.self, using jsonDecoder: JSONDecoder = JSONDecoder()) throws -> D {
        try wrapDebug {
            guard let bodyData = bodyData else {
                throw ClientError(
                    message: "The response had no body to decode JSON from.",
                    request: request,
                    response: self
                )
            }

            do {
                return try jsonDecoder.decode(D.self, from: bodyData)
            } catch {
                throw ClientError(
                    message: "Error decoding `\(D.self)` from a `ClientResponse`. \(error)",
                    request: request,
                    response: self
                )
            }
        }
    }
    
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
