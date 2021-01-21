import Foundation

/// Something convertible to a table column in an SQL database.
public protocol Column {
    var columnSQL: SQL { get }
}

extension String: Column {
    public var columnSQL: SQL {
        SQL(self)
    }
}

extension SQL: Column {
    public var columnSQL: SQL {
        self
    }
}
