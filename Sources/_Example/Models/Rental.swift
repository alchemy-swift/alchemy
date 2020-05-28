import Alchemy
import Foundation

struct Rental: Model {
    static var keyMappingStrategy: DatabaseKeyMappingStrategy = .convertToSnakeCase
    static var tableName = "rentals"

    let id: Int?

    let location: String
    let price: Double
    let numBeds: Int

    let reviewCount: Int

    let createdAt: Date
    let updatedAt: Date
}

struct Review: Model {
    static var keyMappingStrategy: DatabaseKeyMappingStrategy = .convertToSnakeCase
    static var tableName = "reviews"

    let id: Int?

    @OneToOne
    var rental: Rental

    let comment: String
    let rating: Int
    let isApproved: Bool

    let createdAt: Date
    let updatedAt: Date
}
