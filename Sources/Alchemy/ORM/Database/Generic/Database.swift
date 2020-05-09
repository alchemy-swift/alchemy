import Foundation
import PostgresKit

/// Global singleton accessor & convenient typealias for a default database.
public typealias DB = DatabaseDefault
public struct DatabaseDefault {
    public static var `default`: Database {
        get {
            guard let _default = DatabaseDefault._default else {
                fatalError("A default `Database` has not been set up yet. You can do so via `DB.default = ...`")
            }
            
            return _default
        }
        set { DatabaseDefault._default = newValue }
    }
    
    private static var _default: Database?
}

public protocol Database {
    func rawQuery(_ sql: String, on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]>
    func preparedQuery(_ sql: String, values: [DatabaseField], on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]>
    func shutdown()
}

/// A row of data returned from a database.
public protocol DatabaseRow {
    /// Get a specific named field on a Database.
    func getField(columnName: String) throws -> DatabaseField
    func decode<D: DatabaseDecodable>(_ type: D.Type) -> D
}
