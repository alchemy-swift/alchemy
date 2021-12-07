import MultipartKit

extension Request {
    /// Any files attached to this content, keyed by their multipart name
    /// (separate from filename). Only populated if this content is
    /// associated with a multipart request containing files.
    private var _files: [String: File]? {
        get { extensions.get(\._files) }
        set { extensions.set(\._files, value: newValue) }
    }
    
    /// Get any attached file with the given name from this request.
    public func file(_ name: String) async throws -> File? {
        try await files()[name]
    }
    
    /// Access any file parts of this request. Returns an empty dict if this
    /// request has content other than multipart.
    ///
    /// Async since we maybe need to wait until streaming is finished.
    public func files() async throws -> [String: File] {
        guard let alreadyLoaded = _files else {
            return try await loadFiles()
        }
        
        return alreadyLoaded
    }

    /// Currently loads all files into memory. Should store files larger than
    /// some size into a temp directory.
    private func loadFiles() async throws -> [String: File] {
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

        parser.onBody = {
            body.writeBuffer(&$0)
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
        
        _files = files
        return files
    }
}
