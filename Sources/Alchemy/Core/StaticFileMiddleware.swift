import Foundation

/// Middleware for serving static files from a given directory.
///
/// Usage:
/// ```
/// self.router.globalMiddlewares = [
///     // Will server static files from the 'public' directory of your project.
///     StaticFileMiddleware(from: "public")
/// ]
/// ```
/// Now your router will serve the files that are in the `public` directory.
struct StaticFileMiddleware: Middleware {
    /// The directory from which static files will be served.
    private let publicDirectory: String
    
    /// Creates a new middleware to serve static files from a given directory.
    ///
    /// - Parameter publicDirectory: The directory to server static files from.
    init(from publicDirectory: String) {
        self.publicDirectory = publicDirectory
    }
    
    // MARK: Middleware
    
    func intercept(_ request: Request, next: @escaping Next) throws -> EventLoopFuture<Response> {
        var sanitizedPath = request.path
        
        // Ensure path is relative to the current directory.
        while sanitizedPath.hasPrefix("/") {
            sanitizedPath = String(sanitizedPath.dropFirst())
        }
        
        // Ensure path doesn't contain any parent directories.
        guard !request.path.contains("../") else {
            throw HTTPError(.forbidden)
        }
        
        // See if there's a file at the given path
        throw HTTPError(.badRequest)
    }
}
