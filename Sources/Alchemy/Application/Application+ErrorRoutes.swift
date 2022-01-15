extension Application {
    /// Set a custom handler for when a handler isn't found for a
    /// request.
    ///
    /// - Parameter handler: The handler that returns a custom not
    ///   found response.
    /// - Returns: This application for chaining handlers.
    @discardableResult
    public func notFound(use handler: @escaping Handler) -> Self {
        router.notFoundHandler = handler
        return self
    }
    
    /// Set a custom handler for when an internal error happens while
    /// handling a request.
    ///
    /// - Parameter handler: The handler that returns a custom
    ///   internal error response.
    /// - Returns: This application for chaining handlers.
    @discardableResult
    public func internalError(use handler: @escaping Router.ErrorHandler) -> Self {
        router.internalErrorHandler = handler
        return self
    }
}
