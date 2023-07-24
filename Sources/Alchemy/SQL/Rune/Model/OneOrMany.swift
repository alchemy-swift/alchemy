public protocol OneOrMany {
    associatedtype M: Model
    init(models: [M]) throws
}

extension Array: OneOrMany where Element: Model {
    public typealias M = Element

    public init(models: [Element]) throws {
        self = models
    }
}

extension Optional: OneOrMany where Wrapped: Model {
    public init(models: [Wrapped]) throws {
        self = models.first
    }
}

extension Model {
    public init(models: [Self]) throws {
        guard let model = models.first else {
            throw RuneError("Unable to find a hasOne!")
        }

        self = model
    }
}
