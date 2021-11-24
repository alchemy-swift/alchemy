import Foundation
import NIO
import NIOHTTP1

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
public struct StaticFileMiddleware: Middleware {
    /// The directory from which static files will be served.
    private let directory: String
    
    /// Extensions to search for if a file is not found.
    private let extensions: [String]
    
    /// The file IO helper for streaming files.
    private let fileIO = NonBlockingFileIO(threadPool: .default)
    
    /// Used for allocating buffers when pulling out file data.
    private let bufferAllocator = ByteBufferAllocator()
    
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
        self.directory = directory.hasSuffix("/") ? directory : "\(directory)/"
        self.extensions = extensions
    }
    
    // MARK: Middleware
    
    public func intercept(_ request: Request, next: Next) async throws -> Response {
        // Ignore non `GET` requests.
        guard request.method == .GET else {
            return try await next(request)
        }
        
        let initialFilePath = try directory + sanitizeFilePath(request.path)
        var filePath = initialFilePath
        var isDirectory: ObjCBool = false
        var exists = false
        
        // See if there's a file at any possible path
        for possiblePath in [initialFilePath] + extensions.map({ "\(initialFilePath).\($0)" }) {
            filePath = possiblePath
            isDirectory = false
            exists = FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory)
            
            if exists && !isDirectory.boolValue {
                break
            }
        }
        
        guard exists && !isDirectory.boolValue else {
            return try await next(request)
        }
        
        let fileInfo = try FileManager.default.attributesOfItem(atPath: filePath)
        guard let fileSizeBytes = (fileInfo[.size] as? NSNumber)?.intValue else {
            Log.error("[StaticFileMiddleware] attempted to access file at `\(filePath)` but it didn't have a size.")
            throw HTTPError(.internalServerError)
        }
        
        let fileHandle = try NIOFileHandle(path: filePath)
        let response = Response { responseWriter in
            // Set any relevant headers based off the file info.
            var headers: HTTPHeaders = ["content-length": "\(fileSizeBytes)"]
            if let ext = filePath.components(separatedBy: ".").last,
               let mediaType = ContentType(fileExtension: ext) {
                headers.add(name: "content-type", value: mediaType.value)
            }
            try await responseWriter.writeHead(status: .ok, headers)
            
            // Load the file in chunks, streaming it.
            try await fileIO.readChunked(
                fileHandle: fileHandle,
                byteCount: fileSizeBytes,
                chunkSize: NonBlockingFileIO.defaultChunkSize,
                allocator: self.bufferAllocator,
                eventLoop: Loop.current,
                chunkHandler: { buffer in
                    Loop.current.wrapAsync {
                        try await responseWriter.writeBody(buffer)
                    }
                }
            )
            .flatMapThrowing { _ -> Void in
                try fileHandle.close()
            }
            .flatMapAlways { result -> EventLoopFuture<Void> in
                return Loop.current.wrapAsync {
                    if case .failure(let error) = result {
                        Log.error("[StaticFileMiddleware] Encountered an error loading a static file: \(error)")
                    }
                    
                    try await responseWriter.writeEnd()
                }
            }
            .get()
        }
        
        return response
    }
    
    /// Sanitize a file path, returning the new sanitized path.
    ///
    /// - Parameter path: The path to sanitize for file access.
    /// - Throws: An error if the path is forbidden.
    /// - Returns: The sanitized path, appropriate for loading files
    ///   from.
    private func sanitizeFilePath(_ path: String) throws -> String {
        var sanitizedPath = path
        
        // Ensure path is relative to the current directory.
        while sanitizedPath.hasPrefix("/") {
            sanitizedPath = String(sanitizedPath.dropFirst())
        }
        
        // Ensure path doesn't contain any parent directories.
        guard !sanitizedPath.contains("../") else {
            throw HTTPError(.forbidden)
        }
        
        // Route / to
        if sanitizedPath.isEmpty {
            sanitizedPath = "index.html"
        }
        
        return sanitizedPath
    }
}
