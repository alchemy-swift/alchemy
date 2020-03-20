import Foundation

/// Types of foreign keys
/// 1. One to Many (Parent -> Child)
/// 2. One to One (Parent -> Child)
/// 3. Many to Many (separate table?)

// Nonnull -> Use swift optional
// Unique
// Primary Key -> Identifiable?
// Foreign Key
// Check
// Default
// Index

/// Logic silos
/// 1. field constraints
/// 2. relations & querying across tables (get all comments for a user's post)
/// 3. migrations (adding/updating tables)

extension Database {
    func add(table: Table) {

    }

    func migrate(table: Table, migration: () -> Void) {

    }
}

struct SampleSetup {
    @Inject var db: Database

    func setup() {
        // Regular model tables
        self.db.add(table: User.table)
        self.db.add(table: Todo.table)
        self.db.add(table: Comment.table)

        // Junction tables
        self.db.add(table: JunctionTables.todoTags)

        // Migrations
        self.db.migrate(table: Todo.table, migration: { })
    }
}

extension User: Model {

}

struct SampleQueries {

}

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

/// Eager loading
extension Todo {
    
}

/// Through
extension User {
    // One to many through
    // `User` -> `Todo` -> `Comments`
    func relatedComments() -> Future<[Comment]> {
//        self.linked(using: \Todo.user).fetch()
        fatalError()
    }
}

/// Relationship sugar
extension Todo {
    // 'One to Many', via a foreign key on the other type
    func comments() -> Future<[Comment]> {
        self.related(using: \.todo).all()
    }

    // 'Many to Many' across a junction table
    func tags() -> Future<[Tag]> {
        self.related(using: JunctionTables.todoTags).all()
    }
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
    static var todoTags = JunctionTable<Todo, Tag>(name: "TodoTags")
    static var passportCountries = JunctionTable<Passport, Country>(name: "PassportCountries")
}

struct Tag: Model {
    var id: UUID
    var name: String
    var colorHex: String
}

struct Comment: Model {
    var id: UUID
    var timestamp: Date
    var text: String
    var commenter: User
    var todo: Todo
}

protocol Model: Codable, Identifiable, RelationAllowed {
//    typealias Value = Self
}

struct UserMigration {
    
}

struct Future<T> {
    init(_ val: T) {

    }
}

@propertyWrapper
struct Unique<T>: Codable where T: Codable {
    var wrappedValue: T
}

@propertyWrapper
struct Index<T>: Codable where T: Codable {
    var wrappedValue: T
}

@propertyWrapper
struct Default<T>: Codable where T: Codable {
    var wrappedValue: T
}

@propertyWrapper
struct Check<T>: Codable where T: Codable {
    var wrappedValue: T
}

// Sanitize optional keypaths?
// Keypaths for forced correct type?
// Include nested layers

struct User: Identifiable, Codable {
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
