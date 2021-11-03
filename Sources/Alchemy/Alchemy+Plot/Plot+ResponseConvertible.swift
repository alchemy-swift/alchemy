import Plot

extension HTML: ResponseConvertible {
    public func convert() -> Response {
        Response(status: .ok, body: HTTPBody(text: render(), contentType: .html))
    }
}

extension XML: ResponseConvertible {
    public func convert() -> Response {
        Response(status: .ok, body: HTTPBody(text: render(), contentType: .xml))
    }
}
