extension Query {
    /// Limit the returned results to a given amount.
    ///
    /// - Parameter value: An amount to cap the total result at.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func limit(_ value: Int) -> Self {
        limit = Swift.max(0, value)
        return self
    }
    
    /// Offset the returned results by a given amount.
    ///
    /// - Parameter value: An amount representing the offset.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func offset(_ value: Int) -> Self {
        offset = Swift.max(0, value)
        return self
    }

    /// A helper method to be used when needing to page returned
    /// results. Internally this uses the `limit` and `offset`
    /// methods.
    ///
    /// - Note: Paging starts at index 1 so `page: 1` will give the 1st page.
    ///
    /// - Parameters:
    ///   - page: What `page` of results to offset by.
    ///   - pageSize: How many results to show on each page. Defaults to `100`.
    public func page(_ page: Int, pageSize: Int = 100) -> Self {
        offset((page - 1) * pageSize).limit(pageSize)
    }
}
