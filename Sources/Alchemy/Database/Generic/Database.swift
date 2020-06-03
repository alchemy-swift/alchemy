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
        set {
            DatabaseDefault._default = newValue
        }
    }
    public static func query() -> Query {
        return DB.default.query()
    }
    
    private static var _default: Database?
}

public protocol Database {
    var grammar: Grammar { get }
    func query() -> Query
    func runRawQuery(_ sql: String, on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]>
    func runQuery(_ sql: String, values: [DatabaseValue], on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]>
    func shutdown()
}

extension Database {
    public func query() -> Query {
        return Query(database: self)
    }
}
