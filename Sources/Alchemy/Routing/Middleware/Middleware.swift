public protocol Middleware {
    func intercept(_ request: HTTPRequest) throws -> HTTPRequest
}
