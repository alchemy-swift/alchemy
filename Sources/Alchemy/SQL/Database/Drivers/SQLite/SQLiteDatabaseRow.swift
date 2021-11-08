import SQLiteNIO

struct SQLiteDatabaseRow: SQLRow {
    let columns: Set<String>
    private let row: SQLiteRow
    
    init(_ row: SQLiteRow) {
        self.row = row
        self.columns = Set(row.columns.map(\.name))
    }
    
    func get(_ column: String) throws -> SQLValue {
        try row.column(column)
            .unwrap(or: DatabaseError("No column named `\(column)` was found \(columns)."))
            .toSQLValue()
    }
}

extension SQLiteData {
    /// Initialize from an Alchemy `SQLValue`.
    ///
    /// - Parameter value: the value with which to initialize. Given
    ///   the type of the value, the `SQLiteData` will be
    ///   initialized with the best corresponding type.
    init(_ value: SQLValue) {
        switch value {
        case .bool(let value):
            self = value ? .integer(1) : .integer(0)
        case .date(let value):
            self = .text(SQLValue.iso8601DateFormatter.string(from: value))
        case .double(let value):
            self = .float(value)
        case .int(let value):
            self = .integer(value)
        case .json(let value):
            guard let jsonString = String(data: value, encoding: .utf8) else {
                self = .null
                return
            }
            
            self = .text(jsonString)
        case .string(let value):
            self = .text(value)
        case .uuid(let value):
            self = .text(value.uuidString)
        case .null:
            self = .null
        }
    }
    
    /// Converts a `SQLiteData` to the Alchemy `SQLValue` type.
    ///
    /// - Throws: A `DatabaseError` if there is an issue converting
    ///   the `SQLiteData` to its expected type.
    /// - Returns: A `SQLValue` with the column, type and value,
    ///   best representing this `SQLiteData`.
    func toSQLValue() throws -> SQLValue {
        switch self {
        case .integer(let int):
            return .int(int)
        case .float(let double):
            return .double(double)
        case .text(let string):
            return .string(string)
        case .blob:
            throw DatabaseError("SQLite blob isn't supported yet")
        case .null:
            return .null
        }
    }
}
