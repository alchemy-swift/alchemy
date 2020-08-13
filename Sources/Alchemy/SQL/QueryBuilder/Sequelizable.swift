import Foundation

/// Something that can be turned into SQL.
protocol Sequelizable {
    func toSQL() -> SQL
}
