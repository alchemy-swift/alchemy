extension HTTPHeaders {
    public var contentType: ContentType? {
        get {
            first(name: "content-type").map(ContentType.init)
        }
        set {
            if let contentType = newValue {
                self.replaceOrAdd(name: "content-type", value: "\(contentType.string)")
            } else {
                self.remove(name: "content-type")
            }
        }
    }
    
    public var contentLength: Int? {
        get { first(name: "content-length").map { Int($0) } ?? nil }
        set {
            if let contentLength = newValue {
                self.replaceOrAdd(name: "content-length", value: "\(contentLength)")
            } else {
                self.remove(name: "content-length")
            }
        }
    }
}
