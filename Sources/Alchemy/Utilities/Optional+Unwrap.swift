extension Optional {
    public func unwrap(or error: Error) throws -> Wrapped {
        guard let wrapped = self else {
            throw error
        }
        
        return wrapped
    }
    
    public func unwrap<T>(as: T.Type = T.self, or error: Error) throws -> T {
        guard let wrapped = self as? T else {
            throw error
        }
        
        return wrapped
    }
}
