import AsyncHTTPClient
import Foundation
import NIO
import NIOHTTP1
import Papyrus

public struct PapyrusClientError: Error {
    public let message: String
    public let response: HTTPClient.Response
}

extension Endpoint {
    public func request(
        _ dto: Req,
        with client: HTTPClient = Client.default,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> EventLoopFuture<(content: Res, response: HTTPClient.Response)> {
        client.performRequest(
            baseURL: self.baseURL,
            parameters: try self.parameters(dto: dto),
            decoder: decoder
        )
    }
}

extension Endpoint where Req == Empty {
    public func request(
        with client: HTTPClient = Client.default,
        decoder: JSONDecoder = JSONDecoder()
    ) -> EventLoopFuture<(content: Res, response: HTTPClient.Response)> {
        client.performRequest(
            baseURL: self.baseURL,
            parameters: .just(url: self.path, method: self.method),
            decoder: decoder
        )
    }
}

extension HTTPClient {
    fileprivate func performRequest<Response: Codable>(
        baseURL: String,
        parameters: RequestParameters,
        decoder: JSONDecoder
    ) -> EventLoopFuture<(content: Response, response: HTTPClient.Response)> {
        catchError {
            var fullURL = baseURL + parameters.fullPath
            var headers = HTTPHeaders(parameters.headers.map { $0 })
            var bodyData: Data?
            
            if parameters.body?.contentType == .json {
                headers.add(name: "Content-Type", value: "application/json")
                bodyData = try parameters.body.map { try JSONEncoder().encode($0.content) }
            } else if parameters.body?.contentType == .urlEncoded,
                      let urlParams = try parameters.urlParams() {
                headers.add(name: "Content-Type", value: "application/x-www-form-urlencoded")
                bodyData = urlParams.data(using: .utf8)
                fullURL = baseURL + parameters.basePath + parameters.query
            }
            
            let request = try HTTPClient.Request(
                url: fullURL,
                method: HTTPMethod(rawValue: parameters.method.rawValue),
                headers: headers,
                body: bodyData.map { HTTPClient.Body.data($0) }
            )
            
            return self.execute(request: request)
                .flatMapThrowing { response in
                    guard (200...299).contains(response.status.code) else {
                        throw PapyrusClientError(
                            message: "The response code was not successful",
                            response: response
                        )
                    }
                    
                    guard let responseJSON = try response.body
                            .map({ HTTPBody(buffer: $0) })?
                            .decodeJSON(as: Response.self, with: decoder) else {
                        throw PapyrusClientError(
                            message: "Unable to decode response type `\(Response.self)`; the body "
                                + "of the response was empty!",
                            response: response
                        )
                    }
                    
                    return (responseJSON, response)
                }
        }
    }
}
