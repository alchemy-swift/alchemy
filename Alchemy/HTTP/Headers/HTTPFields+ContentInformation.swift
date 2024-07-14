extension HTTPFields {
    public var contentType: ContentType? {
        get {
            self[.contentType].map(ContentType.init)
        }
        set {
            if let contentType = newValue {
                self[.contentType] = contentType.string
            } else {
                self[.contentType] = nil
            }
        }
    }
    
    public var contentLength: Int? {
        get {
            self[.contentLength].map { Int($0) } ?? nil
        }
        set {
            if let contentLength = newValue {
                self[.contentLength] = String(contentLength)
            } else {
                self[.contentLength] = nil
            }
        }
    }
}
