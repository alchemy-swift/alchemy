import Alchemy
import Foundation

struct Query: DatabaseCodable {
    static var keyMappingStrategy: DatabaseKeyMappingStrategy = .convertToSnakeCase
    static var tableName = "queries"
    
    let id: UUID
    let originID: UUID
    let destinationID: UUID
    let departure: Date
    let `return`: Date
    let isEnabled: Bool
    let lastRun: Date
}
