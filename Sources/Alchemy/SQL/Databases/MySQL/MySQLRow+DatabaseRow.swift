import MySQLNIO

extension MySQLRow: DatabaseRow {
    public var allColumns: [String] {
        self.columnDefinitions.map { $0.name }
    }

    public func getField(columnName: String) throws -> DatabaseField {
        guard let value = self.column(columnName) else {
            throw MySQLError("No column named '\(columnName)' was found.")
        }

        return try value.toDatabaseField(from: columnName)
    }
}
