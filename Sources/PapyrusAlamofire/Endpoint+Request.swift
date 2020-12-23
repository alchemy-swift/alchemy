import Alamofire
import Papyrus
import Foundation

extension Endpoint {
    /// Request an endpoint.
    ///
    /// - Parameters:
    ///   - request: the request data of this endpoint.
    ///   - session: the `Alamofire.Session` with which to request this. Defaults to
    ///              `Session.default`.
    /// - Throws: any errors encountered while encoding the request parameters.
    /// - Returns: a `DataRequest` for tracking the response.
    public func request(_ request: Request, session: Session = .default) throws -> DataRequest {
        let requestParameters = try self.parameters(dto: request)
        return session.request(
            self.baseURL + requestParameters.fullPath,
            method: requestParameters.method.af,
            parameters: requestParameters.body?.content,
            encoder: JSONParameterEncoder.default,
            headers: HTTPHeaders(requestParameters.headers)
        )
    }
}
extension Endpoint where Request == Papyrus.Empty {
    /// Request an endpoint where `Request` is `Empty`.
    ///
    /// - Parameter session: the `Alamofire.Session` with which to request this. Defaults to
    ///                      `Session.default`.
    /// - Returns: a `DataRequest` for tracking the response.
    public func request(session: Session = .default) -> DataRequest {
        session.request(self.baseURL + self.path, method: self.method.af)
    }
}

public extension EndpointMethod {
    /// The `Alamofire` equivalent of this `EndpointMethod`.
    var af: HTTPMethod {
        HTTPMethod(rawValue: self.rawValue.uppercased())
    }
}
