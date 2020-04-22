import NIO
import NIOHTTP1

extension HTTPMethod: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}

fileprivate let kRouterVariableEscape = ":"

/// Router. Takes an `HTTPRequest` and routes it to a handler.
///
/// `Input` represents the type the router passes to a handler.
/// `Output` represents the type the router expects back from a handler.
public final class Router<Input, Output> {
    private let uri: String
    private let mapper: (HTTPRequest) throws -> Input
    private var actions: [HTTPMethod: (Input) throws -> Output] = [:]
    private var nextHandler: ((HTTPRequest) throws -> Output?)?

    init(uri: String = "", mapper: @escaping (HTTPRequest) throws -> Input) {
        self.uri = uri
        self.mapper = mapper
    }
    
    func add(action: @escaping (Input) throws -> Output, for method: HTTPMethod) {
        self.actions[method] = action
    }
    
    func handle(request: HTTPRequest) throws -> Output? {
        guard self.uri.matches(uri: request.head.uri) else {
            return try self.nextHandler?(request)
        }
        
        guard let handler = self.actions[request.head.method] else {
            return nil
        }
        
        return try handler(try self.mapper(request))
    }
    
    // A middleware that does something, but doesn't change the type
    public func middleware<M: Middleware>(_ middleware: M) -> Router<Input, Output> where M.Result == Void {
        let next = Router(uri: self.uri) {
            middleware.intercept($0)
            return try self.mapper($0)
        }
        self.nextHandler = next.handle
        return next
    }

    // A middleware that does something, then changes the type
    public func middleware<M: Middleware>(_ middleware: M) -> Router<(Input, M.Result), Output> {
        let next = Router<(Input, M.Result), Output>(uri: self.uri) { request in
            (try self.mapper(request), middleware.intercept(request))
        }
        self.nextHandler = next.handle
        return next
    }
}

extension String {
    fileprivate func matches(uri: String) -> Bool {
        let parts1 = self.split(separator: "/")
        let parts2 = uri.split(separator: "/")
        
        guard parts1.count == parts2.count else {
            return false
        }
        
        for (index, part1) in parts1.enumerated() {
            let part2 = parts2[index]
            
            // This uri component it a variable, don't check.
            guard !part1.starts(with: kRouterVariableEscape)
                && !part2.starts(with: kRouterVariableEscape) else
            { continue }
            
            if part1 != part2 {
                return false
            }
        }
        
        return true
    }
}

extension Router {
    /// For values
    @discardableResult
    public func on(_ method: HTTPMethod, at path: String? = nil,
                   do action: @escaping (Input) throws -> Output) -> Self {
        self.add(action: action, for: method)
        return self
    }
    
    /// For `Void` since `Void` can't conform to any protocol.
//    @discardableResult
//    public func on(_ method: HTTPMethod, at path: String? = nil,
//                   do action: @escaping (Input) throws -> Void) -> Self {
//        self.add(
//            action: { out -> VoidCodable in
//                try action(out)
//                return VoidCodable()
//            },
//            for: method
//        )
//
//        return self
//    }
    
    /// Clean websocket API?
}
