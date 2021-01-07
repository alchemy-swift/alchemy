import Plot

extension HTML: ResponseConvertible {
    // MARK: ResponseConvertible
    
    public func convert() throws -> EventLoopFuture<Response> {
        let body = HTTPBody(text: self.render(), mimeType: .html)
        return .new(Response(status: .ok, body: body))
    }
}

extension XML: ResponseConvertible {
    // MARK: ResponseConvertible
    
    public func convert() throws -> EventLoopFuture<Response> {
        let body = HTTPBody(text: self.render(), mimeType: .xml)
        return .new(Response(status: .ok, body: body))
    }
}
