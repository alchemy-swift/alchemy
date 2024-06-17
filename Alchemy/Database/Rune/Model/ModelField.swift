import Collections

public struct ModelField: Identifiable {
    public var id: String { name }
    public let name: String
    public let type: Any.Type
    public let `default`: Any?

    public init<T>(_ name: String, type: T.Type, default: T? = nil) {
        self.name = name
        self.type = type
        self.default = `default`
    }
}

extension Model {
    public typealias FieldLookup = OrderedDictionary<PartialKeyPath<Self>, ModelField>
}
