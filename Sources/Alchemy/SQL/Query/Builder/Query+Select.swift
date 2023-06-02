extension Query {
    /// Set the columns that should be returned by the query.
    ///
    /// - Parameters:
    ///   - columns: An array of columns to be returned by the query.
    ///     Defaults to `[*]`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func select(_ columns: String...) -> Self {
        query.columns = columns
        return self
    }
    
    /// Set the columns that should be returned by the query.
    ///
    /// - Parameters:
    ///   - columns: An array of columns to be returned by the query.
    ///     Defaults to `[*]`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func select(_ columns: [String] = ["*"]) -> Self {
        query.columns = columns
        return self
    }

    /// Set query to only return distinct entries.
    ///
    /// - Parameter columns: An array of columns to be returned by the query.
    ///   Defaults to `[*]`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func distinct(_ columns: [String] = ["*"]) -> Self {
        query.columns = columns
        query.isDistinct = true
        return self
    }
}
