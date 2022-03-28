import PostgresNIO

extension PostgresData {
    /// Initialize from an Alchemy `SQLValue`.
    ///
    /// - Parameter value: the value with which to initialize. Given
    ///   the type of the value, the `PostgresData` will be
    ///   initialized with the best corresponding type.
    init(_ value: SQLValue) {
        switch value {
        case .bool(let value):
            self = PostgresData(bool: value)
        case .date(let value):
            self = PostgresData(date: value)
        case .double(let value):
            self = PostgresData(double: value)
        case .int(let value):
            self = PostgresData(int: value)
        case .json(let value):
            self = PostgresData(json: value)
        case .string(let value):
            self = PostgresData(string: value)
        case .uuid(let value):
            self = PostgresData(uuid: value)
        case .null:
            self = .null
        }
    }
    
    /// Converts a `PostgresData` to the Alchemy `SQLValue` type.
    ///
    /// - Parameter column: The name of the column this data is at.
    /// - Throws: A `DatabaseError` if there is an issue converting
    ///   the `PostgresData` to its expected type.
    /// - Returns: An `SQLValue` with the column, type and value,
    ///   best representing this `PostgresData`.
    func toSQLValue(_ column: String? = nil) throws -> SQLValue {
        switch self.type {
        case .int2, .int4, .int8:
            return int.map { .int($0) } ?? .null
        case .bool:
            return bool.map { .bool($0) } ?? .null
        case .varchar, .text:
            return string.map { .string($0) } ?? .null
        case .date, .timestamptz, .timestamp:
            return date.map { .date($0) } ?? .null
        case .float4, .float8:
            return double.map { .double($0) } ?? .null
        case .uuid:
            return uuid.map { .uuid($0) } ?? .null
        case .json, .jsonb:
            return json.map { .json($0) } ?? .null
        case .null:
            return .null
        default:
            let desc = column.map { "from column `\($0)`" } ?? "from PostgreSQL column"
            throw DatabaseError("Couldn't parse a `\(type)` from \(desc). That PostgreSQL datatype isn't supported, yet.")
        }
    }
}
