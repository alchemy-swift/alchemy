extension Model {
    /// Returns an ordered dictionary of column names to `Parameter`
    /// values, appropriate for working with the QueryBuilder.
    ///
    /// - Throws: A `DatabaseCodingError` if there is an error
    ///   creating any of the fields of this instance.
    /// - Returns: An ordered dictionary mapping column names to
    ///   parameters for use in a QueryBuilder `Query`.
    public func fields() throws -> [String: SQLValue] {
        try ModelFieldReader(Self.keyMapping).getFields(of: self)
    }
}
