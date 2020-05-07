public struct EncodableStoredProperty {
    public enum PropertyType {
        case string
        case array
        case dictionary
        case int
        case bool
    }
    
    public let codingKey: CodingKey
    public let value: Any
    public let type: PropertyType
}

extension Encodable {
    public func storedProperties() -> [EncodableStoredProperty] {
        []
    }
}
