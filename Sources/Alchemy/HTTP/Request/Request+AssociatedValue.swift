extension Request {
    private var associatedValues: [ObjectIdentifier: Any]? {
        get { extensions.get(\.associatedValues) }
        set { extensions.set(\.associatedValues, value: newValue) }
    }
    
    /// Sets a value associated with this request. Useful for setting
    /// objects with middleware.
    ///
    /// Usage:
    ///
    ///     struct ExampleMiddleware: Middleware {
    ///         func intercept(_ request: Request, next: Next) async throws -> Response {
    ///             let someData: SomeData = ...
    ///             return try await next(request.set(someData))
    ///         }
    ///     }
    ///
    ///     app
    ///         .use(ExampleMiddleware())
    ///         .on(.GET, at: "/example") { request in
    ///             let theData = try request.get(SomeData.self)
    ///         }
    ///
    /// - Parameter value: The value to set.
    /// - Returns: This reqeust, with the new value set internally for access
    ///   with `get(Value.self)`.
    @discardableResult
    public func set<T>(_ value: T) -> Self {
        if associatedValues != nil {
            associatedValues?[id(of: T.self)] = value
        } else {
            associatedValues = [id(of: T.self): value]
        }
        
        return self
    }
    
    /// Gets a value associated with this request, throws if there is
    /// not a value of type `T` already set.
    ///
    /// - Parameter type: The type of the associated value to get from
    ///   the request.
    /// - Throws: An `AssociatedValueError` if there isn't a value of
    ///   type `T` found associated with the request.
    /// - Returns: The value of type `T` from the request.
    public func get<T>(_ type: T.Type = T.self, or error: Error = AssociatedValueError(message: "Couldn't find type `\(name(of: T.self))` on this request")) throws -> T {
        try (associatedValues?[id(of: T.self)]).unwrap(as: type, or: error)
    }
}

/// Error thrown when the user tries to `.get` an assocaited value
/// from an `Request` but one isn't set.
public struct AssociatedValueError: Error {
    /// What went wrong.
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}

extension Optional {
    /// Unwraps an optional as the provided type or throws the
    /// provided error.
    ///
    /// - Parameters:
    ///   - as: The type to unwrap to.
    ///   - error: The error to be thrown if `self` is unable to be
    ///            unwrapped as the provided type.
    /// - Throws: An error if unwrapping as the provided type fails.
    /// - Returns: `self` unwrapped and cast as the provided type.
    fileprivate func unwrap<T>(as: T.Type = T.self, or error: Error) throws -> T {
        guard let wrapped = self as? T else {
            throw error
        }
        
        return wrapped
    }
}
