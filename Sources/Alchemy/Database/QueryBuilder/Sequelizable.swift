import Foundation

protocol Sequelizable {
    func toSQL() -> SQL
}
