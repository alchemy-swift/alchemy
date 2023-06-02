public protocol RelationAllowed {
    associatedtype M: Model
    init(models: [M]) throws
}

extension Model {
    public init(models: [M]) throws {
        guard models.count == 1 else {
            throw RuneError("Unable to determine relationship from `\(models.count)` values!")
        }

        self = models[0]
    }
}

extension Array: RelationAllowed where Element: Model {
    public init(models: [Element]) throws {
        self = models
    }
}

extension Optional: RelationAllowed where Wrapped: Model {
    public init(models: [Wrapped]) throws {
        self = models.first
    }
}
