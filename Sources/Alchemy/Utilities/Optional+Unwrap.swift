extension Optional {
    public func unwrap(or error: Error) throws -> Wrapped {
        guard let wrapped = self else {
            throw error
        }
        
        return wrapped
    }
}
