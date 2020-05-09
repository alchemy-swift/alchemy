extension DatabaseEncodable {
    public func fields() throws -> [DatabaseField] {
        try DatabaseFieldReader().readFields(of: self)
    }
}
