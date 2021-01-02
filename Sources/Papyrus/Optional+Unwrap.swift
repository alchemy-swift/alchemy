extension Optional {
    /// Unwraps an optional or throws the provided error.
    ///
    /// - Parameter error: an error that will be thrown if `self` is `nil`.
    /// - Throws: the provided error if `self` is `nil`.
    /// - Returns: the unwrapped value of `self`.
    public func unwrap(or error: Error) throws -> Wrapped {
        guard let wrapped = self else {
            throw error
        }
        
        return wrapped
    }
}
