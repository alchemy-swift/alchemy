import AsyncHTTPClient
import Foundation
import NIO
import NIOHTTP1
import Papyrus

/// An error that occurred when requesting a `Papyrus.Endpoint`.
public struct PapyrusClientError: Error {
    /// What went wrong.
    public let message: String
    /// The `HTTPClient.Response` of the failed response.
    public let response: HTTPClient.Response
    /// The response body, converted to a String, if there is one.
    public var bodyString: String? {
        guard let body = response.body else {
            return nil
        }
        
        var copy = body
        return copy.readString(length: copy.writerIndex)
    }
}

extension PapyrusClientError: CustomStringConvertible {
    public var description: String {
        """
        \(message)
        Response: \(response.headers)
        Status: \(response.status.code) \(response.status.reasonPhrase)
        Body: \(bodyString ?? "N/A")
        """
    }
}

extension Endpoint {
    /// Requests a `Papyrus.Endpoint`, returning a decoded
    /// `Endpoint.Response`.
    ///
    /// - Parameters:
    ///   - dto: An instance of the request DTO; `Endpoint.Request`.
    ///   - client: The HTTPClient to request this with. Defaults to
    ///     `Client.default`.
    /// - Returns: The decoded `Endpoint.Response` and raw
    ///   `HTTPClient.Response`.
    public func request(
        _ dto: Request,
        with client: HTTPClient = .default
    ) async throws -> (content: Response, response: HTTPClient.Response) {
        try await client.performRequest(
            baseURL: baseURL,
            parameters: try parameters(dto: dto),
            encoder: jsonEncoder,
            decoder: jsonDecoder
        )
    }
}

extension Endpoint where Request == Empty {
    /// Requests a `Papyrus.Endpoint` where the `Request` type is
    /// `Empty`, returning a decoded `Endpoint.Response`.
    ///
    /// - Parameters:
    ///   - client: The HTTPClient to request this with. Defaults to
    ///     `Client.default`.
    ///   - decoder: The decoder with which to decode response data to
    ///     `Endpoint.Response`. Defaults to `JSONDecoder()`.
    /// - Returns: The decoded `Endpoint.Response` and raw
    ///   `HTTPClient.Response`.
    public func request(
        with client: HTTPClient = .default
    ) async throws -> (content: Response, response: HTTPClient.Response) {
        try await client.performRequest(
            baseURL: baseURL,
            parameters: try parameters(dto: .value),
            encoder: jsonEncoder,
            decoder: jsonDecoder
        )
    }
}

extension HTTPClient {
    /// Performs a request with the given request information.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL of the endpoint to request.
    ///   - parameters: Information needed to make a request such as
    ///     method, body, headers, etc.
    ///   - encoder: The encoder with which to encode
    ///     `Endpoint.Request` to request data to Defaults to
    ///     `JSONEncoder()`.
    ///   - decoder: A decoder with which to decode the response type,
    ///     `Response`, from the `HTTPClient.Response`.
    /// - Returns: The decoded `Endpoint.Response` and raw
    ///   `HTTPClient.Response`.
    fileprivate func performRequest<Response: Codable>(
        baseURL: String,
        parameters: HTTPComponents,
        encoder: JSONEncoder,
        decoder: JSONDecoder
    ) async throws -> (content: Response, response: HTTPClient.Response) {
        var fullURL = baseURL + parameters.fullPath
        var headers = HTTPHeaders(parameters.headers.map { $0 })
        var bodyData: Data?
        
        if parameters.bodyEncoding == .json {
            headers.add(name: "Content-Type", value: "application/json")
            bodyData = try parameters.body.map { try encoder.encode($0) }
        } else if parameters.bodyEncoding == .urlEncoded,
                  let urlParams = try parameters.urlParams() {
            headers.add(name: "Content-Type", value: "application/x-www-form-urlencoded")
            bodyData = urlParams.data(using: .utf8)
            fullURL = baseURL + parameters.basePath + parameters.query
        }
        
        let request = try HTTPClient.Request(
            url: fullURL,
            method: HTTPMethod(rawValue: parameters.method),
            headers: headers,
            body: bodyData.map { HTTPClient.Body.data($0) }
        )
        
        return try await execute(request: request)
            .flatMapThrowing { response in
                guard (200...299).contains(response.status.code) else {
                    throw PapyrusClientError(
                        message: "The response code was not successful",
                        response: response
                    )
                }
                
                if Response.self == Empty.self {
                    return (Empty.value as! Response, response)
                }

                guard let bodyBuffer = response.body else {
                    throw PapyrusClientError(
                        message: "Unable to decode response type `\(Response.self)`; the body of the response was empty!",
                        response: response
                    )
                }

                // Decode
                do {
                    let responseJSON = try HTTPBody(buffer: bodyBuffer).decodeJSON(as: Response.self, with: decoder)
                    return (responseJSON, response)
                } catch {
                    throw PapyrusClientError(
                        message: "Error decoding `\(Response.self)` from the response. \(error)",
                        response: response
                    )
                }
            }
            .get()
    }
}
