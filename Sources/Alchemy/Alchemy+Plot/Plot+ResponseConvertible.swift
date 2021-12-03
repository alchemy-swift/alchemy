import Plot

extension HTML: ResponseConvertible {
    public func convert() -> Response {
        Response(status: .ok)
            .withString(render(), type: .html)
    }
}

extension XML: ResponseConvertible {
    public func convert() -> Response {
        Response(status: .ok)
            .withString(render(), type: .xml)
    }
}
