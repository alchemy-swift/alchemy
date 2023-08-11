import Foundation
import NIO

/// An SQL query.
open class Query<Result: QueryResult>: SQLConvertible {
    let db: Database
    var logging: QueryLogging? = nil

    /// The SQL table to be queried.
    var table: String?
    var columns: [String]
    var isDistinct = false
    var limit: Int? = nil
    var offset: Int? = nil
    var lock: SQLLock? = nil
    var joins: [SQLJoin] = []
    var wheres: [SQLWhere] = []
    var groups: [String] = []
    var havings: [SQLWhere] = []
    var orders: [SQLOrder] = []

    public var sql: SQL {
        db.grammar.select(isDistinct: isDistinct,
                          columns: columns,
                          table: table ?? "<notset>",
                          joins: joins,
                          wheres: wheres,
                          groups: groups,
                          havings: havings,
                          orders: orders,
                          limit: limit,
                          offset: offset,
                          lock: lock)
    }

    private var didLoad: ([Result]) async throws -> [Result] = { $0 }

    public init(db: Database, table: String? = nil, columns: [String] = ["*"]) {
        self.db = db
        self.table = table
        self.columns = columns
    }

    // MARK: Table

    public func from(_ table: String, as alias: String? = nil) -> Self {
        self.table = alias.map { "\(table) AS \($0)" } ?? table
        return self
    }

    // MARK: Hooks

    public func didLoad(_ then: @escaping(inout [Result]) async throws -> Void) -> Self {
        let _didLoad = didLoad
        didLoad = { rows in
            var results = try await _didLoad(rows)
            try await then(&results)
            return results
        }

        return self
    }
    
    // MARK: SELECT

    /// Run a select query and return the database rows.
    ///
    /// - Note: Optional columns can be provided that override the
    ///   original select columns.
    /// - Parameter columns: The columns you would like returned.
    ///   Defaults to `nil`.
    /// - Returns: The rows returned by the database.
    public func get() async throws -> [Result] {
        guard let table else {
            throw DatabaseError("Table required to run query - use `.from(...)` to set one.")
        }

        let sql = db.grammar.select(isDistinct: isDistinct,
                                    columns: columns,
                                    table: table,
                                    joins: joins,
                                    wheres: wheres,
                                    groups: groups,
                                    havings: havings,
                                    orders: orders,
                                    limit: limit,
                                    offset: offset,
                                    lock: lock)
        let rows = try await db.query(sql: sql, logging: logging)
        let results = try rows.map(Result.init)
        return try await didLoad(results)
    }

    public func chunk(_ chunkSize: Int = 100, handler: ([Result]) async throws -> Void) async throws {
        try await _chunk(chunkSize, handler: handler)
    }

    private func _chunk(_ chunkSize: Int, page: Int = 0, handler: ([Result]) async throws -> Void) async throws {
        let results = try await didLoad(try await self.page(page, pageSize: chunkSize).get())
        try await handler(results)
        if results.count == chunkSize {
            try await _chunk(chunkSize, page: page + 1, handler: handler)
        }
    }

    /// Run a select query and return the first database row only row.
    ///
    /// - Note: Optional columns can be provided that override the
    ///   original select columns.
    /// - Parameter columns: The columns you would like returned.
    ///   Defaults to `nil`.
    /// - Returns: The first row in the database, if it exists.
    public func first() async throws -> Result? {
        try await limit(1).get().first
    }

    /// Find the total count of the rows that match the given query.
    ///
    /// - Parameter column: What column to count. Defaults to `*`.
    /// - Returns: The count returned by the database.
    public func count(column: String = "*") async throws -> Int {
        guard let row = try await select("COUNT(\(column))").first() as? SQLRow else {
            throw DatabaseError("a COUNT query didn't return any data")
        }

        return try row.decode(Int.self)
    }

    // MARK: INSERT

    public func insert(_ columns: [String], query: Query<SQLRow>) async throws {
        guard let table else {
            throw DatabaseError("Table required to run query - use `.from(...)` to set one.")
        }

        let sql = db.grammar.insert(table, columns: columns, sql: query.sql)
        try await db.query(sql: sql, logging: logging)
    }

    /// Perform an insert and create a database row from the provided
    /// data.
    ///
    /// - Parameter value: A dictionary containing the values to be
    ///   inserted.
    public func insert(_ value: [String: SQLConvertible]) async throws {
        try await insert([value])
    }

    /// Perform an insert and create database rows from the provided data.
    ///
    /// - Parameter values: An array of dictionaries containing the values to be
    ///   inserted.
    public func insert(_ values: [[String: SQLConvertible]]) async throws {
        guard let table else {
            throw DatabaseError("Table required to run query - use `.from(...)` to set one.")
        }

        guard !values.isEmpty else {
            return
        }

        let sql = db.grammar.insert(table, values: values)
        try await db.query(sql: sql, logging: logging)
    }

    public func insertReturn(_ values: [String: SQLConvertible]) async throws -> [SQLRow] {
        try await insertReturn([values])
    }

    /// Perform an insert and return the inserted records.
    ///
    /// - Parameter values: An array of dictionaries containing the values to be
    ///   inserted.
    /// - Returns: The inserted rows.
    public func insertReturn(_ values: [[String: SQLConvertible]]) async throws -> [SQLRow] {
        guard let table else {
            throw DatabaseError("Table required to run query - use `.from(...)` to set one.")
        }

        guard !values.isEmpty else {
            return []
        }

        let statements = db.grammar.insertReturn(table, values: values)
        return try await db.transaction { conn in
            var toReturn: [SQLRow] = []
            for sql in statements {
                let rows = try await conn.query(sql: sql, logging: self.logging)
                toReturn += rows
            }

            return toReturn
        }
    }

    // MARK: UPDATE

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
    public func update(_ fields: [String: SQLConvertible]) async throws {
        guard let table else {
            throw DatabaseError("Table required to run query - use `.from(...)` to set one.")
        }

        guard !fields.isEmpty else {
            return
        }

        let sql = db.grammar.update(table: table, joins: joins, wheres: wheres, fields: fields)
        try await db.query(sql: sql, logging: logging)
    }

    // MARK: DELETE

    /// Perform a deletion on all data matching the given query.
    public func delete() async throws {
        guard let table else {
            throw DatabaseError("Table required to run query - use `.from(...)` to set one.")
        }

        let sql = db.grammar.delete(table, wheres: wheres)
        try await db.query(sql: sql, logging: logging)
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

    public func select(_ columns: String...) -> Query<SQLRow> {
        Query(db: self, table: nil, columns: columns)
    }

    @discardableResult
    func query(sql: SQL, logging: QueryLogging? = nil) async throws -> [SQLRow] {
        if let logging = logging ?? self.logging {
            switch logging {
            case .log:
                Log.info(sql.description)
            case .logRawSQL:
                Log.info(sql.rawSQLString)
            case .logFatal:
                Log.info(sql.description)
                fatalError("logf")
            case .logFatalRawSQL:
                Log.info(sql.rawSQLString)
                fatalError("logf")
            }
        }

        return try await query(sql.statement, parameters: sql.parameters)
    }
}
