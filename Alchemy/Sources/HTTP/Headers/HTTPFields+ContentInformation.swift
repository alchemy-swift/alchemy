extension HTTPFields {
    public var contentType: ContentType? {
        get {
            self[.contentType].map(ContentType.init)
        }
        set {
            self[.contentType] = newValue?.string
        }
    }
    
    public var contentLength: Int? {
        get {
            Int(self[.contentLength] ?? "")
        }
        set {
            self[.contentLength] = newValue.map { String($0) }
        }
    }
}
