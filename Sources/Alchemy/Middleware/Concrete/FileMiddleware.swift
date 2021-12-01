/// Middleware for serving static files from a given directory.
///
/// Usage:
/// ```swift
/// /// Will server static files from the 'public' directory of
/// /// your project.
/// app.useAll(StaticFileMiddleware(from: "public"))
/// ```
/// Now your router will serve the files that are in the `Public`
/// directory.
public struct FileMiddleware: Middleware {
    /// Extensions to search for if a file is not found.
    private let extensions: [String]
    
    /// The storage for getting files.
    private let storage: Storage
    
    /// Creates a new middleware to serve static files from a given
    /// directory. Directory defaults to "Public/".
    ///
    /// - Parameters:
    ///   - directory: The directory to server static files from. Defaults to
    ///     "Public/".
    ///   - extensions: File extension fallbacks. When set, if a file is not
    ///     found, the given extensions will be added to the file name and
    ///     searched for. The first that exists will be served. Defaults
    ///     to []. Example: ["html", "htm"].
    public init(from directory: String = "Public/", extensions: [String] = []) {
        self.storage = .local(root: directory)
        self.extensions = extensions
    }
    
    // MARK: Middleware
    
    public func intercept(_ request: Request, next: Next) async throws -> Response {
        // Ignore non `GET` requests.
        guard request.method == .GET else {
            return try await next(request)
        }
        
        // Ensure path doesn't contain any parent directories.
        guard !request.path.contains("../") else {
            throw HTTPError(.forbidden)
        }
        
        // Trim forward slashes
        var sanitizedPath = request.path.trimmingForwardSlash
        
        // Route / to
        if sanitizedPath.isEmpty {
            sanitizedPath = "index.html"
        }
        
        // See if there's a file at any possible extension
        let allPossiblePaths = [sanitizedPath] + extensions.map({ "\(sanitizedPath).\($0)" })
        for possiblePath in allPossiblePaths {
            if try await storage.exists(possiblePath) {
                return try await storage.get(possiblePath).response
            }
        }
        
        return try await next(request)
    }
}
