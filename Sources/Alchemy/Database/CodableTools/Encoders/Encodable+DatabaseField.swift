extension DatabaseCodable {
    /// Returns all fields on a `DatabaseCodable` object.
    ///
    /// NOTE: This will not return optional fields where the value is set to nil, since the compiler generated
    /// `encode` function special cases those out.
    public func fields() throws -> [DatabaseField] {
        try DatabaseFieldReader().readFields(of: self)
    }

    public func dictionary() throws -> OrderedDictionary<String, Parameter> {
        var dict = OrderedDictionary<String, Parameter>()
        for field in try self.fields() {
            dict.updateValue(field.value, forKey: field.column)
        }
        return dict
    }
    
    public func idField() throws -> DatabaseField {
        // Very naive approach. Only works with objects who's id field is literally titled `id`. Need some
        // way to correlate id keypath with the actual column name. something like `let idKey =
        // Self.kpCodingKeyMapping[\.id]`.
        guard let idField = try self.fields().filter({ $0.column == "id" }).first else {
            throw DatabaseDecodingError("Unable to find a field named `id` on '\(type(of: self))'")
        }
        
        return idField
    }
}

extension Array where Element == DatabaseField {
    var idField: DatabaseField? {
        self.filter { $0.column == "id" }.first
    }
}
