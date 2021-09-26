import Plot

extension HTML: ResponseConvertible {
    public func convert() -> Response {
        let body = HTTPBody(text: render(), mimeType: .html)
        return Response(status: .ok, body: body)
    }
}

extension XML: ResponseConvertible {
    public func convert() -> Response {
        let body = HTTPBody(text: render(), mimeType: .xml)
        return Response(status: .ok, body: body)
    }
}
