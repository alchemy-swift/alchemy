import NIO

public protocol Middleware {
    func intercept(_ request: HTTPRequest) -> EventLoopFuture<HTTPRequest>
}
