/// A `Migration` provides functionality for adding and rolling back
/// changes to the schema of a relational database.
public protocol Migration {
    /// The name of this migration, defaults to the type name.
    var name: String { get }

    /// The schema changes that should be run when applying this
    /// migration to a database.
    ///
    /// - Parameter schema: The schema to build changes on.
    func up(db: Database) async throws

    /// The schema changes that should be run when rolling back this
    /// migration to a database.
    ///
    /// - Parameter schema: The schema to build changes on.
    func down(db: Database) async throws
}

extension Migration {
    /// The name of this migration.
    public var name: String {
        KeyMapping.snakeCase.encode(Alchemy.name(of: Self.self))
    }
}
