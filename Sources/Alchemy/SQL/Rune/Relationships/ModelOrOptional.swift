public protocol ModelOrOptional {
    associatedtype M: Model
    init(model: Optional<M>) throws
}

extension Model {
    public init(model: Optional<Self>) throws {
        guard let model else {
            throw RuneError("Unable to find a hasOne!")
        }

        self = model
    }
}

extension Optional: ModelOrOptional where Wrapped: Model {
    public init(model: Optional<Wrapped>) throws {
        self = model
    }
}
