public struct AnyEncodable: Encodable {
    let value: Encodable

    init(_ value: Encodable) {
        self.value = value
    }

    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
