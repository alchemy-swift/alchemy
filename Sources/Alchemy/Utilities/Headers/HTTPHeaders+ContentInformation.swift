extension HTTPHeaders {
    public var contentType: ContentType? {
        first(name: "content-type").map(ContentType.init)
    }
    
    public var contentLength: Int? {
        first(name: "content-length").map { Int($0) } ?? nil
    }
}
