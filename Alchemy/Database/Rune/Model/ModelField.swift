import Collections

public struct ModelField: Identifiable {
    public var id: String { name }
    public let name: String
    public let `default`: Any?

    public init<M: Model, T>(_ name: String, path: KeyPath<M, T>, default: T? = nil) {
        self.name = name
        self.default = `default`
    }
}

extension Model {
    public typealias Field = ModelField
    public typealias FieldLookup = OrderedDictionary<PartialKeyPath<Self>, ModelField>
}
