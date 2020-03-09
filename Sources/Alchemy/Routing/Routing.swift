enum HTTPMethod {
    case get, post, patch, delete, put
}

/// Request validations
/// (Handle through typed Middleware):
/// 1. Router level: validate pre-conditions (auth, headers, app version)
///
/// (Handle with Request.validate(expectedType)):
/// 2. Controller level: validate expected input (params unique to the request)

extension Router {
    @discardableResult
    func path(_ path: String) -> Self {
        self
    }

    @discardableResult
    func group(path: String? = nil, configure: (Self) -> Void) -> Self {
        self
    }

    @discardableResult
    func group<M: Middleware>(with: M, configure: (Router<Out>) -> Void) -> Self where M.Out == Void {
        self
    }

    @discardableResult
    func group<M: Middleware>(with: M, configure: (Router<(Out, M.Out)>) -> Void) -> Self {
        self
    }
}

extension Router {
    @discardableResult
    func on<R>(_ method: HTTPMethod, at path: String? = nil, do action: (Out) throws -> R) -> Self {
        self
    }
    
    /// Clean websocket API?
}

extension Router: Injectable where Out == Request {
    static func create(_ isMock: Bool) -> Router<Request> {
        Router { $0 }
    }
}

struct Router<Out> {

    /// Either respond
    /// or pass down the chain

    private let action: (Request) -> Out

    init(_ action: @escaping (Request) -> Out) {
        self.action = action
    }

    // A middleware that does something, but doesn't change the type
    func middleware<M: Middleware>(_ middleware: M) -> Self where M.Out == Void {
        self
    }

    // A middleware that does something, then changes the type
    func middleware<M: Middleware>(_ middleware: M) -> Router<(Out, M.Out)> {
        Router<(Out, M.Out)> { request in
            (self.action(request), middleware.intercept(request))
        }
    }
}

//@RouteBuilder
//func get(_ path: String, _ handler: () -> String) -> Router {
//  [Router()]
//}
//@_functionBuilder
//struct RouteBuilder {
//  static func buildBlock(_ segments: [Router]) -> Router {
//    segments.first!
//  }
//}
//extension Router {
//    @discardableResult
//    func configure(with: Middleware, configuration: (Router) -> Void) -> Router {
//        self
//    }
//}
