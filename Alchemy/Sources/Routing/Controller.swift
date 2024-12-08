/// Represents a type that adds handlers to a router. Used for organizing your
/// app's handlers into smaller components.
public protocol Controller {
    /// Any middleware to be applied to all routes in this controller.
    var middlewares: [Middleware] { get }

    /// Add this controller's handlers to a router.
    func route(_ router: Router)
}

extension Controller {
    public var middlewares: [Middleware] { [] }
}

extension Router {
    /// Adds a controller to this router.
    ///
    /// - Parameter controller: The controller to handle routes on this router.
    @discardableResult
    public func use(_ controllers: Controller...) -> Self {
        for controller in controllers {
            let group = group(middlewares: controller.middlewares)
            controller.route(group)
        }

        return self
    }
}
