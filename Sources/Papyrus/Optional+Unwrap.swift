extension Optional {
    /// Unwraps an optional or throws the provided error.
    ///
    /// - Parameter error: An error to be thrown if `self == nil`.
    /// - Throws: The provided error if `self` is `nil`.
    /// - Returns: The unwrapped value of `self`.
    public func unwrap(or error: Error) throws -> Wrapped {
        guard let wrapped = self else {
            throw error
        }
        
        return wrapped
    }
}
