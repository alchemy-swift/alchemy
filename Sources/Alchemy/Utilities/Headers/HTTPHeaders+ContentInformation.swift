extension HTTPHeaders {
    public var contentType: ContentType? {
        get {
            first(name: "Content-Type").map(ContentType.init)
        }
        set {
            if let contentType = newValue {
                self.replaceOrAdd(name: "Content-Type", value: "\(contentType.string)")
            } else {
                self.remove(name: "Content-Type")
            }
        }
    }
    
    public var contentLength: Int? {
        get { first(name: "Content-Length").map { Int($0) } ?? nil }
        set {
            if let contentLength = newValue {
                self.replaceOrAdd(name: "Content-Length", value: "\(contentLength)")
            } else {
                self.remove(name: "Content-Length")
            }
        }
    }
}
