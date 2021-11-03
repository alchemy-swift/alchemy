import SQLiteKit

final class SQLiteGrammar: Grammar {
    override var isSQLite: Bool {
        true
    }
    
    override func insert(_ values: [OrderedDictionary<String, SQLParameter>], query: Query, returnItems: Bool) async throws -> [DatabaseRow] {
        return try await query.database.transaction { conn in
            let sql = try super.compileInsert(query, values: values)
            let initial = try await conn.runRawQuery(sql.query, values: sql.bindings)
            if let from = query.from {
                return try await conn.runRawQuery("select * from \(from) where id = last_insert_rowid()", values: [])
            } else {
                return initial
            }
        }
    }
    
    override func typeString(for type: ColumnType) -> String {
        switch type {
        case .bool:
            return "integer"
        case .date:
            return "text"
        case .double:
            return "double"
        case .increments:
            return "integer PRIMARY KEY AUTOINCREMENT"
        case .int:
            return "integer"
        case .bigInt:
            return "integer"
        case .json:
            return "text"
        case .string:
            return "text"
        case .uuid:
            // There isn't a MySQL UUID type; store UUIDs as a 36
            // length varchar.
            return "text"
        }
    }
}

final class SQLiteDatabase: DatabaseDriver {
    /// The connection pool from which to make connections to the
    /// database with.
    private let pool: EventLoopGroupConnectionPool<SQLiteConnectionSource>

    let grammar: Grammar = SQLiteGrammar()
    
    enum Config {
        case memory
        case file(String)
    }
    
    /// Initialize with the given configuration. The configuration
    /// will be connected to when a query is run.
    ///
    /// - Parameter config: the info needed to connect to the
    ///   database.
    init(config: Config) {
        self.pool = EventLoopGroupConnectionPool(
            source: SQLiteConnectionSource(configuration: {
                switch config {
                case .memory:
                    return SQLiteConfiguration(storage: .memory, enableForeignKeys: true)
                case .file(let path):
                    return SQLiteConfiguration(storage: .file(path: path), enableForeignKeys: true)
                }
            }(), threadPool: .default),
            on: Loop.group
        )
    }
    
    // MARK: Database
    
    func runRawQuery(_ sql: String, values: [DatabaseValue]) async throws -> [DatabaseRow] {
        try await withConnection { try await $0.runRawQuery(sql, values: values) }
    }
    
    func transaction<T>(_ action: @escaping (DatabaseDriver) async throws -> T) async throws -> T {
        try await withConnection { conn in
            _ = try await conn.runRawQuery("BEGIN;", values: [])
            let val = try await action(conn)
            _ = try await conn.runRawQuery("COMMIT;", values: [])
            return val
        }
    }
    
    func shutdown() throws {
        try pool.syncShutdownGracefully()
    }
    
    private func withConnection<T>(_ action: @escaping (DatabaseDriver) async throws -> T) async throws -> T {
        try await pool.withConnection(logger: Log.logger, on: Loop.current) {
            try await action(SQLiteConnectionDatabase(conn: $0, grammar: self.grammar))
        }
    }
}

private struct SQLiteConnectionDatabase: DatabaseDriver {
    let conn: SQLiteConnection
    let grammar: Grammar
    
    func runRawQuery(_ sql: String, values: [DatabaseValue]) async throws -> [DatabaseRow] {
        try await conn.query(sql, values.map(SQLiteData.init)).get().map(SQLiteDatabaseRow.init)
    }
    
    func transaction<T>(_ action: @escaping (DatabaseDriver) async throws -> T) async throws -> T {
        try await action(self)
    }
    
    func shutdown() throws {
        _ = conn.close()
    }
}

public struct SQLiteDatabaseRow: DatabaseRow {
    public let allColumns: Set<String>
    
    private let row: SQLiteRow
    
    init(_ row: SQLiteRow) {
        self.row = row
        self.allColumns = Set(row.columns.map(\.name))
    }
    
    public func getField(column: String) throws -> DatabaseField {
        try self.row.column(column)
            .unwrap(or: DatabaseError("No column named `\(column)` was found \(allColumns)."))
            .toDatabaseField(from: column)
    }
}

extension SQLiteData {
    private static let dateFormatter = ISO8601DateFormatter()
    
    /// Initialize from an Alchemy `DatabaseValue`.
    ///
    /// - Parameter value: the value with which to initialize. Given
    ///   the type of the value, the `SQLiteData` will be
    ///   initialized with the best corresponding type.
    init(_ value: DatabaseValue) {
        switch value {
        case .bool(let value):
            self = value.map { $0 ? .integer(1) : .integer(0) } ?? .null
        case .date(let value):
            let dateString = value.map { SQLiteData.dateFormatter.string(from: $0) }
            self = dateString.map { .text($0) } ?? .null
        case .double(let value):
            self = value.map { .float($0) } ?? .null
        case .int(let value):
            self = value.map { .integer($0) } ?? .null
        case .json(let value):
            let jsonString = value.map { String(data: $0, encoding: .utf8) } ?? nil
            self = jsonString.map { .text($0) } ?? .null
        case .string(let value):
            self = value.map { .text($0) } ?? .null
        case .uuid(let value):
            self = value.map { .text($0.uuidString) } ?? .null
        }
    }
    
    /// Converts a `SQLiteData` to the Alchemy `DatabaseField` type.
    ///
    /// - Parameter column: The name of the column this data is at.
    /// - Throws: A `DatabaseError` if there is an issue converting
    ///   the `SQLiteData` to its expected type.
    /// - Returns: A `DatabaseField` with the column, type and value,
    ///   best representing this `SQLiteData`.
    fileprivate func toDatabaseField(from column: String) throws -> DatabaseField {
        switch self {
        case .integer(let int):
            return DatabaseField(column: column, value: .int(int))
        case .float(let double):
            return DatabaseField(column: column, value: .double(double))
        case .text(let string):
            return DatabaseField(column: column, value: .string(string))
        case .blob:
            throw DatabaseError("SQLite blob isn't supported yet")
        case .null:
            return DatabaseField(column: column, value: .string(nil))
        }
    }
}
