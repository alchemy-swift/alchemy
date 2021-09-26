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
    
    /// The file IO helper for streaming files.
    private let fileIO = NonBlockingFileIO(threadPool: .default)
    
    /// Used for allocating buffers when pulling out file data.
    private let bufferAllocator = ByteBufferAllocator()
    
    /// Creates a new middleware to serve static files from a given
    /// directory. Directory defaults to "public/".
    ///
    /// - Parameter directory: The directory to server static files
    ///   from. Defaults to "Public/".
    public init(from directory: String = "Public/") {
        self.directory = directory.hasSuffix("/") ? directory : "\(directory)/"
    }
    
    // MARK: Middleware
    
    public func intercept(_ request: Request, next: Next) async throws -> Response {
        // Ignore non `GET` requests.
        guard request.method == .GET else {
            return try await next(request)
        }
        
        let filePath = try directory + sanitizeFilePath(request.path)
        
        // See if there's a file at the given path
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory)
        
        if exists && !isDirectory.boolValue {
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
                   let mediaType = MIMEType(fileExtension: ext) {
                    headers.add(name: "content-type", value: mediaType.value)
                }
                try await responseWriter.writeHead(status: .ok, headers)
                
                // Load the file in chunks, streaming it.
                do {
                    try await self.fileIO.readChunked(
                        fileHandle: fileHandle,
                        byteCount: fileSizeBytes,
                        chunkSize: NonBlockingFileIO.defaultChunkSize,
                        allocator: self.bufferAllocator,
                        eventLoop: Loop.current,
                        chunkHandler: { buffer in
                            Task {
                                try await responseWriter.writeBody(buffer)
                            }
                            
                            return .new(())
                        }
                    ).get()
                    try fileHandle.close()
                } catch {
                    // Not a ton that can be done in the case of
                    // an error, not sure what else can be done
                    // besides logging and ending the request.
                    Log.error("[StaticFileMiddleware] Encountered an error loading a static file: \(error)")
                }
            }
            
            return response
        } else {
            // No file, continue to handlers.
            return try await next(request)
        }
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
