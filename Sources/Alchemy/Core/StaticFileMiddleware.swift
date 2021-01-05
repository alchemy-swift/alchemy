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
    private let directory: String
    
    /// Creates a new middleware to serve static files from a given directory.
    ///
    /// - Parameter directory: The directory to server static files from. Defaults to "public/"
    init(from directory: String = "public/") {
        self.directory = directory.hasSuffix("/") ? directory : "\(directory)/"
    }
    
    // MARK: Middleware
    
    func intercept(_ request: Request, next: @escaping Next) throws -> EventLoopFuture<Response> {
        var sanitizedPath = request.path
        
        // Ensure path is relative to the current directory.
        while sanitizedPath.hasPrefix("/") {
            sanitizedPath = String(sanitizedPath.dropFirst())
        }
        
        // Ensure path doesn't contain any parent directories.
        guard !sanitizedPath.contains("../") else {
            throw HTTPError(.forbidden)
        }
        
        let filePath = self.directory + sanitizedPath
        
        // See if there's a file at the given path
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory)
        
        if exists && !isDirectory.boolValue {
            fatalError()
            // load the file & return it
        } else {
            return next(request)
        }
    }
}
