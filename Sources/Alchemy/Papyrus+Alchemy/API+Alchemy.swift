import AsyncHTTPClient
import Foundation
import NIO
import NIOHTTP1
import Papyrus

public struct API {
    /// The baseURL of all endpoints this requests
    let baseURL: String
    let customDecoder: JSONDecoder?
    
    /// TODO add auth interceptors
    public init(baseURL: String, customDecoder: JSONDecoder? = nil) {
        self.baseURL = baseURL
        self.customDecoder = customDecoder
    }
    
    public func request<Req, Res>(
        _ endpoint: Endpoint<Req, Res>, _ dto: Req,
        _ client: HTTPClient = Client.default
    )
        throws -> EventLoopFuture<(content: Res, response: HTTPClient.Response)>
    {
        let parameters = try endpoint.parameters(dto: dto)
        return client.performRequest(baseURL: self.baseURL, parameters, customDecoder: self.customDecoder)
    }
    
    public func request<Res>(_ endpoint: Endpoint<Empty, Res>, _ client: HTTPClient = Client.default)
        -> EventLoopFuture<(content: Res, response: HTTPClient.Response)>
    {
        client.performRequest(baseURL: self.baseURL, .just(url: endpoint.basePath, method: endpoint.method),
                              customDecoder: self.customDecoder)
    }
}

private extension HTTPClient {
    func performRequest<Response: Codable>(baseURL: String, _ parameters: RequestParameters,
                                           customDecoder: JSONDecoder? = nil)
        -> EventLoopFuture<(content: Response, response: HTTPClient.Response)>
    {
        catchError {
            var fullURL = baseURL + parameters.fullPath
            var headers = HTTPHeaders(parameters.headers.map { $0 })
            
            var bodyData: Data?
            if parameters.body?.contentType == .json {
                headers.add(name: "Content-Type", value: "application/json")
                bodyData = try parameters.body.map { try JSONEncoder().encode($0.content) }
            } else if parameters.body?.contentType == .urlEncoded, let urlParams = try parameters.urlParams() {
                headers.add(name: "Content-Type", value: "application/x-www-form-urlencoded")
                bodyData = urlParams.data(using: .utf8)
                fullURL = baseURL + parameters.basePath + parameters.query
            }
            
            let request = try HTTPClient.Request(
                url: fullURL,
                method: parameters.method.nio,
                headers: headers,
                body: bodyData.map { HTTPClient.Body.data($0) }
            )
            
            return self.execute(request: request)
                .flatMapThrowing { response -> (content: Response, response: HTTPClient.Response) in
                    guard response.status.isSuccess else {
                        print("[PapyrusAlchemy] Error: Got status code `\(response.status.code)` hitting `\(fullURL)` response was: \(response.bodyString()).")
                        throw HTTPError(response.status)
                    }
                    
                    guard let responseJSON = try response.body
                        .map({ HTTPBody(buffer: $0) })?
                        .decodeJSON(as: Response.self, with: customDecoder ?? JSONDecoder()) else
                    {
                        throw HTTPError(HTTPResponseStatus.internalServerError)
                    }
                    
                    return (responseJSON, response)
                }
        }
    }
}

private extension HTTPResponseStatus {
    var isSuccess: Bool {
        self.code >= 200 && self.code <= 299
    }
}

extension HTTPClient.Response {
    func bodyString() -> String? {
        let data = self.body?.withUnsafeReadableBytes { buffer -> Data in
            let buffer = buffer.bindMemory(to: UInt8.self)
            return Data.init(buffer: buffer)
        }
        
        return data.map { String(data: $0, encoding: .utf8) ?? "" }
    }
}
