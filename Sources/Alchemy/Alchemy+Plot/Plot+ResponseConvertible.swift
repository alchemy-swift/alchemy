import Plot

extension HTML: ResponseConvertible {
    public func convert() -> Response {
        Response(status: .ok, body: HTTPBody(text: render(), mimeType: .html))
    }
}

extension XML: ResponseConvertible {
    public func convert() -> Response {
        Response(status: .ok, body: HTTPBody(text: render(), mimeType: .xml))
    }
}
