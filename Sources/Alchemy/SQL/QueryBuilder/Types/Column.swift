import Foundation

/// Something convertible to a table column in an SQL database.
public protocol Column {
    var columnSQL: SQL { get }
}

extension String: Column {
    var columnSQL: SQL {
        SQL(self)
    }
}

extension SQL: Column {
    var columnSQL: SQL {
        self
    }
}
