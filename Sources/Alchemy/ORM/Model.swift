import Foundation

extension Model {
    typealias Relation<To: RelationAllowed> = _Relation<Self, To>
}

/// So that `[Model]` & `Model` can have similar functionality
protocol RelationAllowed {
    associatedtype Value: Model
    var elementType: Value.Type { get }
}

extension RelationAllowed {
    var elementType: Self.Type { Self.self }
}

extension Array: RelationAllowed where Element: Model {
    var elementType: Element.Type { Element.self }
}

extension Optional: RelationAllowed where Wrapped: Model {
    var elementType: Wrapped.Type { Wrapped.self }
}

@propertyWrapper
struct _Relation<From: RelationAllowed, To: RelationAllowed>: Codable {
    var wrappedValue: To {
        get {
            fatalError()
        }
        set {
            fatalError()
        }
    }

    init(_ to: To) {

    }

    init() {
        
    }

    init(builder: (From.Value.Relation<From.Value>) -> From.Value.Relation<To.Value>) {

    }


    init(viaTheirKey: KeyPath<To.Value, From.Value>) {

    }

    init(viaTheirKey: KeyPath<To.Value, From.Value?>) {

    }

    init(viaJunction: JunctionTable<From.Value, To.Value>) {

    }

    var projectedValue: _Relation<From, To> {
        self
    }
}

struct Todo: Model {
    @Index
    @Unique
    var id: UUID

    var isDone: Bool

    @Check
    var name: String

    @Relation
    var owner: User
}

/// Table abstraction, automatically synthesized for models
protocol Table {
    var name: String { get }
    // some type for handling fields & such
    var fields: [String] { get }
}

struct ModelTable: Table {
    var name: String = "compute this"
    var fields: [String] = []
}

extension Model {
    static var table: ModelTable {
        ModelTable()
    }

    static func all() -> Future<[Self]> {
        Future([])
    }
}

// Name for this? "Association Table"? "Linking Table"?
struct JunctionTable<T: Model, U: Model>: Table {
    var fields: [String] = []

    // We need an identifier, right?
    var name: String
}

struct JunctionTables {
    static var passportCountries = JunctionTable<Passport, Country>(name: "PassportCountries")
}

protocol Model: Codable, Identifiable, RelationAllowed { }

struct Future<T> {
    init(_ val: T) {

    }
}

// Sanitize optional keypaths?
// Keypaths for forced correct type?
// Include nested layers

struct User: Model {
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

// MARK: - Eager Loading

// MARK: - CRUD on Relations

// MARK: - Touching & Timestamps

// MARK: - Relation vs Query
/// Make `Relation` a subset of Query for similar lazy loading behavior, but extended functionality such as
/// add, delete, touch, etc.
