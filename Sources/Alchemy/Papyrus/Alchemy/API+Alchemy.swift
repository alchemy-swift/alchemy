import AsyncHTTPClient
import Foundation
import NIO
import NIOHTTP1

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
    
    public func request<Res>(_ endpoint: Endpoint<Alchemy.Empty, Res>, _ client: HTTPClient = Client.default)
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
        let fullURL = baseURL + parameters.fullPath
        let headers = HTTPHeaders(parameters.headers.map { $0 })
        let data = try! parameters.body.map { try JSONEncoder().encode($0.content) }
        let body = data.map { HTTPClient.Body.data($0) }
        
        let request = try! HTTPClient.Request(url: fullURL, method: parameters.method, headers: headers, body: body)
        
        return self.execute(request: request)
            .flatMapThrowing { response -> (content: Response, response: HTTPClient.Response) in
                guard response.status.isSuccess else {
                    print("[PapyrusAlchemy] Error: Got status code `\(response.status.code)` hitting `\(fullURL)`.")
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

private extension HTTPResponseStatus {
    var isSuccess: Bool {
        self.code >= 200 && self.code <= 299
    }
}
