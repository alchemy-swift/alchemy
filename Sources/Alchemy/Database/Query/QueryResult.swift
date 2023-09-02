public protocol QueryResult {
    init(row: SQLRow) throws
}

extension SQLRow: QueryResult {
    public init(row: SQLRow) throws {
        self = row
    }
}
