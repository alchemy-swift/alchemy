extension Query {
    public struct Lock: Equatable {
        public enum Strength: String {
            case update
            case share
        }

        public enum Option: String {
            case noWait
            case skipLocked
        }
        
        let strength: Strength
        let option: Option?
    }
    
    /// Adds custom locking SQL to the end of a SELECT query.
    public func lock(for strength: Lock.Strength, option: Lock.Option? = nil) -> Self {
        self.lock = Lock(strength: strength, option: option)
        return self
    }
}
