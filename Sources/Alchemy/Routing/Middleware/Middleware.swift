public protocol Middleware {
    associatedtype Result
    func intercept(_ request: HTTPRequest) throws -> Result
}
