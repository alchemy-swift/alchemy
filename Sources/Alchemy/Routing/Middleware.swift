public protocol Middleware {
    associatedtype Result
    func intercept(_ input: HTTPRequest) -> Result
}
