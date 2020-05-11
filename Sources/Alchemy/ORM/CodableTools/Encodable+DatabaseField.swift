extension DatabaseCodable {
    /// Returns all fields on a `DatabaseCodable` object.
    ///
    /// NOTE: This will not return optional fields where the value is set to nil, since the compiler generated
    /// `encode` function special cases those out.
    public func fields() throws -> [DatabaseField] {
        try DatabaseFieldReader().readFields(of: self)
    }
}
