import Plot

extension HTML: ResponseConvertible {
    public func convert() -> Response {
        Response(status: .ok, body: Content(string: render(), contentType: .html))
    }
}

extension XML: ResponseConvertible {
    public func convert() -> Response {
        Response(status: .ok, body: Content(string: render(), contentType: .xml))
    }
}
