public protocol OneOrMany {
    associatedtype M: Model
    init(models: [M]) throws
    func toArray() -> [M]
}

extension Array: OneOrMany where Element: Model {
    public typealias M = Element

    public init(models: [Element]) throws {
        self = models
    }

    public func toArray() -> [M] {
        self
    }
}

extension Optional: OneOrMany where Wrapped: Model {
    public init(models: [Wrapped]) throws {
        self = models.first
    }

    public func toArray() -> [Wrapped] {
        self.map { [$0] } ?? []
    }
}

extension Model {
    public init(models: [Self]) throws {
        guard let model = models.first else {
            throw RuneError("Non-optional relationship to \(Self.self) had no results!")
        }

        self = model
    }

    public func toArray() -> [Self] {
        [self]
    }
}
