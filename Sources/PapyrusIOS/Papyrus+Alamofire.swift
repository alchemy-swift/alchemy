import Alamofire
import Papyrus
import Foundation

/// Makes request
public protocol API {
    /// The baseURL of all endpoints this requests
    var baseURL: String { get }
    
    /// Put auth interceptors here; add default support later?
    var session: Session { get }
}

extension API {
    /// Request an endpoint with an empty request type & a non-empty Response type.
    public func request<Res>(_ endpoint: Endpoint<Papyrus.Empty, Res>) -> DataRequest {
        self.session.request(baseURL + endpoint.path, method: endpoint.method.af)
    }
    
    /// Request an endpoint with a non-empty Response & Request type.
    public func request<Req, Res>(_ endpoint: Endpoint<Req, Res>, _ req: Req) throws -> DataRequest {
        let requestParameters = try endpoint.parameters(dto: req)
        return self.session.request(self.baseURL + requestParameters.fullPath,
                                    method: requestParameters.method.af,
                                    parameters: requestParameters.body?.content,
                                    encoder: JSONParameterEncoder.default,
                                    headers: HTTPHeaders(requestParameters.headers))
    }
}

public extension HTTPReqMethod {
    var af: HTTPMethod {
        return Alamofire.HTTPMethod(rawValue: self.rawValue.uppercased())
    }
}

private struct AFDataEncoder: ParameterEncoder {
    static let shared = AFDataEncoder()
    
    func encode<Parameters>(_ parameters: Parameters?, into request: URLRequest) throws
        -> URLRequest where Parameters : Encodable
    {
        var request = request
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameters as? Data
        return request
    }
}
