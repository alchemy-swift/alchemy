/// Middleware for serving static files from a given directory.
///
/// Usage:
///
///     app.useAll(StaticFileMiddleware(from: "resources"))
///
/// Now your app will serve the files that are in the `resources` directory.
public struct FileMiddleware: Middleware {
    /// The storage for getting files.
    private let storage: Storage
    /// Additional extensions to try if a file with the exact name isn't found.
    private let extensions: [String]
    
    /// Creates a new middleware to serve static files from a given directory.
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
        let allPossiblePaths = [sanitizedPath] + extensions.map { sanitizedPath + ".\($0)" }
        for possiblePath in allPossiblePaths {
            if try await storage.exists(possiblePath) {
                return try await storage.get(possiblePath).response
            }
        }
        
        return try await next(request)
    }
}
