public protocol SQLQueryResult {
    init(row: SQLRow) throws
}

extension SQLRow: SQLQueryResult {
    public init(row: SQLRow) throws {
        self = row
    }
}
