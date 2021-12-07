import MultipartKit

// Should move this to extension.
final class ContentFiles {
    /// Any files attached to this content, keyed by their multipart name
    /// (separate from filename). Only populated if this content is
    /// associated with a multipart request containing files.
    var files: [String: File]? = nil
}

extension Request {
    public func file(_ name: String) async throws -> File? {
        try await files()[name]
    }
    
    /// Access any file parts of this request. Returns an empty dict if this
    /// request has content other than multipart.
    ///
    /// Async since we maybe need to wait until streaming is finished.
    public func files() async throws -> [String: File] {
        guard let alreadyLoaded = _files.files else {
            let loadedFiles = try await loadFiles()
            _files.files = loadedFiles
            return loadedFiles
        }
        
        return alreadyLoaded
    }
    
    func loadFiles() async throws -> [String: File] {
        /// If stream, don't know all files until as stream goes.
        /// Will need to hook into stream and process files as they come in.
        ///
        ///     for file in req.fileStream {
        ///         print("got a file!")
        ///     }
        ///
        guard headers.contentType == .multipart else {
            return [:]
        }
        
        guard let boundary = headers.contentType?.parameters["boundary"] else {
            throw HTTPError(.notAcceptable)
        }
        
        guard let stream = stream else {
            return [:]
        }
        
        /// As stream comes in, parse each piece. When a new file shows up,
        /// send it along to the file stream.
        
        let parser = MultipartParser(boundary: boundary)
        var parts: [MultipartPart] = []
        var headers: HTTPHeaders = .init()
        var body: ByteBuffer = ByteBuffer()

        parser.onHeader = {
            headers.replaceOrAdd(name: $0, value: $1)
        }

        let maxFileSize = 4 * 1024 * 1024
        
        parser.onBody = {
            body.writeBuffer(&$0)
            if body.readableBytes > maxFileSize {
                
            }
        }
        
        parser.onPartComplete = {
            let part = MultipartPart(headers: headers, body: body)
            headers = [:]
            body = ByteBuffer()
            parts.append(part)
        }

        for try await chunk in stream {
            try parser.execute(chunk)
        }
        
        var files: [String: File] = [:]
        for part in parts {
            guard
                let disposition = part.headers.contentDisposition,
                let name = disposition.name,
                let filename = disposition.filename
            else { continue }
            files[name] = File(name: filename, size: part.body.writerIndex, content: .buffer(part.body))
        }
        
        return files
    }
}
