extension Query {
    public enum LockStrength: String {
        case update = "FOR UPDATE", share = "FOR SHARE"
    }

    public enum LockOption: String {
        case noWait = "NO WAIT", skipLocked = "SKIP LOCKED"
    }
    
    /// Adds custom SQL to the end of a SELECT query.
    public func forLock(_ lock: LockStrength, option: LockOption? = nil) -> Self {
        let lockOptionString = option.map { " \($0.rawValue)" } ?? ""
        self.lock = lock.rawValue + lockOptionString
        return self
    }
}
