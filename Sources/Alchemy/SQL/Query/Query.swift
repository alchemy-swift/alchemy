import Foundation
import NIO

public protocol SQLQueryResult {
    init(row: SQLRow) throws
}

extension SQLRow: SQLQueryResult {
    public init(row: SQLRow) throws {
        self = row
    }
}

// Wraps a raw SQLQuery adding the ability to Log, Convert Results, and provides
// pre-post execute hooks.
public class Query<Result: SQLQueryResult> {
    let db: Database
    var shouldLog: Bool = false
    var query: SQLQuery

    private var didLoad: ([Result]) async throws -> [Result] = { $0 }

    public init(db: Database, table: String) {
        self.db = db
        self.query = SQLQuery(table: table)
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

    // MARK: - SQL Statements

    public func select(_ columns: [String]? = nil) async throws -> [SQLRow] {
        if let columns = columns {
            self.query.columns = columns
        }

        let sql = db.dialect.select(isDistinct: query.isDistinct,
                                    columns: query.columns,
                                    table: query.table,
                                    joins: query.joins,
                                    wheres: query.wheres,
                                    groups: query.groups,
                                    havings: query.havings,
                                    orders: query.orders,
                                    limit: query.limit,
                                    offset: query.offset,
                                    lock: query.lock)
        return try await db.query(sql: sql, log: shouldLog)
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

        let sql = db.dialect.insert(query.table, values: values)
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

        let statements = db.dialect.insertReturn(query.table, values: values)
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

        let sql = db.dialect.update(table: query.table, joins: query.joins, wheres: query.wheres, fields: fields)
        try await db.query(sql: sql, log: shouldLog)
    }

    /// Perform a deletion on all data matching the given query.
    public func delete() async throws {
        let sql = db.dialect.delete(query.table, wheres: query.wheres)
        try await db.query(sql: sql, log: shouldLog)
    }
}

/// The Data required to construct an SQL query.
struct SQLQuery: Equatable {
    var table: String

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
}
