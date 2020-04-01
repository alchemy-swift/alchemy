import Alchemy
import Foundation

// Sanitize optional keypaths?
// Keypaths for forced correct type?
// Include nested layers

struct User: Model, Authable {
    var id: UUID = UUID()
    var name: String
    var email: String

    @Relation
    var favoriteCountry: Country
}

// MARK: - Defining Relations

/// Still need
/// Through
/// Custom Key Paths, default to ID

struct Passport: Model {
    var id: UUID = UUID()
    var color: String
    var dateIssued: Date

    // MARK: - Relations

    /// Child of `1 - 1`
    @Relation
    var traveler: User

    /// Child of `1 - M`
    @Relation
    var issuingCountry: Country

    /// Parent of `1 - 1`
    @Relation(viaTheirKey: \.passport)
    var photo: Photo

    /// Parent of `1 - M`
    @Relation(viaTheirKey: \.passport)
    var pages: [PassportPage]

    /// Either side of `M - M`
    @Relation(viaJunction: JunctionTables.passportCountries)
    var countriesVisited: [Country]

    // MARK: - TODO: Add constraints so these don't compile

    @Relation
    var countries: [Country] // Don't want to allow array of foreign keys

    @Relation(viaJunction: JunctionTables.passportCountries)
    var country1: Country // Needs to enforce an array
}

struct PassportPage: Model {
    var id: UUID = UUID()

    @Relation
    var passport: Passport
}

struct Photo: Model {
    var id: UUID = UUID()
    var imageURL: String

    @Relation
    var takenIn: Country

    @Relation
    var passport: Passport
}

struct Country: Model {
    var id: UUID = UUID()
    var name: String

    /// Through Relations

    @Relation(builder: {
        // Country -> Passport -> Photo -> Country -> User
        $0.through(theirKey: \Passport.issuingCountry)
            .through(theirKey: \Photo.passport)
            .through(relation: \.$takenIn)
            .through(theirKey: \User.favoriteCountry)
    })
    var complexUserQuery: [User]

    @Relation(builder: {
        // Country -> Passport -> Country
        $0.through(theirKey: \Passport.issuingCountry)
            .through(table: JunctionTables.passportCountries)
    })
    var complexCountriesQuery: [Country]
}

struct JunctionTables {
    static var passportCountries = JunctionTable<Passport, Country>(name: "PassportCountries")
}

// MARK: - Eager Loading

// MARK: - CRUD on Relations

/// Create:
/// 1. Many to many
/// 2. One to many
/// 3. One to one:
extension User {
    /// Many to many
    func addFriend(user: User) {

    }
}

// MARK: - Touching & Timestamps

// MARK: - Relation vs Query
/// Make `Relation` a subset of Query for similar lazy loading behavior, but extended functionality such as
/// add, delete, touch, etc.
