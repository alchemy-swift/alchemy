extension Query {
    public enum LockStrength: String {
        case update = "FOR UPDATE", share = "FOR SHARE"
    }

    public enum LockOption: String {
        case noWait = "NO WAIT", skipLocked = "SKIP LOCKED"
    }
    
    /// Adds custom locking SQL to the end of a SELECT query.
    public func lock(for strength: LockStrength, option: LockOption? = nil) -> Self {
        lock = strength.rawValue
        if let option = option { lock?.append(" \(option.rawValue)") }
        return self
    }
}
