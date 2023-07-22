public protocol ModelOrOptional: OneOrMany {}

extension Optional: ModelOrOptional where Wrapped: Model {}
