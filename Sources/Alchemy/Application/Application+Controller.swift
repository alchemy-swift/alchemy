/// Represents a type that adds handlers to a router. Used for
/// organizing your app's handlers
/// into smaller components.
public protocol Controller {
    /// Add this controller's handlers to a router.
    ///
    /// - Parameter router: The Router on which to add handlers.
    func route(_ app: Application)
}

extension Application {
    /// Adds a controller to this route.
    ///
    /// - Parameter controller: The controller to handle routes on
    ///   this router.
    /// - Returns: This router for chaining.
    @discardableResult
    public func controller(_ controllers: Controller...) -> Self {
        controllers.forEach { c in
            _ = snapshotMiddleware { c.route($0) }
        }
        
        return self
    }
}
