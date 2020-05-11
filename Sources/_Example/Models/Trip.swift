import Alchemy
import Foundation

struct Trip: DatabaseCodable {
    static var keyMappingStrategy: DatabaseKeyMappingStrategy = .convertToSnakeCase
    static var tableName = "trips"
    
    let id: UUID
    let userID: UUID
    let originID: UUID
    let destinationID: UUID
    let priceStatus: PriceStatus?
    let dotwStart: DOTW?
    let dotwEnd: DOTW?
    let additionalWeeks: Int?
}

enum DOTW: String, Codable {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday
}

enum PriceStatus: String, Codable {
    case lowest, low, medium, high
}
