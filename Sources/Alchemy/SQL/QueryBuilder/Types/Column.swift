import Foundation

/// Something convertible to a table column in an SQL database.
public protocol Column {}

extension String: Column {}
extension SQL: Column {}
