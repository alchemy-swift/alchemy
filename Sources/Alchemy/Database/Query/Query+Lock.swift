public struct SQLLock: Equatable {
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

extension Query {
    /// Adds custom locking SQL to the end of a SELECT query.
    public func lock(for strength: SQLLock.Strength, option: SQLLock.Option? = nil) -> Self {
        lock = SQLLock(strength: strength, option: option)
        return self
    }
}
