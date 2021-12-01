import Plot

extension HTML: ResponseConvertible {
    public func convert() -> Response {
        Response(status: .ok, body: .string(render(), type: .html))
    }
}

extension XML: ResponseConvertible {
    public func convert() -> Response {
        Response(status: .ok, body: .string(render(), type: .xml))
    }
}
