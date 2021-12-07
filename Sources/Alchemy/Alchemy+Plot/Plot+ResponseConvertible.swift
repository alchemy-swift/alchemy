import Plot

extension HTML: ResponseConvertible {
    public func response() -> Response {
        Response(status: .ok)
            .withString(render(), type: .html)
    }
}

extension XML: ResponseConvertible {
    public func response() -> Response {
        Response(status: .ok)
            .withString(render(), type: .xml)
    }
}
