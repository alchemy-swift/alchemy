import Alamofire
import Papyrus
import Foundation

extension Endpoint {
    /// Request an endpoint.
    ///
    /// - Parameters:
    ///   - request: The request data of this endpoint.
    ///   - session: The `Alamofire.Session` with which to request
    ///     this. Defaults to `Session.default`.
    ///   - jsonEncoder: The `JSONEncoder` to use when encoding the
    ///     `Request`. Defaults to `JSONEncoder()`.
    ///   - jsonDecoder: The `JSONDecoder` to use when decoding the
    ///     `Response`. Defaults to `JSONDecoder()`.
    ///   - completion: A completion that will be called when the
    ///     request is complete. Contains the raw `AFDataResponse<Data>`
    ///     as well as a `Result` containing either the parsed
    ///   `Response` or an `Error`.
    /// - Throws: any errors encountered while encoding the request
    ///   parameters.
    public func request(
        _ request: Request,
        session: Session = .default,
        jsonEncoder: JSONEncoder = JSONEncoder(),
        jsonDecoder: JSONDecoder = JSONDecoder(),
        completion: @escaping (AFDataResponse<Data?>, Result<Response, Error>) -> Void
    ) throws {
        let requestParameters = try self.parameters(dto: request)
        session
            .request(
                self.baseURL + requestParameters.fullPath,
                method: requestParameters.method.af,
                parameters: requestParameters.body,
                encoder: requestParameters.bodyEncoding == .json ?
                    JSONParameterEncoder(encoder: jsonEncoder) :
                    URLEncodedFormParameterEncoder.default,
                headers: HTTPHeaders(requestParameters.headers)
            )
            .validate(statusCode: 200..<300)
            .response { afResponse in
                switch afResponse.result {
                case .success(let data):
                    if Response.self == Papyrus.Empty.self {
                        return completion(afResponse, .success(Papyrus.Empty.value as! Response))
                    }
                    do {
                        guard let data = data else {
                            throw PapyrusError("Error parsing `\(Response.self)`; body was empty.")
                        }
                        let dto = try jsonDecoder.decode(Response.self, from: data)
                        completion(afResponse, .success(dto))
                    } catch {
                        completion(afResponse, .failure(error))
                    }
                case .failure(let error):
                    completion(afResponse, .failure(error))
                }
            }
    }
}

extension Endpoint where Request == Papyrus.Empty {
    /// Request an endpoint where `Request` is `Empty`.
    ///
    /// - Parameter session: The `Alamofire.Session` with which to
    ///   request this. Defaults to `Session.default`.
    /// - Returns: A `DataRequest` for tracking the response.
    public func request(session: Session = .default) -> DataRequest {
        session.request(self.baseURL + self.path, method: self.method.af)
    }
}

private extension EndpointMethod {
    /// The Alamofire equivalent of this `EndpointMethod`.
    var af: HTTPMethod {
        HTTPMethod(rawValue: self.rawValue.uppercased())
    }
}
