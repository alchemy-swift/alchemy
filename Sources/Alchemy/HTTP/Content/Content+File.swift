import MultipartKit

// Should move this to extension.
final class ContentFiles {
    /// Any files attached to this content, keyed by their multipart name
    /// (separate from filename). Only populated if this content is
    /// associated with a multipart request containing files.
    var files: [String: File]? = nil
}

extension Request {
    func file(_ name: String) throws -> File? {
        try files()[name]
    }
    
    func files() throws -> [String: File] {
        guard let alreadyLoaded = _files.files else {
            let loadedFiles = try loadFiles()
            _files.files = loadedFiles
            return loadedFiles
        }
        
        return alreadyLoaded
    }
    
    func loadFiles() throws -> [String: File] {
        guard let buffer = buffer else {
            return [:]
        }
        
        guard headers.contentType == .multipart else {
            return [:]
        }
        
        guard let boundary = headers.contentType?.parameters["boundary"] else {
            throw HTTPError(.notAcceptable)
        }
        
        let parser = MultipartParser(boundary: boundary)
        var parts: [MultipartPart] = []
        var headers: HTTPHeaders = .init()
        var body: ByteBuffer = ByteBuffer()

        parser.onHeader = { headers.replaceOrAdd(name: $0, value: $1) }
        parser.onBody = { body.writeBuffer(&$0) }
        parser.onPartComplete = {
            let part = MultipartPart(headers: headers, body: body)
            headers = [:]
            body = ByteBuffer()
            parts.append(part)
        }

        try parser.execute(buffer)
        
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
