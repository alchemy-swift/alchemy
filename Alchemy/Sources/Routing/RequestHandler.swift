public protocol RequestHandler {
    /// Handle a Request.
    func handle(request: Request) async -> Response

    /// Set Middlewares to run on every request that goes into `handle`,
    /// regardless of if it is handled by an internal router type.
    func appendGlobalMiddlewares(_ middlewares: [Middleware])

    /// Set the default error handler.
    func setErrorHandler(_ handler: @escaping Router.ErrorHandler)

    /// Set the default not found handler.
    func setNotFoundHandler(_ handler: @escaping Router.Handler)
}
