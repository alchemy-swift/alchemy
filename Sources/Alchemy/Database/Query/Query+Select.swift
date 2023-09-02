extension Query {
    /// Set the columns that should be returned by the query.
    public func select(_ columns: String...) -> Self {
        self.columns = columns
        return self
    }
    
    /// Set the columns that should be returned by the query.
    ///
    /// - Parameters:
    ///   - columns: An array of columns to be returned by the query.
    ///     Defaults to `[*]`.
    public func select(_ columns: [String] = ["*"]) -> Self {
        self.columns = columns
        return self
    }

    /// Set query to only return distinct entries.
    ///
    /// - Parameters:
    ///   - columns: An array of columns to be returned by the query. Defaults
    ///     to `[*]`.
    public func distinct(_ columns: [String] = ["*"]) -> Self {
        self.columns = columns
        isDistinct = true
        return self
    }
}
