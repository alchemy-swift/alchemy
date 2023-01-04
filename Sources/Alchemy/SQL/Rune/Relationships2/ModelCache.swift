public final class ModelCache: ModelProperty, Codable {
    let row: SQLRow
    var relationships: [Int: any RelationAllowed]

    // MARK: Codable

    public init(from decoder: Decoder) throws {
        self.row = SQLRow(fields: [])
        self.relationships = [:]
    }

    public func encode(to encoder: Encoder) throws {
        // Encode nothing.
    }

    // MARK: ModelProperty

    public init(key: String, on row: SQLRowReader) throws {
        self.row = row.row
        self.relationships = [:]
    }

    public func store(key: String, on row: inout SQLRowWriter) throws {
        // Do nothing.
    }
}
