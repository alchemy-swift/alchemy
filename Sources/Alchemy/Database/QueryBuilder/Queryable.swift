import Foundation

public protocol Queryable: Table {
    static func query(database: Database) -> Query
}

public extension Queryable {
    static func query(database: Database = DB.default) -> Query {
        return Query(database: database).from(table: Self.tableName)
    }
}
