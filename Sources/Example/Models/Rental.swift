import Alchemy
import Foundation

struct Rental: Model {
    static var keyMappingStrategy: DatabaseKeyMappingStrategy = .convertToSnakeCase
    static var tableName = "rentals"

    var id: Int?

    let location: String
    let price: Double
    let numBeds: Int

    let reviewCount: Int

    let createdAt: Date
    let updatedAt: Date

    @BelongsTo
    var review: Review
}

struct Review: Model {
    static var keyMappingStrategy: DatabaseKeyMappingStrategy = .convertToSnakeCase
    static var tableName = "reviews"

    var id: Int?

    @HasOne(to: \.$review, keyString: "review_id")
    var rental: Rental

    let comment: String
    let rating: Int
    let isApproved: Bool

    let createdAt: Date
    let updatedAt: Date
}
