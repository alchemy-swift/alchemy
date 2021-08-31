/// A `Migration` provides functionality for adding and rolling back
/// changes to the schema of a relational database.
public protocol Migration {
    /// The schema changes that should be run when applying this
    /// migration to a database.
    ///
    /// - Parameter schema: The schema to build changes on.
    func up(schema: Schema)
    
    /// The schema changes that should be run when rolling back this
    /// migration to a database.
    ///
    /// - Parameter schema: The schema to build changes on.
    func down(schema: Schema)
    
    /// The name of this migration, defaults to the type name.
    var name: String { get }
}

extension Migration {
    /// The name of this migration.
    public var name: String {
        Alchemy.name(of: Self.self)
    }
    
    /// Returns SQL statements for running the `.up` function of this
    /// migration.
    ///
    /// - Parameter grammar: The grammar to generate statements with.
    /// - Returns: The statements to run to apply this migration.
    func upStatements(for grammar: Grammar) -> [SQL] {
        let schema = Schema(grammar: grammar)
        up(schema: schema)
        return schema.statements
    }
    
    /// Returns SQL statements for running the `.down` function of
    /// this migration.
    ///
    /// - Parameter grammar: The grammar to generate statements with.
    /// - Returns: The statements to run to rollback this migration.
    func downStatements(for grammar: Grammar) -> [SQL] {
        let schema = Schema(grammar: grammar)
        down(schema: schema)
        return schema.statements
    }
}
