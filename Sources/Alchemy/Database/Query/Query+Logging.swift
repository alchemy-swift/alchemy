enum QueryLogging {
    /// Log the SQL query when it's executed.
    case log
    /// Log the SQL query when it's executed, substituting bindings.
    case logRawSQL
    /// Log the SQL query, then die without executing the query.
    case logFatal
    /// Log the SQL query, substituting bindings, then die.
    case logFatalRawSQL
}

extension Query {
    /// Indicates the entire query should be logged when it's executed. Logs
    /// will occur at the `info` log level.
    public func log() -> Self {
        logging = .log
        return self
    }

    public func logRawSQL() -> Self {
        logging = .logRawSQL
        return self
    }

    public func logf() -> Self {
        logging = .logFatal
        return self
    }

    public func logfRawSQL() -> Self {
        logging = .logFatalRawSQL
        return self
    }
}
