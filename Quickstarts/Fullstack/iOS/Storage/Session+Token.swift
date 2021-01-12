import Alamofire
import Foundation

extension Session {
    /// We can use this session to add the auth token to requests that
    /// expect it.
    static let tokenSession = Session(interceptor: AuthInterceptor())
    
    /// An `Alamofire` interceptor that will add the auth token, if it
    /// exists, to all outgoing requests made on this session.
    private final class AuthInterceptor: RequestInterceptor {
        func adapt(
            _ urlRequest: URLRequest,
            for session: Session,
            completion: @escaping (Result<URLRequest, Error>) -> Void
        ) {
            var urlRequest = urlRequest
            if let token = Storage.shared.authToken {
                urlRequest.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
            }
            completion(.success(urlRequest))
        }
    }
}
