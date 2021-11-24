import AsyncHTTPClient
import Foundation
import NIO
import NIOHTTP1
import Papyrus

extension Endpoint {
    /// Requests a `Papyrus.Endpoint`, returning a decoded `Endpoint.Response`.
    ///
    /// - Parameters:
    ///   - dto: An instance of the request DTO; `Endpoint.Request`.
    ///   - client: The client to request with. Defaults to `Client.default`.
    /// - Returns: A raw `ClientResponse` and decoded `Response`.
    public func request(_ dto: Request, with client: Client = .default) async throws -> (clientResponse: ClientResponse, response: Response) {
        try await client.request(endpoint: self, request: dto)
    }
}

extension Endpoint where Request == Empty {
    /// Requests a `Papyrus.Endpoint` where the `Request` type is
    /// `Empty`, returning a decoded `Endpoint.Response`.
    ///
    /// - Parameter client: The client to request with. Defaults to
    ///   `Client.default`.
    /// - Returns: A raw `ClientResponse` and decoded `Response`.
    public func request(with client: Client = .default) async throws -> (clientResponse: ClientResponse, response: Response) {
        try await client.request(endpoint: self, request: Empty.value)
    }
}

extension Client {
    /// Performs a request with the given request information.
    ///
    /// - Parameters:
    ///   - endpoint: The Endpoint to request.
    ///   - request: An instance of the Endpoint's Request.
    /// - Returns: A raw `ClientResponse` and decoded `Response`.
    fileprivate func request<Request: RequestConvertible, Response: Codable>(
        endpoint: Endpoint<Request, Response>,
        request: Request
    ) async throws -> (clientResponse: ClientResponse, response: Response) {
        let components = try endpoint.httpComponents(dto: request)
        var request = withHeaders(components.headers)
        
        switch components.contentEncoding {
        case .json:
            request = request
                .withJSON(components.body, encoder: endpoint.jsonEncoder)
        case .url:
            request = request
                .withBody(try components.urlParams()?.data(using: .utf8))
                .withContentType(.urlEncoded)
        }
        
        let clientResponse = try await request
            .request(HTTPMethod(rawValue: components.method), endpoint.baseURL + components.fullPath)
            .validateSuccessful()
        
        if Response.self == Empty.self {
            return (clientResponse, Empty.value as! Response)
        }
        
        return (clientResponse, try clientResponse.decodeJSON(Response.self, using: endpoint.jsonDecoder))
    }
}
