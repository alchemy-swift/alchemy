/// The migration table to store migrations in.
private let kMigrationTable = "_alchemy_migrations"
/// A query to run to create the migration table, if it doesn't exist.
private let kMigrationTableCreateQuery =
    """
    CREATE TABLE IF NOT EXISTS _alchemy_migrations (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        batch INT NOT NULL,
        run_at TIMESTAMPTZ NOT NULL
    )
    """

/// Represents a table for storing migration data. Alchemy will use this table for keeping track of
/// the various batches of migrations that have been run.
struct AlchemyMigration: Model {
    static var tableName: String = kMigrationTable
    /// A query for creating this table.
    static var creationQuery: String { kMigrationTableCreateQuery }
    
    /// Serial primary key.
    var id: Int?
    
    /// The name of the migration.
    let name: String
    
    /// The batch this migration was run as a part of.
    let batch: Int
    
    /// The timestamp when this migration was run.
    let runAt: Date?
}
