public protocol ContentDecoder {
    func decodeContent<D: Decodable>(_ type: D.Type, from content: Content) throws -> D
}

public protocol ContentEncoder {
    func encodeContent<E: Encodable>(_ value: E) throws -> Content
}
