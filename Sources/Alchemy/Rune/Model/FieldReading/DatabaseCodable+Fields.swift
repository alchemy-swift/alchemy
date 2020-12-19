extension Model {
    /// Returns all `DatabaseField`s on a `Model` object. Useful for inserting or updating
    /// values into a database.
    ///
    /// - Throws: a `DatabaseCodingError` if there is an error creating any of the fields of this
    ///           instance.
    /// - Returns: an array of database fields representing the stored properties of `self`.
    public func fields() throws -> [DatabaseField] {
        try DatabaseFieldReader(Self.keyMappingStrategy).getFields(of: self)
    }
    
    /// Returns an ordered dictionary of column names to `Parameter` values, appropriate for working
    /// with the QueryBuilder.
    ///
    /// - Throws: a `DatabaseCodingError` if there is an error creating any of the fields of this
    ///           instance.
    /// - Returns: an ordered dictionary mapping column names to parameters for use in a
    ///            QueryBuilder `Query`.
    public func fieldDictionary() throws -> OrderedDictionary<String, Parameter> {
        var dict = OrderedDictionary<String, Parameter>()
        for field in try self.fields() {
            dict.updateValue(field.value, forKey: field.column)
        }
        return dict
    }
}
