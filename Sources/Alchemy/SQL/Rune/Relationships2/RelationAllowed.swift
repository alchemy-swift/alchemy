public protocol RelationAllowed {
    associatedtype M: Model

    static func from(array: [M]) throws -> Self
    func toModel() -> [M]
}

extension Array: RelationAllowed where Element: Model {
    public typealias M = Element

    public static func from(array: [Element]) throws -> [M] {
        array
    }

    public func toModel() -> [M] {
        self
    }
}

extension Optional: RelationAllowed where Wrapped: Model {
    public typealias M = Wrapped

    public static func from(array: [Wrapped]) throws -> Wrapped? {
        array.first
    }

    public func toModel() -> [M] {
        [self].compactMap { $0 }
    }
}
