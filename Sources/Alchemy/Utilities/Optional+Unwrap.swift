import NIO

extension Optional {
    /// Unwraps an optional or throws the provided error.
    ///
    /// - Parameter error: An error that will be thrown if `self` is
    ///   `nil`.
    /// - Throws: The provided error if `self` is `nil`.
    /// - Returns: The unwrapped value of `self`.
    public func unwrap(or error: Error) throws -> Wrapped {
        guard let wrapped = self else {
            throw error
        }
        
        return wrapped
    }
    
    /// Unwraps an optional as the provided type or throws the
    /// provided error.
    ///
    /// - Parameters:
    ///   - as: The type to unwrap to.
    ///   - error: The error to be thrown if `self` is unable to be
    ///            unwrapped as the provided type.
    /// - Throws: An error if unwrapping as the provided type fails.
    /// - Returns: `self` unwrapped and cast as the provided type.
    public func unwrap<T>(as: T.Type = T.self, or error: Error) throws -> T {
        guard let wrapped = self as? T else {
            throw error
        }
        
        return wrapped
    }
}
