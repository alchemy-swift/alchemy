/// Represents a type erased `Optional`.
public protocol AnyOptional {}

// MARK: AnyOptional
extension Optional: AnyOptional {}
