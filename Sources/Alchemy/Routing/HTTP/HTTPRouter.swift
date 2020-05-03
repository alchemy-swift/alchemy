public typealias HTTPRouter = Router<HTTPRequest, HTTPResponseEncodable>

extension HTTPRouter: Injectable {
    // Singleton router
    public static var shared = HTTPRouter { $0 }

    public static func create(identifier: String?, _ isMock: Bool) -> HTTPRouter {
        Router.shared
    }
}
