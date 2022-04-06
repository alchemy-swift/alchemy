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
    public func request(_ dto: Request, with client: Client = .default) async throws -> (clientResponse: Client.Response, response: Response) {
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
    public func request(with client: Client = .default) async throws -> (clientResponse: Client.Response, response: Response) {
        try await client.request(endpoint: self, request: .value)
    }
}

extension Client {
    /// Performs a request with the given request information.
    ///
    /// - Parameters:
    ///   - endpoint: The Endpoint to request.
    ///   - request: An instance of the Endpoint's Request.
    /// - Returns: A raw `ClientResponse` and decoded `Response`.
    fileprivate func request<Request: EndpointRequest, Response: EndpointResponse>(
        endpoint: Endpoint<Request, Response>,
        request: Request
    ) async throws -> (clientResponse: Client.Response, response: Response) {
        let rawRequest = try endpoint.rawRequest(with: request)
        var builder = builder()
        if let body = rawRequest.body {
            builder = builder.withBody(data: body)
        }
        
        builder = builder.withHeaders(rawRequest.headers)
        
        let method = HTTPMethod(rawValue: rawRequest.method)
        let fullUrl = try rawRequest.fullURL()
        builder = builder.withBaseUrl(fullUrl).withMethod(method)

        if let mockedResponse = endpoint.mockedResponse {
            let clientRequest = builder.clientRequest
            let clientResponse = Client.Response(request: clientRequest, host: "mock", status: .ok, version: .http1_1, headers: [:])
            let res = mockedResponse(request)
            return (clientResponse: clientResponse, response: res)
        }

        let clientResponse = try await builder.execute().validateSuccessful()
        
        guard Response.self != Empty.self else {
            return (clientResponse, Empty.value as! Response)
        }

        var dict: [String: String] = [:]
        clientResponse.headers.forEach { dict[$0] = $1 }
        let response = try endpoint.decodeResponse(headers: dict, body: clientResponse.data)
        return (clientResponse, response)
    }
}
