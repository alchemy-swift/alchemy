import Foundation
import NIO

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
public struct StaticFileMiddleware: Middleware {
    /// The directory from which static files will be served.
    private let directory: String
    
    /// The file IO helper for streaming files.
    private let fileIO = NonBlockingFileIO(threadPool: Thread.pool)
    
    /// Used for allocating buffers when pulling out file data.
    private let bufferAllocator = ByteBufferAllocator()
    
    /// Creates a new middleware to serve static files from a given directory. Directory defaults to
    /// "public/".
    ///
    /// - Parameter directory: The directory to server static files from. Defaults to "public/"
    public init(from directory: String = "public/") {
        self.directory = directory.hasSuffix("/") ? directory : "\(directory)/"
    }
    
    // MARK: Middleware
    
    public func intercept(
        _ request: Request,
        next: @escaping Next
    ) throws -> EventLoopFuture<Response> {
        print("YO!")
        
        // Ignore non `GET` requests.
        guard request.method == .GET else {
            return next(request)
        }
        
        let filePath = try self.directory + self.sanitizeFilePath(request.path)
        
        // See if there's a file at the given path
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory)
        print("File exists? \(exists) \(filePath)")
        print("Current: \(FileManager.default.currentDirectoryPath)")
        
        if exists && !isDirectory.boolValue {
            let fileInfo = try FileManager.default.attributesOfItem(atPath: filePath)
            guard let fileSize = (fileInfo[.size] as? NSNumber)?.intValue else {
                Log.error("Attempted to access file at `\(filePath)` but it didn't have a size.")
                throw HTTPError(.internalServerError)
            }
            
            let fileHandle = try NIOFileHandle(path: filePath)
            let response = EventLoopFuture<Response>.new(
                Response { responseWriter in
                    // Load the file in chunkes, streaming it.
                    responseWriter.writeHead(status: .ok)
                    self.fileIO.readChunked(
                        fileHandle: fileHandle,
                        byteCount: fileSize,
                        chunkSize: NonBlockingFileIO.defaultChunkSize,
                        allocator: self.bufferAllocator,
                        eventLoop: Loop.current,
                        chunkHandler: { buffer in
                            responseWriter.writeBody(buffer)
                            return .new(())
                        }
                    )
                    .flatMapThrowing {
                        try fileHandle.close()
                    }
                    .whenComplete { result in
                        try? fileHandle.close()
                        switch result {
                        case .failure(let error):
                            // Not a ton that can be done in the case of an error, not sure what
                            // else can be done besides logging and ending the request.
                            Log.error("Encountered an error loading a static file: \(error)")
                            responseWriter.writeEnd()
                        case .success:
                            responseWriter.writeEnd()
                        }
                    }
                }
            )
            
            return response
        } else {
            // No file, continue to handlers.
            return next(request)
        }
    }
    
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
