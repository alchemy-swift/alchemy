public protocol OneOrMany {
    associatedtype M: Model
    var array: [M] { get }
    init(models: [M]) throws
}

extension Array: OneOrMany where Element: Model {
    public typealias M = Element

    public init(models: [Element]) throws {
        self = models
    }

    public var array: [Element] {
        self
    }
}

extension Optional: OneOrMany where Wrapped: Model {
    public typealias M = Wrapped

    public init(models: [Wrapped]) throws {
        self = models.first
    }

    public var array: [Wrapped] {
        map { [$0] } ?? []
    }
}

extension Model where M == Self {
    public init(models: [Self]) throws {
        guard let model = models.first else {
            throw RuneError("Non-optional relationship to \(Self.self) had no results!")
        }

        self = model
    }

    public var array: [Self] {
        [self]
    }
}
