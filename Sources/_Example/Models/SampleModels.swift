import Alchemy
import Foundation

// Sanitize optional keypaths?
// Keypaths for forced correct type?
// Include nested layers

struct Traveler: Model, Authable {
    var id: UUID? = UUID()
    var name: String
    var email: String

    @ManyToOne
    var favoriteCountry: Country
}

// MARK: - Defining Relations

/// Still need
/// Through
/// Custom Key Paths, default to ID

struct Passport: Model {
    var id: UUID? = UUID()
    var color: String
    var dateIssued: Date

    // MARK: - Relations

    /// Child of `1 - 1`
    @OneToOne
    var traveler: Traveler
    
    /// Parent of `1 - 1`
    @OneToOne(to: \.passport)
    var photo: Photo
    
    /// Child of `1 - M`
    @ManyToOne
    var issuingCountry: Country

    /// Parent of `1 - M`
    @OneToMany(to: \.passport)
    var pages: [PassportPage]

    /// Either side of `M - M`
    @ManyToMany(from: \PassportCountries.passport, to: \.country)
    var countriesVisited: [Country]
}

struct PassportPage: Model {
    var id: UUID? = UUID()

    @ManyToOne
    var passport: Passport
}

struct Photo: Model {
    var id: UUID? = UUID()
    var imageURL: String

    @ManyToOne
    var takenIn: Country

    @ManyToOne
    var passport: Passport
}

struct PassportCountries: Model {
    let id: UUID?
    
    @ManyToOne
    var passport: Passport
    
    @ManyToOne
    var country: Country
}

struct Country: Model {
    var id: UUID? = UUID()
    var name: String

    /// Through Relations - for a later date.

//    @Relation(builder: {
//        // Country -> Passport -> Photo -> Country -> Traveler
//        $0.through(theirKey: \Passport.issuingCountry)
//            .through(theirKey: \Photo.passport)
//            .through(relation: \.$takenIn)
//            .through(theirKey: \Traveler.favoriteCountry)
//    })
//    var complexUserQuery: [Traveler]
//
//    @Relation(builder: {
//        // Country -> Passport -> Country
//        $0.through(theirKey: \Passport.issuingCountry)
//            .through(table: JunctionTables.passportCountries)
//    })
//    var complexCountriesQuery: [Country]
}

// MARK: - Eager Loading

// MARK: - CRUD on Relations

/// Create:
/// 1. Many to many
/// 2. One to many
/// 3. One to one:
extension Traveler {
    /// Many to many
    func addFriend(user: Traveler) {

    }
}

// MARK: - Touching & Timestamps

// MARK: - Relation vs Query
/// Make `Relation` a subset of Query for similar lazy loading behavior, but extended functionality such as
/// add, delete, touch, etc.
