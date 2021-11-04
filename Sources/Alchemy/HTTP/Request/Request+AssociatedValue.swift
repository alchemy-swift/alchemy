extension Request {
    /// Sets a value associated with this request. Useful for setting
    /// objects with middleware.
    ///
    /// Usage:
    /// ```swift
    /// struct ExampleMiddleware: Middleware {
    ///     func intercept(_ request: Request, next: Next) async throws -> Response {
    ///         let someData: SomeData = ...
    ///         return try await next(request.set(someData))
    ///     }
    /// }
    ///
    /// app
    ///     .use(ExampleMiddleware())
    ///     .on(.GET, at: "/example") { request in
    ///         let theData = try request.get(SomeData.self)
    ///     }
    ///
    /// ```
    ///
    /// - Parameter value: The value to set.
    /// - Returns: `self`, with the new value set internally for
    ///   access with `self.get(Value.self)`.
    @discardableResult
    public func set<T>(_ value: T) -> Self {
        storage[ObjectIdentifier(T.self)] = value
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
    public func get<T>(_ type: T.Type = T.self) throws -> T {
        let error = AssociatedValueError(message: "Couldn't find type `\(name(of: type))` on this request")
        return try storage[ObjectIdentifier(T.self)]
            .unwrap(as: type, or: error)
    }
}

/// Error thrown when the user tries to `.get` an assocaited value
/// from an `Request` but one isn't set.
struct AssociatedValueError: Error {
    /// What went wrong.
    let message: String
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
