extension Application {
    /// Groups a set of endpoints by a path prefix.
    /// All endpoints added in the `configure` closure will
    /// be prefixed, but none in the handler chain that continues
    /// after the `.grouped`.
    ///
    /// - Parameters:
    ///   - pathPrefix: The path prefix for all routes
    ///     defined in the `configure` closure.
    ///   - configure: A closure for adding routes that will be
    ///     prefixed by the given path prefix.
    /// - Returns: This application for chaining handlers.
    @discardableResult
    public func grouped(_ pathPrefix: String, configure: (Application) -> Void) -> Self {
        Services.router.pathPrefixes.append(pathPrefix)
        configure(self)
        _ = Services.router.pathPrefixes.popLast()
        return self
    }
}
