import Foundation

/// Something that can be turned into SQL.
public protocol Sequelizable {
    func toSQL() -> SQL
}
