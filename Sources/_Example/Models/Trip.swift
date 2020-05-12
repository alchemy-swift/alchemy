import Alchemy
import Foundation

struct User: Model, Authable {
    let id: UUID
}

struct Place: Model {
    let id: UUID
}

struct TripPlaces: Model {
    var id: UUID = UUID()
    var place: Place
    var trip: Trip
}

// 1 - 1 with trip
struct Flight: Model {
    var id: UUID?
    var trip: Trip!
}

struct Trip: Model {
    static var keyMappingStrategy: DatabaseKeyMappingStrategy = .convertToSnakeCase
    static var tableName = "trips"
    
    let id: UUID

    @OneToOne
    var flight: Flight
    
    @ManyToOne
    var user: User
    
    @ManyToOne
    var origin: Place
    
    @ManyToOne
    var destination: Place
    
    @ManyToMany(from: \TripPlaces.trip, to: \.place)
    var places: [Place]
    
    let priceStatus: PriceStatus?
    let dotwStart: DOTW?
    let dotwEnd: DOTW?
    let additionalWeeks: Int?
    let outboundDepartureRange: Range?
    let outboundDepartureTime: Int?
}

enum DOTW: String, Codable {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday
}

enum PriceStatus: String, Codable {
    case lowest, low, medium, high
}

public enum Range: String, Codable, CaseIterable {
    case before, after
}
