struct Request {

}

/// Something that can be encoded to and decoded from an HTTP request
protocol RequestCodable {}

extension Request {
    func validate<T: RequestCodable>(_ type: T.Type) throws -> T {
        fatalError()
    }
}
