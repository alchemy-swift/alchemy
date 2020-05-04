public typealias HTTPRouter = Router<HTTPRequest, HTTPResponseEncodable>

extension HTTPRouter: SingletonService, Fusable {
    public static func singleton(in container: Container) throws -> HTTPRouter {
        HTTPRouter { $0 }
    }
}
