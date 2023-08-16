public protocol KeyPathQueryable {
    /// The stored properties on this type, mapped to corresponding columns.
    static var storedProperties: [PartialKeyPath<Self>: String] { get }
}

extension KeyPathQueryable {
    public static func column<M>(for keyPath: WritableKeyPath<Self, M>) -> String? {
        storedProperties[keyPath]
    }
}

extension Model where Self: KeyPathQueryable {
    public func isDirty<M: ModelProperty & Equatable>(_ keyPath: WritableKeyPath<Self, M>) -> Bool {
        Self.column(for: keyPath).map(isDirty) ?? false
    }

    public func isClean<M: ModelProperty & Equatable>(_ keyPath: WritableKeyPath<Self, M>) -> Bool {
        !isDirty(keyPath)
    }
}
