import Foundation
import NIO

// An SQL query.
public class Query<Result: SQLQueryResult> {
    let db: Database
    var shouldLog: Bool = false

    let table: String
    var columns: [String] = ["*"]
    var isDistinct = false
    var limit: Int? = nil
    var offset: Int? = nil
    var lock: SQLLock? = nil
    var joins: [SQLJoin] = []
    var wheres: [SQLWhere] = []
    var groups: [String] = []
    var havings: [SQLWhere] = []
    var orders: [SQLOrder] = []

    private var didLoad: ([Result]) async throws -> [Result] = { $0 }

    public init(db: Database, table: String) {
        self.db = db
        self.table = table
    }

    // MARK: - Logging

    /// Indicates the entire query should be logged when it's executed. Logs
    /// will occur at the `info` log level.
    public func log() -> Self {
        shouldLog = true
        return self
    }

    // MARK: - Hooks

    func didLoad(_ then: @escaping(inout [Result]) async throws -> Void) -> Self {
        let _didLoad = didLoad
        didLoad = { rows in
            var results = try await _didLoad(rows)
            try await then(&results)
            return results
        }

        return self
    }
    
    // MARK: - Get

    /// Run a select query and return the database rows.
    ///
    /// - Note: Optional columns can be provided that override the
    ///   original select columns.
    /// - Parameter columns: The columns you would like returned.
    ///   Defaults to `nil`.
    /// - Returns: The rows returned by the database.
    public func get(_ columns: [String]? = nil) async throws -> [Result] {
        let rows = try await select(columns)
        let results = try rows.map(Result.init)
        return try await didLoad(results)
    }

    /// Run a select query and return the first database row only row.
    ///
    /// - Note: Optional columns can be provided that override the
    ///   original select columns.
    /// - Parameter columns: The columns you would like returned.
    ///   Defaults to `nil`.
    /// - Returns: The first row in the database, if it exists.
    public func first(_ columns: [String]? = nil) async throws -> Result? {
        try await limit(1).get(columns).first
    }

    // MARK: - SQL Statements

    public func select(_ columns: [String]? = nil) async throws -> [SQLRow] {
        if let columns = columns {
            self.columns = columns
        }

        let sql = db.dialect.select(isDistinct: isDistinct,
                                    columns: self.columns,
                                    table: table,
                                    joins: joins,
                                    wheres: wheres,
                                    groups: groups,
                                    havings: havings,
                                    orders: orders,
                                    limit: limit,
                                    offset: offset,
                                    lock: lock)
        return try await db.query(sql: sql, log: shouldLog)
    }

    /// Find the total count of the rows that match the given query.
    ///
    /// - Parameter column: What column to count. Defaults to `*`.
    /// - Returns: The count returned by the database.
    public func count(column: String = "*") async throws -> Int {
        guard let field = try await (select(["COUNT(\(column))"]).first() as? SQLRow)?.fields.first else {
            throw DatabaseError("a COUNT query didn't return any data")
        }

        return try field.value.int()
    }

    /// Perform an insert and create a database row from the provided
    /// data.
    ///
    /// - Parameter value: A dictionary containing the values to be
    ///   inserted.
    public func insert(_ value: [String: SQLValueConvertible]) async throws {
        try await insert([value])
    }

    /// Perform an insert and create database rows from the provided data.
    ///
    /// - Parameter values: An array of dictionaries containing the values to be
    ///   inserted.
    public func insert(_ values: [[String: SQLValueConvertible]]) async throws {
        guard !values.isEmpty else {
            return
        }

        let sql = db.dialect.insert(table, values: values)
        try await db.query(sql: sql, log: shouldLog)
    }

    public func insertReturn(_ values: [String: SQLValueConvertible]) async throws -> [SQLRow] {
        try await insertReturn([values])
    }

    /// Perform an insert and return the inserted records.
    ///
    /// - Parameter values: An array of dictionaries containing the values to be
    ///   inserted.
    /// - Returns: The inserted rows.
    public func insertReturn(_ values: [[String: SQLValueConvertible]]) async throws -> [SQLRow] {
        guard !values.isEmpty else {
            return []
        }

        let statements = db.dialect.insertReturn(table, values: values)
        let shouldLog = shouldLog
        return try await db.transaction { conn in
            var toReturn: [SQLRow] = []
            for sql in statements {
                let rows = try await conn.query(sql: sql, log: shouldLog)
                toReturn += rows
            }

            return toReturn
        }
    }

    /// Perform an update on all data matching the query in the
    /// builder with the values provided.
    ///
    /// For example, if you wanted to update the first name of a user
    /// whose ID equals 10, you could do so as follows:
    /// ```swift
    /// database
    ///     .table("users")
    ///     .where("id" == 10)
    ///     .update(values: [
    ///         "first_name": "Ashley"
    ///     ])
    /// ```
    ///
    /// - Parameter fields: An dictionary containing the values to be
    ///   updated.
    public func update(fields: [String: SQLValueConvertible]) async throws {
        guard !fields.isEmpty else {
            return
        }

        let sql = db.dialect.update(table: table, joins: joins, wheres: wheres, fields: fields)
        try await db.query(sql: sql, log: shouldLog)
    }

    /// Perform a deletion on all data matching the given query.
    public func delete() async throws {
        let sql = db.dialect.delete(table, wheres: wheres)
        try await db.query(sql: sql, log: shouldLog)
    }
}

extension Database {
    /// Start a QueryBuilder query on this database. See `Query` or
    /// QueryBuilder guides.
    ///
    /// Usage:
    /// ```swift
    /// if let row = try await database.table("users").where("id" == 1).first() {
    ///     print("Got a row with fields: \(row.allColumns)")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - table: The table to run the query on.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func table(_ table: String, as alias: String? = nil) -> Query<SQLRow> {
        let tableName = alias.map { "\(table) AS \($0)" } ?? table
        return Query(db: self, table: tableName)
    }

    /// An alias for `table(_ table: String)` to be used when running.
    /// a `select` query that also lets you alias the table name.
    ///
    /// - Parameters:
    ///   - table: The table to select data from.
    ///   - alias: An alias to use in place of table name. Defaults to
    ///     `nil`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func from(_ table: String, as alias: String? = nil) -> Query<SQLRow> {
        self.table(table, as: alias)
    }

    @discardableResult
    fileprivate func query(sql: SQL, log: Bool) async throws -> [SQLRow] {
        if log || shouldLog {
            let bindingsString = sql.bindings.isEmpty ? "" : " \(sql.bindings)"
            Log.info("\(sql.statement);\(bindingsString)")
        }

        return try await query(sql.statement, values: sql.bindings)
    }

    fileprivate var dialect: SQLDialect {
        provider.dialect
    }
}
